# frozen_string_literal: true

require "cgi"

module EncodedId
  module Rails
    class SluggedId
      def initialize(slug_part:, id_part:, separator: "--")
        @slug_part = slug_part
        @id_part = id_part
        @separator = separator
      end

      def slugged_id
        unless @id_part.present? && @slug_part.present?
          raise ::StandardError, "The model does not return a valid ID and/or slug"
        end
        "#{@slug_part.to_s.parameterize}#{CGI.escape(@separator)}#{@id_part}"
      end
    end
  end
end
