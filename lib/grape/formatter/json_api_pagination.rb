module Grape
  module Formatter
    class JsonApiPagination
      class << self
        def call(resource, env)
          new.serialize_resource(resource, env) || Grape::Formatter::Json.call(resource, env)
        end
      end

      attr_reader :env, :resource

      def serialize_resource(resource, env)
        @env = env
        @resource = resource

        endpoint = env['api.endpoint']

        jsonapi_options = build_options_from_endpoint(endpoint)
        jsonapi_options.merge!(env['jsonapi_options'] || {})

        context = {}
        context[:current_user] = endpoint.current_user if endpoint.respond_to?(:current_user)
        context.merge!(jsonapi_options.delete(:context)) if jsonapi_options[:context]

        resource_class = resource_class_for(resource)

        if resource_class.nil?
          return blank_resource_response(jsonapi_options, resource)
        end

        sorted_primary_ids = nil
        if resource.respond_to?(:to_ary)
          resource_instances = resource.to_ary.compact.collect do |each_resource|
            each_resource_class = resource_class_for(each_resource)
            each_resource_class.new(each_resource, context)
          end
          sorted_primary_ids = resource_instances.collect { |resource_instance| resource_instance.try(:id) }
        else
          resource_instances = resource_class.new(resource, context)
        end

        resource_serialized = JSONAPI::ResourceSerializer
                                .new(resource_class, jsonapi_options)
                                .serialize_to_hash(resource_instances)
        json_output = if jsonapi_options[:meta]
                        # Add option to merge top level meta tag as
                        # jsonapi-resources does not appear to support this
                        resource_serialized.as_json.merge(meta: jsonapi_options[:meta])
                      else
                        resource_serialized
                      end

        # Ensure sort order is maintained, serialize_to_hash can reorder objects if
        # objects of the array are of different types (polymorphic cases)
        json_output = json_output.stringify_keys
        if sorted_primary_ids && (data = json_output["data"]).present?
          sorted_primary_ids = sorted_primary_ids.map(&:to_s)
          json_output["data"] = data.sort_by { |d| sorted_primary_ids.index(d["id"]) }
        end

        if resource.respond_to?(:current_page) && resource.respond_to?(:total_pages)
          json_output["links"] ||= {}

          original_uri = URI("#{jsonapi_options[:base_url]}#{env['REQUEST_URI']}")
          json_output["links"]["self"] = original_uri.to_s

          original_query = Rack::Utils.parse_query(original_uri.query)

          last_page_query = original_query.merge('page[number]' => resource.total_pages)
          last_page_uri = original_uri.dup.tap { |uri| uri.query = build_query(last_page_query) }
          json_output["links"]["last"] = last_page_uri.to_s

          first_page_query = original_query.merge('page[number]' => 1)
          first_page_uri = original_uri.dup.tap { |uri| uri.query = build_query(first_page_query) }
          json_output["links"]["first"] = first_page_uri.to_s

          if resource.current_page > 1
            prev_page_query = original_query.merge('page[number]' => [1, resource.current_page.pred].max)
            prev_page_uri = original_uri.dup.tap { |uri| uri.query = build_query(prev_page_query) }
            json_output["links"]["prev"] = prev_page_uri.to_s
          end

          if resource.current_page < resource.total_pages && resource.total_pages > 1
            next_page_query = original_query.merge('page[number]' => [resource.total_pages, resource.current_page.succ].min)
            next_page_uri = original_uri.dup.tap { |uri| uri.query = build_query(next_page_query) }
            json_output["links"]["next"] = next_page_uri.to_s
          end
        end

        json_output.to_json
      end

      def original_uri(jsonapi_options)
        URI("#{jsonapi_options[:base_url]}#{env['REQUEST_URI']}")
      end

      def uri_with_page_number(page_number)
        original_query.merge('page[number]' => page_number)
      end

      def build_query(params)
        params.map { |k, v|
          if v.class == Array
            build_query(v.map { |x| [k, x] })
          else
            v.nil? ? k : "#{k}=#{v}"
          end
        }.join("&")
      end

      def build_options_from_endpoint(endpoint)
        options = {}
        if endpoint.namespace_inheritable(:jsonapi_base_url)
          options[:base_url] = endpoint.namespace_inheritable(:jsonapi_base_url)
        end
        options
      end

      def resource_class_for(resource)
        if resource.class.respond_to?(:jsonapi_resource_class)
          resource.class.jsonapi_resource_class
        elsif resource.respond_to?(:to_ary)
          resource_class_for(resource.to_ary.first)
        else
          get_resource_for(resource.class)
        end
      end

      def resources_cache
        @resources_cache ||= ThreadSafe::Cache.new
      end

      def get_resource_for(klass)
        resources_cache.fetch_or_store(klass) do
          resource_class_name = "#{klass.name}Resource"
          resource_class = resource_class_name.safe_constantize

          if resource_class
            resource_class
          elsif klass.superclass
            get_resource_for(klass.superclass)
          end
        end
      end

      private

      def blank_resource_response(jsonapi_options, resource)
        return nil unless resource.blank?

        blank_return = {}
        blank_return[:data] = resource.respond_to?(:to_ary) ? [] : {}
        blank_return[:meta] = jsonapi_options[:meta] if jsonapi_options[:meta]
        blank_return.to_json
      end
    end
  end
end
