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

      def alphanum
        new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
      end
    end

    def initialize(characters, equivalences = nil)
      raise_invalid_alphabet! unless valid_input_characters?(characters)
      @unique_characters = unique_character_alphabet(characters)
      raise_invalid_alphabet! unless valid_characters?
      raise_character_set_too_small! unless sufficient_characters?
      raise_invalid_equivalences! unless valid_equivalences?(equivalences)

      @characters = unique_characters.join
      @equivalences = equivalences
    end

    attr_reader :unique_characters, :characters, :equivalences

    def include?(character)
      unique_characters.include?(character)
    end

    def to_a
      unique_characters.dup
    end

    def to_s
      @characters.dup
    end

    def inspect
      "#<#{self.class.name} chars: #{unique_characters.inspect}>"
    end

    def size
      unique_characters.size
    end
    alias_method :length, :size

    private

    def valid_input_characters?(characters)
      return false unless characters.is_a?(Array) || characters.is_a?(String)
      characters.size > 0
    end

    def unique_character_alphabet(characters)
      (characters.is_a?(Array) ? characters : characters.chars).uniq
    end

    def valid_characters?
      unique_characters.size > 0 && unique_characters.grep(/\s|\0/).size == 0
    end

    def sufficient_characters?
      unique_characters.size >= MIN_UNIQUE_CHARACTERS
    end

    def valid_equivalences?(equivalences)
      return true if equivalences.nil?
      return false unless equivalences.is_a?(Hash)
      return false if equivalences.any? { |key, value| key.size != 1 || value.size != 1 }

      (unique_characters & equivalences.keys).empty? && (equivalences.values - unique_characters).empty?
    end

    def raise_invalid_alphabet!
      raise InvalidAlphabetError, "Alphabet must be a string or array and not contain whitespace."
    end

    def raise_character_set_too_small!
      raise InvalidAlphabetError, "Alphabet must contain at least #{MIN_UNIQUE_CHARACTERS} unique characters."
    end

    def raise_invalid_equivalences!
      raise InvalidConfigurationError, "Character equivalences must be a hash or nil and contain mappings to valid alphabet characters."
    end
  end
end
