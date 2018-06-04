require 'spec_helper'

Merchant = Struct.new(:id, :name)

class MerchantResource < JSONAPI::Resource
  attribute :name
end

RSpec.describe Grape::Formatter::JsonApiPagination do
  let(:base_url) { 'http://localhost:3000' }

  it 'provides pagination links' do
    resource = [Merchant.new(12, 'Purton')]
    fake_env = { 'api.endpoint' => double('endpoint', namespace_inheritable: base_url ) }
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
          },
        }
      ],
      # links: {
      #   self: "#{base_url}"
      # }
    }

    expect(JSON.parse(actual)).to eq expected.as_json
  end
end
