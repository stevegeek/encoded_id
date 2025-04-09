# frozen_string_literal: true

class ModelWithSluggedPathParam < ::ActiveRecord::Base
  self.table_name = "my_models"
  include EncodedId::Model
  include EncodedId::Rails::SluggedPathParam
  
  def custom_slug_method
    "custom-slug"
  end
end