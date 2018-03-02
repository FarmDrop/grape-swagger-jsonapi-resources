require 'spec_helper'

RSpec.describe Grape::Swagger::Jsonapi::Resources::Parser do
  it 'parses the object correctly' do
    expect(described_class.new(Owner.new, '').call).to eq('')
  end
end