# frozen_string_literal: true

class ModelWithSluggedPathParam < ::ActiveRecord::Base
  self.table_name = "my_models"
  include EncodedId::Model
  include EncodedId::Rails::SluggedPathParam

  def name_for_encoded_id_slug
    name
  end

  def custom_slug_method
    "custom-slug"
  end
end
