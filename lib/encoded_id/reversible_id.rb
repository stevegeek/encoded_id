# frozen_string_literal: true

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with https://hashids.org
# Note hashIds already has a built in profanity limitation algorithm
module EncodedId
  class ReversibleId
    def initialize(salt:, length: 8, split_at: 4, split_with: "-", alphabet: Alphabet.modified_crockford, hex_digit_encoding_group_size: 4, max_length: 128, max_inputs_per_id: 32)
      @alphabet = validate_alphabet(alphabet)
      @salt = validate_salt(salt)
      @length = validate_length(length)
      @split_at = validate_split_at(split_at)
      @split_with = validate_split_with(split_with, alphabet)
      @hex_represention_encoder = HexRepresentation.new(hex_digit_encoding_group_size)
      @max_length = validate_max_length(max_length)
      @max_inputs_per_id = validate_max_input(max_inputs_per_id)
    end

    # Encode the input values into a hash
    def encode(values)
      inputs = prepare_input(values)
      encoded_id = encoded_id_generator.encode(inputs)
      encoded_id = humanize_length(encoded_id) unless split_with.nil? || split_at.nil?

      raise EncodedIdLengthError if max_length_exceeded?(encoded_id)

      encoded_id
    end

    # Encode hex strings into a hash
    def encode_hex(hexs)
      encode(hex_represention_encoder.hex_as_integers(hexs))
    end

    # Decode the hash to original array
    def decode(str, downcase: true)
      raise EncodedIdFormatError, "Max length of input exceeded" if max_length_exceeded?(str)

      encoded_id_generator.decode(convert_to_hash(str, downcase))
    rescue InvalidInputError => e
      raise EncodedIdFormatError, e.message
    end

    # Decode hex strings from a hash
    def decode_hex(str, downcase: true)
      integers = encoded_id_generator.decode(convert_to_hash(str, downcase))
      hex_represention_encoder.integers_as_hex(integers)
    end

    private

    attr_reader :salt,
      :length,
      :alphabet,
      :split_at,
      :split_with,
      :hex_represention_encoder,
      :max_length

    def validate_alphabet(alphabet)
      return alphabet if alphabet.is_a?(Alphabet)
      raise InvalidAlphabetError, "alphabet must be an instance of Alphabet"
    end

    def validate_salt(salt)
      return salt if salt.is_a?(String) && salt.size > 3
      raise InvalidConfigurationError, "Salt must be a string and longer than 3 characters"
    end

    # Target length of the encoded string (the minimum but not maximum length)
    def validate_length(length)
      return length if valid_integer_option?(length)
      raise InvalidConfigurationError, "Length must be an integer greater than 0"
    end

    def validate_max_length(max_length)
      return max_length if valid_integer_option?(max_length) || max_length.nil?
      raise InvalidConfigurationError, "Max length must be an integer greater than 0"
    end

    def validate_max_input(max_inputs_per_id)
      return max_inputs_per_id if valid_integer_option?(max_inputs_per_id)
      raise InvalidConfigurationError, "Max inputs per ID must be an integer greater than 0"
    end

    # Split the encoded string into groups of this size
    def validate_split_at(split_at)
      return split_at if valid_integer_option?(split_at) || split_at.nil?
      raise InvalidConfigurationError, "Split at must be an integer greater than 0 or nil"
    end

    def validate_split_with(split_with, alphabet)
      return split_with if split_with.nil? || (split_with.is_a?(String) && !alphabet.characters.include?(split_with))
      raise InvalidConfigurationError, "Split with must be a string and not part of the alphabet or nil"
    end

    def valid_integer_option?(value)
      value.is_a?(Integer) && value > 0
    end

    def prepare_input(value)
      inputs = value.is_a?(Array) ? value.map(&:to_i) : [value.to_i]
      raise ::EncodedId::InvalidInputError, "Integer IDs to be encoded can only be positive" if inputs.any?(&:negative?)

      raise ::EncodedId::InvalidInputError, "%d integer IDs provided, maximum amount of IDs is %d" % [inputs.length, @max_inputs_per_id] if inputs.length > @max_inputs_per_id

      inputs
    end

    def encoded_id_generator
      @encoded_id_generator ||= HashId.new(salt, length, alphabet)
    end

    def split_regex
      @split_regex ||= /.{#{split_at}}(?=.)/
    end

    def humanize_length(hash)
      hash.gsub(split_regex, "\\0#{split_with}")
    end

    def convert_to_hash(str, downcase)
      clean = str.gsub(split_with, "")
      clean = clean.downcase if downcase
      map_equivalent_characters(clean)
    end

    def map_equivalent_characters(str)
      return str unless alphabet.equivalences

      alphabet.equivalences.reduce(str) do |cleaned, ceq|
        from, to = ceq
        cleaned.tr(from, to)
      end
    end

    def max_length_exceeded?(str)
      return false if max_length.nil?

      str.length > max_length
    end
  end
end
