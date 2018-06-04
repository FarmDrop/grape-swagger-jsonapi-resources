require 'spec_helper'

# class StockOrderResource

RSpec.describe Grape::Formatter::JsonApiPagination do
  it 'provides pagination links' do
    resource = double('active_record_resource', :to_ary => [])
    fake_env = { 'api.endpoint' => double('endpoint', namespace_inheritable: '""') }
    actual = described_class.call(resource, fake_env)
    expected = {
      data: {},
      links: {}
    }

    expect(actual).to eq expected
  end
end
