# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  # Represents a character set (alphabet) used for encoding IDs, with optional character equivalences.
  class Alphabet
    MIN_UNIQUE_CHARACTERS = 16

    class << self
      # @rbs return: Alphabet
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

      # @rbs return: Alphabet
      def alphanum
        new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
      end
    end

    # @rbs @unique_characters: Array[String]
    # @rbs @characters: String
    # @rbs @equivalences: Hash[String, String]?

    # @rbs (String | Array[String] characters, ?Hash[String, String]? equivalences) -> void
    def initialize(characters, equivalences = nil)
      raise_invalid_alphabet! unless valid_input_characters?(characters)
      @unique_characters = unique_character_alphabet(characters)
      raise_invalid_characters! unless valid_characters?
      raise_character_set_too_small! unless sufficient_characters?
      raise_invalid_equivalences! unless valid_equivalences?(equivalences)

      @characters = unique_characters.join
      @equivalences = equivalences
    end

    attr_reader :unique_characters #: Array[String]
    attr_reader :characters #: String
    attr_reader :equivalences #: Hash[String, String]?

    # @rbs (String character) -> bool
    def include?(character)
      unique_characters.include?(character)
    end

    # @rbs return: Array[String]
    def to_a
      unique_characters.dup
    end

    # @rbs return: String
    def to_s
      @characters.dup
    end

    # @rbs return: String
    def inspect
      "#<#{self.class.name} chars: #{unique_characters.inspect}>"
    end

    # @rbs return: Integer
    def size
      unique_characters.size
    end
    alias_method :length, :size

    private

    # @rbs (String | Array[String] characters) -> bool
    def valid_input_characters?(characters)
      return false unless characters.is_a?(Array) || characters.is_a?(String)
      characters.size > 0
    end

    # @rbs (String | Array[String] characters) -> Array[String]
    def unique_character_alphabet(characters)
      (characters.is_a?(Array) ? characters : characters.chars).uniq
    end

    # @rbs return: bool
    def valid_characters?
      unique_characters.size > 0 && unique_characters.grep(/\s|\0/).size == 0
    end

    # @rbs return: bool
    def sufficient_characters?
      unique_characters.size >= MIN_UNIQUE_CHARACTERS
    end

    # @rbs (Hash[String, String]? equivalences) -> bool
    def valid_equivalences?(equivalences)
      return true if equivalences.nil?
      return false unless equivalences.is_a?(Hash)
      return false if equivalences.any? { |key, value| key.size != 1 || value.size != 1 }

      (unique_characters & equivalences.keys).empty? && (equivalences.values - unique_characters).empty?
    end

    # @rbs return: void
    def raise_invalid_alphabet!
      raise InvalidAlphabetError, "Alphabet must be a populated string or array"
    end

    # @rbs return: void
    def raise_invalid_characters!
      raise InvalidAlphabetError, "Alphabet must not contain whitespace or null characters."
    end

    # @rbs return: void
    def raise_character_set_too_small!
      raise InvalidAlphabetError, "Alphabet must contain at least #{MIN_UNIQUE_CHARACTERS} unique characters."
    end

    # @rbs return: void
    def raise_invalid_equivalences!
      raise InvalidConfigurationError, "Character equivalences must be a hash or nil and contain mappings to valid alphabet characters."
    end
  end
end
