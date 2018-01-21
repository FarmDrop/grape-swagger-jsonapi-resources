require "grape-swagger"
require "jsonapi-resources"
require "grape-jsonapi-resources"
require "grape/swagger/jsonapi/resources/version"
require "grape/swagger/jsonapi/resources/parser"

module Grape
  module Swagger
    module Jsonapi
      module Resources
        # Your code goes here...
      end
    end
  end
end

GrapeSwagger.model_parsers.register(Grape::Swagger::Jsonapi::Resources::Parser, JSONAPI::Resource)
