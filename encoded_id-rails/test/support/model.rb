# frozen_string_literal: true

class MyModel < ::ActiveRecord::Base
  include EncodedId::Model

  def custom_slug_method
    "sluggy"
  end
end
