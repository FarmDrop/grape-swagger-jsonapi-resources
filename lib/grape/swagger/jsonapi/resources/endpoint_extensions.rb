# frozen_string_literal: true

module Grape
  # This is for inclusion into Grape::Endpoint after the stuff from grape-swagger
  class Endpoint
    alias original_response_object response_object

    def response_object(route)
      if endpoint_uses_jsonapi?
        json_api_response_object(route)
      else
        original_response_object(route)
      end
    end

    def endpoint_uses_jsonapi?
      @entity&.ancestors&.include?(JSONAPI::Resource)
    end

    def json_api_response_object(route)
      codes = (route.http_codes || route.options[:failure] || [])

      codes = apply_success_codes(route) + codes
      codes.map! { |x| x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2] } : x }

      codes.each_with_object({}) do |this_http_code, all_responses|
        this_http_code[:message] ||= ''
        all_responses[this_http_code[:code]] = { description: this_http_code[:message] }
        next build_file_response(all_responses[this_http_code[:code]]) if file_response?(this_http_code[:model])

        response_model = @item
        response_model = expose_params_from_model(this_http_code[:model]) if this_http_code[:model]

        if all_responses.key?(200) && route.request_method == 'DELETE' && this_http_code[:model].nil?
          all_responses[204] = all_responses.delete(200)
          this_http_code[:code] = 204
        end

        next if all_responses.key?(204)
        next unless !response_model.start_with?('Swagger_doc') && (@definitions[response_model] || this_http_code[:model])

        reference = {
          '$ref' => "#/definitions/#{response_model}"
        }

        json_api_response = {
          type: :object,
          properties: {
            data: reference
          }
        }

        json_api_response[:properties][:included] = included_models(this_http_code[:model]) if @entity._relationships.any?

        all_responses[this_http_code[:code]][:schema] = if route.options[:is_array] && this_http_code[:code] < 300
                                                          { type: 'array', items: reference }
                                                        else
                                                          json_api_response
                                                        end
      end
    end

    # This uses anyOf, but swagger UI seems not to display it properly and you
    # just get an empty object with null in it.
    # https://github.com/swagger-api/swagger-ui/issues/3859
    # https://github.com/swagger-api/swagger-ui/pull/4136
    def included_models(model)
      models = Grape::Swagger::Jsonapi::Resources::Parser.new(model, self).included
      refs = models.map do |m|
        {
          '$ref' => "#/definitions/#{expose_params_from_model(m)}"
        }
      end
      {
        type: :array,
        items: {
          anyOf: refs
        }
      }
    end
  end
end
