module GrapeSwagger
  module DocMethods
    # This turns ModelResource into Model so that the swagger doc has the right model name
    class DataType
      def self.parse_entity_name(model)
        if model.methods(false).include?(:entity_name)
          model.entity_name
        elsif model.to_s.end_with?("::Entity", "::Entities")
          model.to_s.split("::")[-2]
        elsif model.to_s.end_with?("Resource")
          model.to_s.gsub("Resource", "")
        elsif model.respond_to?(:name)
          model.name.demodulize.camelize
        else
          model.to_s.split("::").last
        end
      end
    end
  end
end
