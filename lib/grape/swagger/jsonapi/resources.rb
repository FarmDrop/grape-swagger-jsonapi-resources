require "grape-swagger"

# Only require the bits of Rails that jsonapi-resources uses
require "action_controller"
require "rails"

require "jsonapi-resources"

require "grape-jsonapi-resources"
require "grape/swagger/jsonapi/resources/version"
require "grape/swagger/jsonapi/resources/parser"
require "grape/swagger/jsonapi/resources/endpoint_extensions"

GrapeSwagger.model_parsers.register(Grape::Swagger::Jsonapi::Resources::Parser, JSONAPI::Resource)
