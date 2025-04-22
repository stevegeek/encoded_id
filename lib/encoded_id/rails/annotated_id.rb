# frozen_string_literal: true

require "cgi"

module EncodedId
  module Rails
    class AnnotatedId
      def initialize(annotation:, id_part:, separator: "_")
        @annotation = annotation
        @id_part = id_part
        @separator = separator
      end

      def annotated_id
        unless @id_part.present? && @annotation.present?
          raise ::StandardError, "The model does not provide a valid ID and/or annotation"
        end
        "#{@annotation.to_s.parameterize}#{CGI.escape(@separator)}#{@id_part}"
      end
    end
  end
end
