# frozen_string_literal: true

class ModelWithPersistedEncodedId < ::ActiveRecord::Base
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end
