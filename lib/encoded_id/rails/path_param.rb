# frozen_string_literal: true

# rbs_inline: enabled

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    # Overrides to_param to return the encoded ID for use in URLs.
    module PathParam
      # Method provided by model
      # @rbs!
      #   def encoded_id: () -> String?

      # @rbs () -> String
      def to_param
        encoded_id || raise(StandardError, "Cannot create path param for #{self.class.name} without an encoded id")
      end
    end
  end
end
