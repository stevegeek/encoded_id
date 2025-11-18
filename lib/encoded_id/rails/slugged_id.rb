# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    class SluggedId < CompositeIdBase
      # @rbs (slug_part: String, id_part: String, ?separator: String) -> void
      def initialize(slug_part:, id_part:, separator: "--")
        super(first_part: slug_part, id_part: id_part, separator: separator)
      end

      # @rbs return: String
      def slugged_id
        build_composite_id
      end

      private

      # @rbs return: String
      def invalid_id_error_message
        "The model does not return a valid ID and/or slug"
      end
    end
  end
end
