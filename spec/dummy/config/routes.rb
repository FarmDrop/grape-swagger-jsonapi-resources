Rails.application.routes.draw do
  mount Dummy::Application => "/grape-jsonapi-resources"
end
