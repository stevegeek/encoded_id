# frozen_string_literal: true

class MyModel < ::ActiveRecord::Base
  include EncodedId::WithEncodedId
end
