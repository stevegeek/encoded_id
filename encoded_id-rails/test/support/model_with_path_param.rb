# frozen_string_literal: true

class ModelWithPathParam < ::ActiveRecord::Base
  self.table_name = "my_models"
  include EncodedId::Model
  include EncodedId::Rails::PathParam
end