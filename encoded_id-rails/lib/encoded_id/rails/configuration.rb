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
        :slugged_id_separator

      def initialize
        @character_group_size = 4
        @group_separator = "-"
        @alphabet = ::EncodedId::Alphabet.modified_crockford
        @id_length = 8
        @slugged_id_separator = "--"
      end
    end
  end
end
