# frozen_string_literal: true

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module SluggedPathParam
      def to_param
        slugged_encoded_id || raise(StandardError, "Cannot create path param for #{self.class.name} without an encoded id")
      end
    end
  end
end
