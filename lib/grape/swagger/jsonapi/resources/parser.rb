module Grape
  module Swagger
    module Jsonapi
      module Resources
        # If editing this file, be aware that it somehow doesn't get reloaded by Rails
        # so you need to restart the server to see changes in output if testing using
        # swagger UI.
        class Parser
          attr_reader :main_model
          attr_reader :endpoint

          def initialize(model, endpoint)
            @main_model = model
            @endpoint = endpoint
          end

          def call
            model_properties(main_model)
          end

          # Currently doesn't display in swagger UI properly. Schema is correct though.
          # https://github.com/swagger-api/swagger-ui/issues/3859
          def included
            {
              type: :array,
              items: {
                anyOf: included_resource_models
              }
            }
          end

          private

          def model_properties(the_model)
            {
              type: {
                type: :string
              },
              id: {
                type: :integer
              },
              attributes: {
                type: :object,
                properties: attributes_schema(the_model),
              },
              relationships: {
                type: :object,
                properties: relationships_schema(the_model),
              }
            }
          end

          def model_data_schema(the_model)
            {
              type: :object,
              properties: model_properties(the_model)
            }
          end

          def attributes_schema(the_model)
            the_model._attributes.each_with_object({}) do |(name, details), properties|
              properties[name] = {
                type: details[:type] || :integer
              }
            end
          end

          def relationships_schema(the_model)
            the_model._relationships.each_with_object({}) do |(name, relationship), schema|
              has_many = relationship.class.name.demodulize == "ToMany"

              schema[name] = {
                type: :object,
                properties: {
                  links: {
                    type: :object,
                    properties: {
                      self: {
                        type: :string
                      },
                      related: {
                        type: :string
                      }
                    }
                  }
                },
                data: {
                  type: (has_many ? :array : :object), # Sorry.
                  "#{has_many ? :items : :properties}": {
                    id: {
                      type: :integer,
                    },
                    type: {
                      type: :string
                    }
                  }
                }
              }
            end
          end

          def included_resource_models
            main_model._relationships.values.map do |reflection|
              relationship_model = reflection.parent_resource
              model_data_schema(relationship_model)
            end
          end
        end
      end
    end
  end
end

