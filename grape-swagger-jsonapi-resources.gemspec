
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "grape/swagger/jsonapi/resources/version"

Gem::Specification.new do |spec|
  spec.name          = "grape-swagger-jsonapi-resources"
  spec.version       = Grape::Swagger::Jsonapi::Resources::VERSION
  spec.authors       = ["Matt Gibson"]

  spec.summary       = <<~TEXT
                         This gem will allow you to use JSONAPI::Resources resource definition classes with Grape
                         and have the correct Swagger docs generated from them.
                       TEXT
  spec.description   = <<~TEXT
                         The use case is that you are using the Grape gem to define your API, want to use JSONAPI,
                         and want to have Swagger docs for the endpoints.
                       TEXT
  spec.homepage      = "https://github.com/mattgibson/grape-swagger-jsonapi-resources"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4.2" # jsonapi-resources needs this but doesn't declare it
  spec.add_dependency "grape", "~> 1.0"
  spec.add_dependency "grape-swagger", "~> 0.27"
  spec.add_dependency "jsonapi-resources", "~> 0.9.0"
  spec.add_dependency "grape-jsonapi-resources", "~> 0.0.7"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
