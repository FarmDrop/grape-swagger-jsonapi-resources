# frozen_string_literal: true

module Grape
  module Formatter
    class Link
      attr_reader :uri, :merge_params

      def initialize(uri, merge_params)
        @uri = uri
        @merge_params = merge_params
      end

      def to_s
        uri.dup.tap { |uri| uri.query = build_query(original_query.merge(merge_params)) }
      end

      private

      def build_query(params)
        params.map do |k, v|
          if v.class == Array
            build_query(v.map { |x| [k, x] })
          else
            v.nil? ? k : "#{k}=#{v}"
          end
        end.join("&")
      end

      def original_query
        Rack::Utils.parse_query(uri.query)
      end
    end
  end
end
