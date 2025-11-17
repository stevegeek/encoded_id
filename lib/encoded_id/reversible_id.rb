# frozen_string_literal: true

# rbs_inline: enabled

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with support for https://hashids.org and https://sqids.org
module EncodedId
  # @rbs!
  #   type encodeableValue = Array[String | Integer] | String | Integer

  class ReversibleId
    # @rbs VALID_ENCODERS: Array[Symbol]
    VALID_ENCODERS = [:hashids, :sqids].freeze
    # @rbs DEFAULT_ENCODER: Symbol
    DEFAULT_ENCODER = :hashids

    # @rbs @alphabet: Alphabet
    # @rbs @salt: String
    # @rbs @length: Integer
    # @rbs @split_at: Integer?
    # @rbs @split_with: String?
    # @rbs @hex_represention_encoder: HexRepresentation
    # @rbs @max_length: Integer?
    # @rbs @max_inputs_per_id: Integer
    # @rbs @blocklist: Blocklist
    # @rbs @encoder: Encoders::Base

    # @rbs (salt: String, ?length: Integer, ?split_at: Integer?, ?split_with: String?, ?alphabet: Alphabet, ?hex_digit_encoding_group_size: Integer, ?max_length: Integer?, ?max_inputs_per_id: Integer, ?encoder: Symbol | Encoders::Base, ?blocklist: Blocklist | Array[String] | Set[String] | nil) -> void
    def initialize(salt:, length: 8, split_at: 4, split_with: "-", alphabet: Alphabet.modified_crockford, hex_digit_encoding_group_size: 4, max_length: 128, max_inputs_per_id: 32, encoder: DEFAULT_ENCODER, blocklist: Blocklist.empty)
      @alphabet = validate_alphabet(alphabet)
      @salt = validate_salt(salt)
      @length = validate_length(length)
      @split_at = validate_split_at(split_at)
      @split_with = validate_split_with(split_with, alphabet)
      @hex_represention_encoder = HexRepresentation.new(hex_digit_encoding_group_size)
      @max_length = validate_max_length(max_length)
      @max_inputs_per_id = validate_max_input(max_inputs_per_id)
      @blocklist = validate_blocklist(blocklist)
      @encoder = create_encoder(validate_encoder(encoder))
    end

    # Accessors for introspection
    attr_reader :salt #: String
    attr_reader :length #: Integer
    attr_reader :alphabet #: Alphabet
    attr_reader :split_at #: Integer?
    attr_reader :split_with #: String?
    attr_reader :hex_represention_encoder #: HexRepresentation
    attr_reader :max_length #: Integer?
    attr_reader :blocklist #: Blocklist
    attr_reader :encoder #: Encoders::Base

    # Encode the input values into a hash
    # @rbs (encodeableValue values) -> String
    def encode(values)
      inputs = prepare_input(values)
      encoded_id = encoder.encode(inputs)
      encoded_id = humanize_length(encoded_id) if split_with && split_at

      raise EncodedIdLengthError if max_length_exceeded?(encoded_id)

      encoded_id
    end

    # Encode hex strings into a hash
    # @rbs (encodeableHexValue hexs) -> String
    def encode_hex(hexs)
      encode(hex_represention_encoder.hex_as_integers(hexs))
    end

    # Decode the hash to original array
    # @rbs (String str, ?downcase: bool) -> Array[Integer]
    def decode(str, downcase: true)
      raise EncodedIdFormatError, "Max length of input exceeded" if max_length_exceeded?(str)

      encoder.decode(convert_to_hash(str, downcase))
    rescue InvalidInputError => e
      raise EncodedIdFormatError, e.message
    end

    # Decode hex strings from a hash
    # @rbs (String str, ?downcase: bool) -> Array[String]
    def decode_hex(str, downcase: true)
      integers = encoder.decode(convert_to_hash(str, downcase))
      hex_represention_encoder.integers_as_hex(integers)
    end

    private

    # @rbs (Alphabet alphabet) -> Alphabet
    def validate_alphabet(alphabet)
      return alphabet if alphabet.is_a?(Alphabet)
      raise InvalidAlphabetError, "alphabet must be an instance of Alphabet"
    end

    # @rbs (String salt) -> String
    def validate_salt(salt)
      return salt if salt.is_a?(String) && salt.size > 3
      raise InvalidConfigurationError, "Salt must be a string and longer than 3 characters"
    end

    # Target length of the encoded string (the minimum but not maximum length)
    # @rbs (Integer length) -> Integer
    def validate_length(length)
      return length if valid_integer_option?(length)
      raise InvalidConfigurationError, "Length must be an integer greater than 0"
    end

    # @rbs (Integer? max_length) -> Integer?
    def validate_max_length(max_length)
      return max_length if valid_integer_option?(max_length) || max_length.nil?
      raise InvalidConfigurationError, "Max length must be an integer greater than 0"
    end

    # @rbs (Integer max_inputs_per_id) -> Integer
    def validate_max_input(max_inputs_per_id)
      return max_inputs_per_id if valid_integer_option?(max_inputs_per_id)
      raise InvalidConfigurationError, "Max inputs per ID must be an integer greater than 0"
    end

    # Split the encoded string into groups of this size
    # @rbs (Integer? split_at) -> Integer?
    def validate_split_at(split_at)
      return split_at if valid_integer_option?(split_at) || split_at.nil?
      raise InvalidConfigurationError, "Split at must be an integer greater than 0 or nil"
    end

    # @rbs (String? split_with, Alphabet alphabet) -> String?
    def validate_split_with(split_with, alphabet)
      return split_with if split_with.nil? || (split_with.is_a?(String) && !alphabet.characters.include?(split_with))
      raise InvalidConfigurationError, "Split with must be a string and not part of the alphabet or nil"
    end

    # @rbs (Integer? value) -> bool
    def valid_integer_option?(value)
      value.is_a?(Integer) && value > 0
    end

    # @rbs (encodeableValue value) -> Array[Integer]
    def prepare_input(value)
      inputs = value.is_a?(Array) ? value.map(&:to_i) : [value.to_i]
      raise ::EncodedId::InvalidInputError, "Cannot encode an empty array" if inputs.empty?
      raise ::EncodedId::InvalidInputError, "Integer IDs to be encoded can only be positive" if inputs.any?(&:negative?)

      raise ::EncodedId::InvalidInputError, "%d integer IDs provided, maximum amount of IDs is %d" % [inputs.length, @max_inputs_per_id] if inputs.length > @max_inputs_per_id

      inputs
    end

    # @rbs (Symbol | Encoders::Base encoder) -> Encoders::Base
    def create_encoder(encoder)
      # If an encoder instance was provided, return it directly
      return @encoder if defined?(@encoder) && @encoder.is_a?(Encoders::Base)
      return encoder if encoder.is_a?(Encoders::Base)

      case encoder
      when :sqids
        if defined?(Encoders::Sqids)
          Encoders::Sqids.new(salt, length, alphabet, @blocklist)
        else
          raise InvalidConfigurationError, "Sqids encoder requested but the sqids gem is not available. Please add 'gem \"sqids\"' to your Gemfile."
        end
      when :hashids
        Encoders::HashId.new(salt, length, alphabet, @blocklist)
      else
        raise InvalidConfigurationError, "The encoder name is not supported '#{encoder}'"
      end
    end

    # @rbs (Symbol | Encoders::Base encoder) -> (Symbol | Encoders::Base)
    def validate_encoder(encoder)
      # Accept either a valid symbol or an Encoders::Base instance
      return encoder if VALID_ENCODERS.include?(encoder) || encoder.is_a?(Encoders::Base)
      raise InvalidConfigurationError, "Encoder must be one of: #{VALID_ENCODERS.join(", ")} or an instance of EncodedId::Encoders::Base"
    end

    # @rbs (Blocklist | Array[String] | Set[String] | nil blocklist) -> Blocklist
    def validate_blocklist(blocklist)
      return blocklist if blocklist.is_a?(Blocklist)
      return Blocklist.empty if blocklist.nil?

      return Blocklist.new(blocklist) if blocklist.is_a?(Array) || blocklist.is_a?(Set)

      raise InvalidConfigurationError, "Blocklist must be an instance of Blocklist, a Set, or an Array of strings"
    end

    # @rbs (String hash) -> String
    def humanize_length(hash)
      len = hash.length
      at = split_at #: Integer
      with = split_with #: String
      return hash if len <= at

      separator_count = (len - 1) / at
      result = hash.dup
      insert_offset = 0
      (1..separator_count).each do |i|
        insert_pos = i * at + insert_offset
        result.insert(insert_pos, with)
        insert_offset += with.length
      end
      result
    end

    # @rbs (String str, bool downcase) -> String
    def convert_to_hash(str, downcase)
      str = str.gsub(split_with, "") if split_with
      str = str.downcase if downcase
      map_equivalent_characters(str)
    end

    # @rbs (String str) -> String
    def map_equivalent_characters(str)
      return str unless alphabet.equivalences

      alphabet.equivalences.reduce(str) do |cleaned, ceq|
        from, to = ceq
        cleaned.tr(from, to)
      end
    end

    # @rbs (String str) -> bool
    def max_length_exceeded?(str)
      return false if max_length.nil?

      str.length > max_length
    end
  end
end
