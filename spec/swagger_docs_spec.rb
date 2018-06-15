require "spec_helper"

Product = Struct.new(:id, :name)

class ProductResource < JSONAPI::Resource
  attribute :name
end

RSpec.describe "swagger docs" do
  before :all do
    module TheApi
      class SwaggerApi < Grape::API
        formatter :jsonapi, Grape::Formatter::JsonApiPagination
        content_type :jsonapi, "application/vnd.api+json"
        default_format :jsonapi
        format :jsonapi

        desc "This returns something",
             headers: {
               "X-Rate-Limit-Limit" => {
                 "description" => "The number of allowed requests in the current period",
                 "type" => "integer"
               }
             },
             entity: ProductResource
        params do
          optional :param_x, type: String, desc: "This is a parameter", documentation: { param_type: "query" }
        end
        get "/use_headers" do
          { "declared_params" => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::SwaggerApi
  end

  it "send back a 200 response" do
    get "/swagger_doc"
    expect(last_response.status).to eq 200
  end
end
