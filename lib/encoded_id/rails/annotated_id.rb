# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Represents an encoded ID with an annotation prefix (e.g., "user_ABC123").
    class AnnotatedId < CompositeIdBase
      # @rbs (annotation: String, id_part: String, ?separator: String) -> void
      def initialize(annotation:, id_part:, separator: "_")
        super(first_part: annotation, id_part: id_part, separator: separator)
      end

      # @rbs return: String
      def annotated_id
        build_composite_id
      end

      private

      # @rbs return: String
      def invalid_id_error_message
        "The model does not return a valid ID and/or annotation"
      end
    end
  end
end
