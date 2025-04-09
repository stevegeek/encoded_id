# frozen_string_literal: true

class MyModel < ::ActiveRecord::Base
  include EncodedId::Model

  def name_for_encoded_id_slug
    name
  end

  def custom_slug_method
    "sluggy"
  end
end
