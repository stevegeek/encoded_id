# frozen_string_literal: true

module EncodedId
  module Rails
    class Salt
      def initialize(klass, salt)
        @klass = klass
        @salt = salt
      end

      def generate!
        unless @klass.respond_to?(:name) && @klass.name.present?
          raise ::StandardError, "The class must have a `name` to ensure encode id uniqueness. " \
              "Please set a name on the class or override `encoded_id_salt`."
        end
        raise ::StandardError, "Encoded ID salt is invalid" if !@salt || @salt.blank? || @salt.size < 4
        "#{@klass.name}/#{@salt}"
      end
    end
  end
end
