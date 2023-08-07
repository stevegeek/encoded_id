# frozen_string_literal: true

module EncodedId
  module Rails
    # Configuration class for initializer
    class Configuration
      attr_accessor :salt, :character_group_size, :alphabet, :id_length
      attr_accessor :slug_value_method_name, :annotation_method_name
      attr_reader :group_separator, :slugged_id_separator, :annotated_id_separator

      def initialize
        @character_group_size = 4
        @group_separator = "-"
        @alphabet = ::EncodedId::Alphabet.modified_crockford
        @id_length = 8
        @slug_value_method_name = :name_for_encoded_id_slug
        @slugged_id_separator = "--"
        @annotation_method_name = :annotation_for_encoded_id
        @annotated_id_separator = "_"
      end

      # Perform validation vs alphabet on these assignments

      def group_separator=(value)
        unless valid_separator?(value, alphabet)
          raise ArgumentError, "Group separator characters must not be part of the alphabet"
        end
        @group_separator = value
      end

      def slugged_id_separator=(value)
        if value.blank? || value == group_separator || !valid_separator?(value, alphabet)
          raise ArgumentError, "Slugged ID separator characters must not be part of the alphabet or the same as the group separator"
        end
        @slugged_id_separator = value
      end

      def annotated_id_separator=(value)
        if value.blank? || value == group_separator || !valid_separator?(value, alphabet)
          raise ArgumentError, "Annotated ID separator characters must not be part of the alphabet or the same as the group separator"
        end
        @annotated_id_separator = value
      end

      def valid_separator?(separator, characters)
        separator.chars.none? { |v| characters.include?(v) }
      end
    end
  end
end
