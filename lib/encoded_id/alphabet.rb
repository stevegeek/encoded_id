# frozen_string_literal: true

module EncodedId
  class Alphabet
    MIN_UNIQUE_CHARACTERS = 16

    class << self
      def modified_crockford
        new(
          "0123456789abcdefghjkmnpqrstuvwxyz",
          {
            "o" => "0",
            "i" => "j",
            "l" => "1"
          }
        )
      end
    end

    def initialize(characters, equivalences = nil)
      raise_invalid_alphabet! unless valid_input_characters?(characters)
      unique_characters = unique_character_alphabet(characters)
      raise_character_set_too_small! unless sufficient_characters?(unique_characters)
      raise_invalid_equivalences! unless valid_equivalences?(equivalences, unique_characters)

      @characters = unique_characters.join
      @equivalences = equivalences
    end

    attr_reader :characters, :equivalences

    private

    def valid_input_characters?(characters)
      (characters.is_a?(Array) || characters.is_a?(String)) && characters.size > 0
    end

    def unique_character_alphabet(characters)
      (characters.is_a?(Array) ? characters : characters.chars).uniq
    end

    def sufficient_characters?(unique_alphabet)
      unique_alphabet.size >= MIN_UNIQUE_CHARACTERS
    end

    def valid_equivalences?(equivalences, unique_characters)
      return true if equivalences.nil?
      return false unless equivalences.is_a?(Hash)

      (unique_characters & equivalences.keys).empty? && (equivalences.values - unique_characters).empty?
    end

    def raise_invalid_alphabet!
      raise InvalidAlphabetError, "Alphabet must be a string or array."
    end

    def raise_character_set_too_small!
      raise InvalidAlphabetError, "Alphabet must contain at least #{MIN_UNIQUE_CHARACTERS} unique characters."
    end

    def raise_invalid_equivalences!
      raise InvalidConfigurationError, "Character equivalences must be a hash or nil."
    end
  end
end
