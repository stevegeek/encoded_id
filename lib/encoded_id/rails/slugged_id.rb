# frozen_string_literal: true

# rbs_inline: enabled

require "cgi"

module EncodedId
  module Rails
    class SluggedId
      # @rbs @slug_part: String
      # @rbs @id_part: String
      # @rbs @separator: String

      # @rbs (slug_part: String, id_part: String, ?separator: String) -> void
      def initialize(slug_part:, id_part:, separator: "--")
        @slug_part = slug_part
        @id_part = id_part
        @separator = separator
      end

      # @rbs return: String
      def slugged_id
        unless @id_part.present? && @slug_part.present?
          raise ::StandardError, "The model does not return a valid ID and/or slug"
        end
        "#{@slug_part.to_s.parameterize}#{CGI.escape(@separator)}#{@id_part}"
      end
    end
  end
end
