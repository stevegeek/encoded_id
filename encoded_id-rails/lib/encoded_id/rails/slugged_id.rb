# frozen_string_literal: true

module EncodedId
  module Rails
    class SluggedId
      def initialize(from_object, name_method: :name, id_method: :id, separator: "--")
        @from_object = from_object
        @name_method = name_method
        @id_method = id_method
        @separator = separator
      end

      def slugged_id
        name_part = @from_object.send(@name_method)
        id_part = @from_object.send(@id_method)
        unless id_part.present? && name_part.present?
          raise ::StandardError, "The model has no #{@id_method} or #{@name_method}"
        end
        "#{name_part.to_s.parameterize}#{@separator}#{id_part}"
      end
    end
  end
end
