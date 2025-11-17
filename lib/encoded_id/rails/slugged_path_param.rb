# frozen_string_literal: true

# rbs_inline: enabled

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module SluggedPathParam
      # Method provided by model
      # @rbs!
      #   def slugged_encoded_id: () -> String?

      # @rbs () -> String
      def to_param
        slugged_encoded_id || raise(StandardError, "Cannot create path param for #{self.class.name} without an encoded id")
      end
    end
  end
end
