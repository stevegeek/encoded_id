# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    class SluggedIdParser
      # @rbs @slug: String?
      # @rbs @id: String

      # @rbs (String slugged_id, ?separator: String) -> void
      def initialize(slugged_id, separator: "--")
        if separator && slugged_id.include?(separator)
          parts = slugged_id.split(separator)
          @slug = parts.first
          @id = parts.last
        else
          @id = slugged_id
        end
      end

      attr_reader :slug #: String?
      attr_reader :id #: String
    end
  end
end
