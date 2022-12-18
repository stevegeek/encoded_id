# frozen_string_literal: true

require "cgi"

module EncodedId
  module Rails
    class SluggedId
      def initialize(from_object, slug_method: :name_for_encoded_id_slug, id_method: :id, separator: "--")
        @from_object = from_object
        @slug_method = slug_method
        @id_method = id_method
        @separator = separator
      end

      def slugged_id
        slug_part = @from_object.send(@slug_method)
        id_part = @from_object.send(@id_method)
        unless id_part.present? && slug_part.present?
          raise ::StandardError, "The model does not return a valid ID (:#{@id_method}) and/or slug (:#{@slug_method})"
        end
        "#{slug_part.to_s.parameterize}#{CGI.escape(@separator)}#{id_part}"
      end
    end
  end
end
