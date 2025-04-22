# frozen_string_literal: true

class ModelWithPersistedEncodedId < ::ActiveRecord::Base
  include EncodedId::Model
  include EncodedId::Rails::Persists
end
