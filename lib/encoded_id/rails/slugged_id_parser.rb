# frozen_string_literal: true

module EncodedId
  module Rails
    class SluggedIdParser
      def initialize(slugged_id, separator: "--")
        if separator && slugged_id.include?(separator)
          parts = slugged_id.split(separator)
          @slug = parts.first
          @id = parts.last
        else
          @id = slugged_id
        end
      end

      attr_reader :slug, :id
    end
  end
end
