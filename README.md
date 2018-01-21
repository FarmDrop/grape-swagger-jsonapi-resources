# Grape::Swagger::Jsonapi::Resources

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape-swagger-jsonapi-resources'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-swagger-jsonapi-resources

## Usage

Add the formatter from `JSONAPI::Resources` to your API:

```
module V1
  class StockOrders < Grape::API
    format :json
    formatter :json, Grape::Formatter::JSONAPIResources
    content_type :json, "application/vnd.api+json"
    
    # ...
  end
end
```

Define your resources as per the instructions for the [jsonapi-resources](https://github.com/cerebris/jsonapi-resources) gem:

```
# /app/resources/stock_order_respource.rb

class StockOrderResource < JSONAPI::Resource
  attribute :stock_order_number, type: :string
  attribute :delivery_date, type: :integer
  attribute :discount_type, type: :string
  attribute :discount_amount, type: :integer
  attribute :created_at, type: :string
  attribute :updated_at, type: :string

  has_many :order_items
  has_many :purchase_orders

  has_one :hub
  has_one :user
  has_one :merchant
end

```

Tell the API that the response will use your resource as an entity, and which models you want to have sideloaded in the
`included` section of the response:

```
desc "Returns a single stock order" do
  entity StockOrderResource
end
get do
  render StockOrder.find(params[:id]), include: %w(purchase_orders order_items)
end
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mattgibson/grape-swagger-jsonapi-resources. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Grape::Swagger::Jsonapi::Resources project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mattgibson/grape-swagger-jsonapi-resources/blob/master/CODE_OF_CONDUCT.md).
