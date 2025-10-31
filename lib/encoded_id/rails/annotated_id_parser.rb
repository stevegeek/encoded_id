# frozen_string_literal: true
# rbs_inline: enabled

module EncodedId
  module Rails
    class AnnotatedIdParser
      # @rbs @annotation: String?
      # @rbs @id: String

      # @rbs (String annotated_id, ?separator: String) -> void
      def initialize(annotated_id, separator: "_")
        if separator && annotated_id.include?(separator)
          parts = annotated_id.split(separator)
          @id = parts.last
          @annotation = parts[0..-2]&.join(separator)
        else
          @id = annotated_id
        end
      end

      attr_reader :annotation #: String?
      attr_reader :id #: String
    end
  end
end
