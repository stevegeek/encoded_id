# frozen_string_literal: true

module EncodedId
  module Rails
    # Configuration class for initializer
    class Configuration
      attr_accessor :salt,
        :character_group_size,
        :group_separator,
        :alphabet,
        :id_length,
        :slug_value_method_name,
        :slugged_id_separator,
        :annotation_method_name, # Set to nil to disable annotated IDs
        :annotated_id_separator

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
    end
  end
end
