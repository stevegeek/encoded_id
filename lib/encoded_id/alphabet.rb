# frozen_string_literal: true

module EncodedId
  class Alphabet
    def initialize(characters, equivalences = nil)
      raise InvalidAlphabetError, "Alphabet must be a string" unless characters.is_a?(String) && characters.size > 0
      unique_alphabet = characters.chars.uniq
      raise InvalidAlphabetError, "Alphabet must be at least 16 unique characters" if unique_alphabet.size < 16
      @characters = unique_alphabet.join

      # Equivalences is a hash of characters to their equivalent character.
      # Characters to be mapped must not be in the alphabet, and must map to a character that is in the alphabet.
      raise InvalidConfigurationError, "Character equivalences must be a hash or nil" unless equivalences.nil? || equivalences.is_a?(Hash)
      valid_equivalences = equivalences.nil? || (unique_alphabet & equivalences.keys).empty? && (equivalences.values - unique_alphabet).empty?
      raise InvalidConfigurationError unless valid_equivalences
      @equivalences = equivalences
    end

    attr_reader :characters, :equivalences

    class << self
      def modified_crockford
        # Note we downcase first, so mappings are only for lower case. Also Crockford suggests i==1,
        # but here i==j is used.

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
  end
end
