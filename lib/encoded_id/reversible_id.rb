# frozen_string_literal: true

require "hashids"

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with https://hashids.org
# Note hashIds already has a built in profanity limitation algorithm
module EncodedId
  class ReversibleId
    def initialize(salt:, length: 8, split_at: 4, split_with: "-", alphabet: Alphabet.modified_crockford, hex_digit_encoding_group_size: 4)
      @alphabet = validate_alphabet(alphabet)
      @salt = validate_salt(salt)
      @length = validate_length(length)
      @split_at = validate_split_at(split_at)
      @split_with = validate_split_with(split_with, alphabet)
      @hex_digit_encoding_group_size = validate_hex_digit_encoding_group_size(hex_digit_encoding_group_size)
    end

    # Encode the input values into a hash
    def encode(values)
      inputs = prepare_input(values)
      encoded_id = encoded_id_generator.encode(inputs)
      encoded_id = humanize_length(encoded_id) unless split_at.nil?
      encoded_id
    end

    # Encode hex strings into a hash
    def encode_hex(hexs)
      encode(integer_representation(hexs))
    end

    # Decode the hash to original array
    def decode(str)
      encoded_id_generator.decode(convert_to_hash(str))
    rescue ::Hashids::InputError => e
      raise EncodedIdFormatError, e.message
    end

    # Decode hex strings from a hash
    def decode_hex(str)
      integers = encoded_id_generator.decode(convert_to_hash(str))
      integers_to_hex_strings(integers)
    end

    private

    attr_reader :salt,
      :length,
      :alphabet,
      :split_at,
      :split_with,
      :hex_digit_encoding_group_size

    def validate_alphabet(alphabet)
      raise InvalidAlphabetError, "alphabet must be an instance of Alphabet" unless alphabet.is_a?(Alphabet)
      alphabet
    end

    def validate_salt(salt)
      raise InvalidConfigurationError, "Salt must be a string and longer than 3 characters" unless salt.is_a?(String) && salt.size > 3
      salt
    end

    # Target length of the encoded string (the minimum but not maximum length)
    def validate_length(length)
      raise InvalidConfigurationError, "Length must be an integer greater than 0" unless length.is_a?(Integer) && length > 0
      length
    end

    # Split the encoded string into groups of this size
    def validate_split_at(split_at)
      unless (split_at.is_a?(Integer) && split_at > 0) || split_at.nil?
        raise InvalidConfigurationError, "Split at must be an integer greater than 0 or nil"
      end
      split_at
    end

    def validate_split_with(split_with, alphabet)
      unless split_with.is_a?(String) && !alphabet.characters.include?(split_with)
        raise InvalidConfigurationError, "Split with must be a string and not part of the alphabet"
      end
      split_with
    end

    # Number of hex digits to encode in each group, larger values will result in shorter hashes for longer inputs.
    # Vice versa for smaller values, ie a smaller value will result in smaller hashes for small inputs.
    def validate_hex_digit_encoding_group_size(hex_digit_encoding_group_size)
      if hex_digit_encoding_group_size < 1 || hex_digit_encoding_group_size > 32
        raise InvalidConfigurationError, "hex_digit_encoding_group_size must be > 0 and <= 32"
      end
      hex_digit_encoding_group_size
    end

    def prepare_input(value)
      inputs = value.is_a?(Array) ? value.map(&:to_i) : [value.to_i]
      raise ::EncodedId::InvalidInputError, "Integer IDs to be encoded can only be positive" if inputs.any?(&:negative?)

      inputs
    end

    def encoded_id_generator
      @encoded_id_generator ||= ::Hashids.new(salt, length, alphabet.characters)
    end

    def split_regex
      @split_regex ||= /.{#{split_at}}(?=.)/
    end

    def humanize_length(hash)
      hash.gsub(split_regex, "\\0#{split_with}")
    end

    def convert_to_hash(str)
      clean = str.delete(split_with).downcase
      alphabet.equivalences.nil? ? clean : map_equivalent_characters(clean)
    end

    def map_equivalent_characters(str)
      alphabet.equivalences.reduce(str) do |cleaned, ceq|
        from, to = ceq
        cleaned.tr(from, to)
      end
    end

    # Convert hex strings to integer representations
    def integer_representation(hexs)
      inputs = Array(hexs).map(&:to_s)
      digits_to_encode = []

      inputs.map { |hex_string| hex_string_as_integer_representation(hex_string) }.each do |integer_groups|
        digits_to_encode.concat(integer_groups)
        digits_to_encode << hex_string_separator
      end

      # Remove the last marker
      digits_to_encode.pop unless digits_to_encode.empty?
      digits_to_encode
    end

    # Convert integer representations to hex strings
    def integers_to_hex_strings(integers)
      hex_strings = []
      hex_string = []
      add_leading = false

      integers.reverse_each do |integer|
        if integer == hex_string_separator # Marker to separate hex strings, so start a new one
          hex_strings << hex_string.join
          hex_string = []
          add_leading = false
        else
          hex_string << (add_leading ? "%.#{hex_digit_encoding_group_size}x" % integer : integer.to_s(16))
          add_leading = true
        end
      end

      # Add the last hex string
      hex_strings << hex_string.join unless hex_string.empty?
      hex_strings.reverse
    end

    def hex_string_as_integer_representation(hex_string)
      cleaned = remove_non_hex_characters(hex_string)
      convert_to_integer_groups(cleaned)
    end

    # Marker to separate hex strings, must be greater than largest value encoded
    def hex_string_separator
      @hex_string_separator ||= 2.pow(@hex_digit_encoding_group_size * 4)
    end

    def remove_non_hex_characters(hex_string)
      hex_string.gsub(/[^0-9a-f]/i, "")
    end

    def convert_to_integer_groups(hex_string_cleaned)
      groups = []
      hex_string_cleaned.chars.reverse.each_with_index do |char, i|
        group_id = i / @hex_digit_encoding_group_size
        groups[group_id] ||= []
        groups[group_id].unshift(char)
      end
      groups.map { |c| c.join.to_i(16) }
    end
  end
end
