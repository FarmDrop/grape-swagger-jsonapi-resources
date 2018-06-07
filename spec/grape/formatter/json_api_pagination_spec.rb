# frozen_string_literal: true

require "spec_helper"
require "kaminari"

Merchant = Struct.new(:id, :name)
Product = Struct.new(:id, :name)

class ProductResource < JSONAPI::Resource
  attribute :name

  has_one :merchant
end

class MerchantResource < JSONAPI::Resource
  attribute :name

  has_one :product
end

RSpec.describe Grape::Formatter::JsonApiPagination do
  let(:base_url) { "http://localhost:3000" }
  let(:fake_endpoint) { double("endpoint", namespace_inheritable: base_url) }
  let(:fake_env) do
    {
      "api.endpoint" => fake_endpoint,
      "HTTP_ORIGIN" => "http://localhost:3000",
    }
  end
  let(:resource) do
    [
      Merchant.new(12, "Purton"),
      Merchant.new(13, "Anspach")
    ]
  end

  describe "characterisation spec for the JSONAPI response" do
    it "matches the spec" do
      expected = {
        "data" => [
          {
            "id" => "12",
            "type" => "merchants",
            "links" => {
              "self" => "http://localhost:3000/merchants/12"
            },
            "attributes" => {
              "name" => "Purton"
            },
            "relationships" => {
              "product" => {
                "links" => {
                  "self" => "http://localhost:3000/merchants/12/relationships/product",
                  "related" => "http://localhost:3000/merchants/12/product"
                }
              }
            }
          },
          {
            "id" => "13",
            "type" => "merchants",
            "links" => {
              "self" => "http://localhost:3000/merchants/13"
            },
            "attributes" => {
              "name" => "Anspach"
            },
            "relationships" => {
              "product" => {
                "links" => {
                  "self" => "http://localhost:3000/merchants/13/relationships/product",
                  "related" => "http://localhost:3000/merchants/13/product"
                }
              }
            }
          }
        ]
      }
      json = described_class.call(resource, fake_env)
      expect(JSON.parse(json)).to eq expected
    end
  end

  describe "pagination" do
    context "when there is no pagination supplied" do
      it "provides no pagination links" do
        resource = [Merchant.new(12, "Purton")]

        actual = described_class.call(resource, fake_env)
        expected = {
          data: [
            {
              id: "12",
              type: "merchants",
              links: {
                self: "http://localhost:3000/merchants/12"
              },
              attributes: {
                name: "Purton"
              },
              relationships: {
                product: {
                  links: {
                    self: "http://localhost:3000/merchants/12/relationships/product",
                    related: "http://localhost:3000/merchants/12/product"
                  }
                }
              }
            }
          ]
        }

        expect(JSON.parse(actual)).to eq expected.as_json
      end
    end

    context "with a paginated resource supplied" do
      let(:pagination_links) do
        JSON.parse(described_class.call(resource, fake_env))["links"]
      end

      context "when there is only one page" do
        let(:fake_env) do
          {
            "api.endpoint" => fake_endpoint,
            "REQUEST_URI" => "/merchants?page[number]=1&page[size]=2",
            "PATH_INFO" => "/merchants",
            "QUERY_STRING" => "page[number]=1&page[size]=2",
            "HTTP_ORIGIN" => "http://localhost:3000",
          }
        end
        let(:resource) do
          Kaminari.paginate_array(
            [
              Merchant.new(12, "Purton")
            ]
          ).page(1).per(2)
        end

        it "provides pagination links" do
          expected = {
            self: "http://localhost:3000/merchants?page[number]=1&page[size]=2",
            first: "http://localhost:3000/merchants?page[number]=1&page[size]=2",
            last: "http://localhost:3000/merchants?page[number]=1&page[size]=2"
          }

          expect(pagination_links).to eq expected.as_json
        end
      end

      context "when there are multiple pages" do
        context "when we are on the middle page" do
          let(:fake_env) do
            {
              "api.endpoint" => fake_endpoint,
              "REQUEST_URI" => "/merchants?page[number]=2&page[size]=2",
              "PATH_INFO" => "/merchants",
              "QUERY_STRING" => "page[number]=2&page[size]=2",
              "HTTP_ORIGIN" => "http://localhost:3000",
            }
          end
          let(:resource) do
            Kaminari.paginate_array(
              [
                Merchant.new(12, "Purton"),
                Merchant.new(13, "Anspach"),
                Merchant.new(14, "Fourpure"),
                Merchant.new(15, "Naty"),
                Merchant.new(16, "Ranas"),
                Merchant.new(17, "Longmans"),
              ]
            ).page(2).per(2)
          end

          it "provides a pagination link for the first page" do
            expected_link = "http://localhost:3000/merchants?page[number]=1&page[size]=2"
            expect(pagination_links["first"]).to eq expected_link
          end

          it "provides a pagination link for the last page" do
            expected_link = "http://localhost:3000/merchants?page[number]=3&page[size]=2"
            expect(pagination_links["last"]).to eq expected_link
          end

          it "provides a pagination link for the previous page" do
            expected_link = "http://localhost:3000/merchants?page[number]=1&page[size]=2"
            expect(pagination_links["prev"]).to eq expected_link
          end

          it "provides a pagination link for the next page" do
            expected_link = "http://localhost:3000/merchants?page[number]=3&page[size]=2"
            expect(pagination_links["next"]).to eq expected_link
          end
        end
      end
    end
  end
end
