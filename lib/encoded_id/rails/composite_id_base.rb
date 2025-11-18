# frozen_string_literal: true

# rbs_inline: enabled

require "cgi"

module EncodedId
  module Rails
    # Base class for composite IDs (slugged and annotated)
    class CompositeIdBase
      # @rbs @first_part: String
      # @rbs @id_part: String
      # @rbs @separator: String

      # @rbs (first_part: String, id_part: String, separator: String) -> void
      def initialize(first_part:, id_part:, separator:)
        @first_part = first_part
        @id_part = id_part
        @separator = separator
      end

      private

      # @rbs return: String
      def build_composite_id
        unless @id_part.present? && @first_part.present?
          raise ::StandardError, invalid_id_error_message
        end
        "#{@first_part.to_s.parameterize}#{CGI.escape(@separator)}#{@id_part}"
      end

      # Default error message. Subclasses can override for more specific messages.
      # @rbs return: String
      def invalid_id_error_message
        "The model does not return a valid ID and/or prefix"
      end
    end
  end
end
