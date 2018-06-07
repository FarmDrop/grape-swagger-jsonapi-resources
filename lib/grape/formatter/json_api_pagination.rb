# frozen_string_literal: true

require_relative "link"

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
        @endpoint = env["api.endpoint"]

        return blank_resource_response(jsonapi_options, resource) if resource_class.nil?

        build_main_json_output_data
        add_pagination_links if resource_supports_pagination?

        json_output.to_json
      end

      private

      # Ensure sort order is maintained, serialize_to_hash can reorder objects if
      # objects of the array are of different types (polymorphic cases)
      def build_main_json_output_data
        if sorted_primary_ids && (data = json_output["data"]).present?
          json_output["data"] = data.sort_by { |d| sorted_primary_ids.index(d["id"]) }
        end
      end

      def resource_supports_pagination?
        resource.respond_to?(:current_page) && resource.respond_to?(:total_pages)
      end

      def add_pagination_links
        json_output["links"] ||= {}

        add_link_to_json_output("self", original_uri)

        add_page_link_to_json_output("last", resource.total_pages)
        add_page_link_to_json_output("first", 1)

        add_previous_page_link if current_page_is_not_the_first_page
        add_next_page_link if current_page_is_not_the_last_page
      end

      def add_next_page_link
        next_or_last_page_number = [resource.total_pages, resource.current_page.succ].min
        add_page_link_to_json_output("next", next_or_last_page_number)
      end

      def add_previous_page_link
        first_or_previous_page_number = [1, resource.current_page.pred].max
        add_page_link_to_json_output("prev", first_or_previous_page_number)
      end

      def current_page_is_not_the_first_page
        resource.current_page > 1
      end

      def current_page_is_not_the_last_page
        resource.current_page < resource.total_pages
      end

      def add_link_to_json_output(link_name, uri)
        json_output["links"][link_name] = uri.to_s
      end

      def add_page_link_to_json_output(link_name, page_number)
        link = Link.new(original_uri, "page[number]" => page_number).to_s
        add_link_to_json_output(link_name, link)
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
          .merge!(env["jsonapi_options"] || {})
      end

      def original_uri
        URI("#{jsonapi_options[:base_url]}#{env['REQUEST_URI']}")
      end

      def build_options_from_endpoint
        options = {}
        options[:base_url] = env["HTTP_ORIGIN"] if env["HTTP_ORIGIN"]
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
        return nil if resource.present?

        blank_return = {}
        blank_return[:data] = resource.respond_to?(:to_ary) ? [] : {}
        blank_return[:meta] = jsonapi_options[:meta] if jsonapi_options[:meta]
        blank_return.to_json
      end
    end
  end
end
