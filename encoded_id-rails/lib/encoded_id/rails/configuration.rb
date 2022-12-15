# frozen_string_literal: true

module EncodedId
  module Rails
    # Configuration class for initializer
    class Configuration
      attr_accessor :salt,
        :character_group_size,
        :alphabet,
        :id_length

      def initialize
        @character_group_size = 4
        @alphabet = ::EncodedId::Alphabet.modified_crockford
        @id_length = 8
      end
    end
  end
end
