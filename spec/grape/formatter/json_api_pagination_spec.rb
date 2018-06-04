# frozen_string_literal: true

require 'spec_helper'
require 'kaminari'

Merchant = Struct.new(:id, :name)

class MerchantResource < JSONAPI::Resource
  attribute :name
end

RSpec.describe Grape::Formatter::JsonApiPagination do
  let(:base_url) { 'http://localhost:3000' }

  it 'provides no pagination links if there is no pagination supplied' do
    resource = [Merchant.new(12, 'Purton')]
    fake_env = {
      'api.endpoint' => double('endpoint', namespace_inheritable: base_url )
    }
    actual = described_class.call(resource, fake_env)
    expected = {
      data: [
        {
          id:'12',
          type: 'merchants',
          links: {
            self: 'http://localhost:3000/merchants/12'
          },
          attributes: {
            name: 'Purton'
          }
        }
      ]
    }

    expect(JSON.parse(actual)).to eq expected.as_json
  end

  it 'provides self pagination links if there is pagination supplied' do
    resource = Kaminari.paginate_array([
                                         Merchant.new(12, 'Purton')
                                       ]).page(1).per(2)
    fake_env = {
      'api.endpoint' => double('endpoint', namespace_inheritable: base_url),
      'REQUEST_URI' => '/merchants?page[number]=1&page[size]=2',
      'PATH_INFO' => '/merchants',
      'QUERY_STRING' => 'page[number]=1&page[size]=2'
    }
    actual = described_class.call(resource, fake_env)
    expected = {
      data: [
        {
          id: '12',
          type: 'merchants',
          links: {
            self: 'http://localhost:3000/merchants/12'
          },
          attributes: {
            name: 'Purton'
          }
        }
      ],
      links: {
        self: 'http://localhost:3000/merchants?page[number]=1&page[size]=2'
      }
    }

    expect(JSON.parse(actual)).to eq expected.as_json
  end
end
