# frozen_string_literal: true

class MyModel < ::ActiveRecord::Base
  include EncodedId::WithEncodedId

  def custom_slug_method
    "sluggy"
  end
end
