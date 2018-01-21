module JSONAPI
  class Resource
    # So that the Swagger docs definitions have the name of the actual model, not ModelResource
    def self.entity_name
      name.gsub("Resource", "")
    end
  end
end