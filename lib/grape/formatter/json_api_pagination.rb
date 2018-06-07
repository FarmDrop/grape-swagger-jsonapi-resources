# frozen_string_literal: true

module Grape
  module Formatter
    # This an extended and refactored version of the JSONAPI resources formatter
    # that adds pagination links if there is a wrapper e.g. Kaminari that provides
    # the appropriate pagination methods.
    class JsonApiPagination
      class << self
        def call(resource, env)
          new.serialize_resource(resource, env) || Grape::Formatter::Json.call(resource, env)
        end
      end

      attr_reader :env, :resource, :endpoint

      def serialize_resource(resource, env)
        @env = env
        @resource = resource
        @endpoint = env['api.endpoint']

        if resource_class.nil?
          return blank_resource_response(jsonapi_options, resource)
        end

        build_main_json_output_data
        add_pagination_links if resource_supports_pagination?

        json_output.to_json
      end

      private

      # Ensure sort order is maintained, serialize_to_hash can reorder objects if
      # objects of the array are of different types (polymorphic cases)
      def build_main_json_output_data
        if sorted_primary_ids && (data = json_output['data']).present?
          json_output['data'] = data.sort_by { |d| sorted_primary_ids.index(d['id']) }
        end
      end

      def resource_supports_pagination?
        resource.respond_to?(:current_page) && resource.respond_to?(:total_pages)
      end

      def add_pagination_links
        json_output['links'] ||= {}

        add_link_to_json_output('self', original_uri)

        last_page_uri = build_query_for_different_page(resource.total_pages)
        add_link_to_json_output('last', last_page_uri)
        first_page_uri = build_query_for_different_page(1)
        add_link_to_json_output('first', first_page_uri)

        add_previous_page_link if current_page_is_not_the_first_page
        add_next_page_link if current_page_is_not_the_last_page
      end

      def add_next_page_link
        next_or_last_page_number = [resource.total_pages, resource.current_page.succ].min
        next_page_uri = build_query_for_different_page(next_or_last_page_number)
        add_link_to_json_output('next', next_page_uri)
      end

      def add_previous_page_link
        first_or_previous_page_number = [1, resource.current_page.pred].max
        prev_page_uri = build_query_for_different_page(first_or_previous_page_number)
        add_link_to_json_output('prev', prev_page_uri)
      end

      def build_query_for_different_page(query)
        original_uri.dup.tap { |uri| uri.query = build_query(uri_with_page_number(query)) }
      end

      def current_page_is_not_the_first_page
        resource.current_page > 1
      end

      def current_page_is_not_the_last_page
        resource.current_page < resource.total_pages
      end

      def add_link_to_json_output(link_name, uri)
        json_output['links'][link_name] = uri.to_s
      end

      def resource_class
        resource_class_for(resource)
      end

      def context
        return @context if @context
        @context = {}
        @context[:current_user] = endpoint.current_user if endpoint.respond_to?(:current_user)
        @context.merge!(jsonapi_options.delete(:context)) if jsonapi_options[:context]
      end

      def resource_instances
        @resource_instances ||= if resource.respond_to?(:to_ary)
                                  resource.to_ary.compact.collect do |each_resource|
                                    each_resource_class = resource_class_for(each_resource)
                                    each_resource_class.new(each_resource, context)
                                  end
                                else
                                  resource_class.new(resource, context)
                                end
      end

      def sorted_primary_ids
        return @sorted_primary_ids if @sorted_primary_ids
        if resource.respond_to?(:to_ary)
          @sorted_primary_ids = resource_instances.collect { |resource_instance| resource_instance.try(:id) }
        end
      end

      def json_output
        @json_output ||= if jsonapi_options[:meta]
                           # Add option to merge top level meta tag as
                           # jsonapi-resources does not appear to support this
                           resource_serialized.as_json.merge(meta: jsonapi_options[:meta])
                         else
                           resource_serialized
                         end.stringify_keys
      end

      def resource_serialized
        @resource_serialized ||= JSONAPI::ResourceSerializer
                                 .new(resource_class, jsonapi_options)
                                 .serialize_to_hash(resource_instances)
      end

      def jsonapi_options
        @json_api_options ||= build_options_from_endpoint
                              .merge!(env['jsonapi_options'] || {})
      end

      def original_uri
        URI("#{jsonapi_options[:base_url]}#{env['REQUEST_URI']}")
      end

      def original_query
        Rack::Utils.parse_query(original_uri.query)
      end

      def uri_with_page_number(page_number)
        original_query.merge('page[number]' => page_number)
      end

      def build_query(params)
        params.map do |k, v|
          if v.class == Array
            build_query(v.map { |x| [k, x] })
          else
            v.nil? ? k : "#{k}=#{v}"
          end
        end.join('&')
      end

      def build_options_from_endpoint
        options = {}
        if env['HTTP_ORIGIN']
          options[:base_url] = env['HTTP_ORIGIN']
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
