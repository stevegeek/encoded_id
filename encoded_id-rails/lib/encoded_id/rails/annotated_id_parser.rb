# frozen_string_literal: true

module EncodedId
  module Rails
    class AnnotatedIdParser
      def initialize(annotated_id, separator: "_")
        if separator && annotated_id.include?(separator)
          parts = annotated_id.split(separator)
          @id = parts.last
          @annotation = parts[0..-2]&.join(separator)
        else
          @id = annotated_id
        end
      end

      attr_reader :annotation, :id
    end
  end
end
