# frozen_string_literal: true

# This model is used to test the automatic inclusion of PathParam when
# model_to_param_returns_encoded_id is enabled
class AutoPathParamModel < ::ActiveRecord::Base
  self.table_name = "my_models"
  include EncodedId::Model
end