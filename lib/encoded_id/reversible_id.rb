# frozen_string_literal: true

require "hashids"

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with https://hashids.org
# Note hashIds already has a built in profanity limitation algorithm
module EncodedId
  class ReversibleId
    def initialize(salt:, length: 8, split_at: 4, split_with: "-", alphabet: Alphabet.modified_crockford, hex_digit_encoding_group_size: 4)
      raise InvalidAlphabetError, "alphabet must be an instance of Alphabet" unless alphabet.is_a?(Alphabet)
      @alphabet = alphabet

      raise InvalidConfigurationError, "Salt must be a string and longer that 3 characters" unless salt.is_a?(String) && salt.size > 3
      @salt = salt
      # Target length of the encoded string (the minimum but not maximum length)
      raise InvalidConfigurationError, "Length must be an integer greater than 0" unless length.is_a?(Integer) && length > 0
      @length = length
      # Split the encoded string into groups of this size
      unless (split_at.is_a?(Integer) && split_at > 0) || split_at.nil?
        raise InvalidConfigurationError, "Split at must be an integer greater than 0 or nil"
      end
      @split_at = split_at
      unless split_with.is_a?(String) && !alphabet.characters.include?(split_with)
        raise InvalidConfigurationError, "Split with must be a string and not part of the alphabet"
      end
      @split_with = split_with
      # Number of hex digits to encode in each group, larger values will result in shorter hashes for longer inputs.
      # Vice versa for smaller values, ie a smaller value will result in smaller hashes for small inputs.
      if hex_digit_encoding_group_size < 1 || hex_digit_encoding_group_size > 32
        raise InvalidConfigurationError, "hex_digit_encoding_group_size must be > 0 and <= 32"
      end
      @hex_digit_encoding_group_size = hex_digit_encoding_group_size
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

    # TODO: optimize this
    def integer_representation(hexs)
      inputs = hexs.is_a?(Array) ? hexs.map(&:to_s) : [hexs.to_s]
      inputs.map! do |hex_string|
        cleaned = hex_string.gsub(/[^0-9a-f]/i, "")
        # Convert to groups of integers. Process least significant hex digits first
        groups = []
        cleaned.chars.reverse.each_with_index do |char, i|
          group_id = i / hex_digit_encoding_group_size.to_i
          groups[group_id] ||= []
          groups[group_id].unshift(char)
        end
        groups.map { |c| c.join.to_i(16) }
      end
      digits_to_encode = []
      inputs.each_with_object(digits_to_encode) do |hex_digits, digits|
        digits.concat(hex_digits)
        digits << hex_string_separator
      end
      digits_to_encode.pop unless digits_to_encode.empty? # Remove the last marker
      digits_to_encode
    end

    # Marker to separate hex strings, must be greater than largest value encoded
    def hex_string_separator
      @hex_string_separator ||= 2.pow(hex_digit_encoding_group_size * 4)
    end

    # TODO: optimize this
    def integers_to_hex_strings(integers)
      hex_strings = []
      hex_string = []
      add_leading = false
      # Digits are encoded in least significant digit first order, but string is most significant first, so reverse
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
      hex_strings << hex_string.join unless hex_string.empty? # Add the last hex string
      hex_strings.reverse # Reverse final values to get the original order (the encoding process also reverses the encoded value order)
    end
  end
end
