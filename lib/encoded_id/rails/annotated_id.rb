# frozen_string_literal: true

# rbs_inline: enabled

require "cgi"

module EncodedId
  module Rails
    class AnnotatedId
      # @rbs @annotation: String
      # @rbs @id_part: String
      # @rbs @separator: String

      # @rbs (annotation: String, id_part: String, ?separator: String) -> void
      def initialize(annotation:, id_part:, separator: "_")
        @annotation = annotation
        @id_part = id_part
        @separator = separator
      end

      # @rbs return: String
      def annotated_id
        unless @id_part.present? && @annotation.present?
          raise ::StandardError, "The model does not provide a valid ID and/or annotation"
        end
        "#{@annotation.to_s.parameterize}#{CGI.escape(@separator)}#{@id_part}"
      end
    end
  end
end
