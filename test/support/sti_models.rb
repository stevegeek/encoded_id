# frozen_string_literal: true

# STI base class
class StiRecord < ::ActiveRecord::Base
  include EncodedId::Rails::Model

  def name_for_encoded_id_slug
    name
  end
end

# STI child class without custom salt
class StiChild < StiRecord
end

# STI grandchild class without custom salt
class StiGrandchild < StiChild
end

# STI child class with custom salt matching parent
class StiChildWithSharedSalt < StiRecord
  def self.encoded_id_salt
    EncodedId::Rails::Salt.new(StiRecord, EncodedId::Rails.configuration.salt).generate!
  end
end

# Another STI child with shared salt
class AnotherStiChildWithSharedSalt < StiRecord
  def self.encoded_id_salt
    EncodedId::Rails::Salt.new(StiRecord, EncodedId::Rails.configuration.salt).generate!
  end
end
