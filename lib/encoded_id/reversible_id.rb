# frozen_string_literal: true

# rbs_inline: enabled

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with support for https://hashids.org and https://sqids.org
module EncodedId
  # @rbs!
  #   type encodeableValue = Array[String | Integer] | String | Integer

  class ReversibleId
    # @rbs @config: Configuration::Base
    # @rbs @hex_represention_encoder: HexRepresentation
    # @rbs @encoder: untyped

    # Factory method to create a Hashid-based reversible ID
    # @rbs (**untyped) -> ReversibleId
    def self.hashid(...)
      new(Configuration::Hashid.new(...))
    end

    # Factory method to create a Sqids-based reversible ID (default)
    # @rbs (**untyped) -> ReversibleId
    def self.sqids(...)
      new(Configuration::Sqids.new(...))
    end

    # Initialize with a configuration object
    # Defaults to Sqids configuration if called with no arguments
    # @rbs (?Configuration::Base? config) -> void
    def initialize(config = nil)
      @config = config || Configuration::Sqids.new

      unless @config.is_a?(Configuration::Base)
        raise InvalidConfigurationError, "config must be an instance of Configuration::Base (or nil for default Sqids)"
      end

      @hex_represention_encoder = HexRepresentation.new(@config.hex_digit_encoding_group_size)
      @encoder = create_encoder
    end

    # Accessors for introspection (delegated to config)
    # @rbs () -> String?
    def salt
      config = @config
      return config.salt if config.is_a?(Configuration::Hashid)
      nil
    end

    def min_length
      @config.min_length
    end

    def alphabet
      @config.alphabet
    end

    def split_at
      @config.split_at
    end

    def split_with
      @config.split_with
    end

    def hex_represention_encoder
      @hex_represention_encoder
    end

    def max_length
      @config.max_length
    end

    def blocklist
      @config.blocklist
    end

    attr_reader :encoder #: untyped

    # Encode the input values into a hash
    # @rbs (encodeableValue values) -> String
    def encode(values)
      inputs = prepare_input(values)
      encoded_id = encoder.encode(inputs)
      encoded_id = humanize_length(encoded_id) if @config.split_with && @config.split_at

      raise EncodedIdLengthError if max_length_exceeded?(encoded_id)

      encoded_id
    end

    # Encode hex strings into a hash
    # @rbs (encodeableHexValue hexs) -> String
    def encode_hex(hexs)
      encode(@hex_represention_encoder.hex_as_integers(hexs))
    end

    # Decode the hash to original array
    # @rbs (String str, ?downcase: bool) -> Array[Integer]
    def decode(str, downcase: false)
      raise EncodedIdFormatError, "Max length of input exceeded" if max_length_exceeded?(str)

      encoder.decode(convert_to_hash(str, downcase))
    rescue InvalidInputError => error
      raise EncodedIdFormatError, error.message
    end

    # Decode hex strings from a hash
    # @rbs (String str, ?downcase: bool) -> Array[String]
    def decode_hex(str, downcase: false)
      integers = encoder.decode(convert_to_hash(str, downcase))
      @hex_represention_encoder.integers_as_hex(integers)
    end

    private

    # @rbs (encodeableValue value) -> Array[Integer]
    def prepare_input(value)
      inputs = value.is_a?(Array) ? value.map(&:to_i) : [value.to_i]
      raise ::EncodedId::InvalidInputError, "Cannot encode an empty array" if inputs.empty?
      raise ::EncodedId::InvalidInputError, "Integer IDs to be encoded can only be positive" if inputs.any?(&:negative?)
      raise ::EncodedId::InvalidInputError, "%d integer IDs provided, maximum amount of IDs is %d" % [inputs.length, @config.max_inputs_per_id] if inputs.length > @config.max_inputs_per_id

      inputs
    end

    # @rbs () -> untyped
    def create_encoder
      case @config.encoder_type
      when :sqids
        Encoders::Sqids.new(@config.min_length, @config.alphabet, @config.blocklist)
      when :hashids
        config = @config #: Configuration::Hashid
        Encoders::Hashid.new(config.salt, config.min_length, config.alphabet, config.blocklist)
      else
        raise InvalidConfigurationError, "Unsupported encoder type: #{@config.encoder_type}"
      end
    end

    # @rbs (String hash) -> String
    def humanize_length(hash)
      len = hash.length
      at = @config.split_at #: Integer
      with = @config.split_with #: String
      return hash if len <= at

      separator_count = (len - 1) / at
      result = hash.dup
      insert_offset = 0
      (1..separator_count).each do |separator_index|
        insert_pos = separator_index * at + insert_offset
        result.insert(insert_pos, with)
        insert_offset += with.length
      end
      result
    end

    # @rbs (String str, bool downcase) -> String
    def convert_to_hash(str, downcase)
      str = str.gsub(@config.split_with, "") if @config.split_with
      str = str.downcase if downcase
      map_equivalent_characters(str)
    end

    # @rbs (String str) -> String
    def map_equivalent_characters(str)
      equivalences = @config.alphabet.equivalences
      return str unless equivalences

      equivalences.reduce(str) do |cleaned, ceq|
        from, to = ceq
        cleaned.tr(from, to)
      end
    end

    # @rbs (String str) -> bool
    def max_length_exceeded?(str)
      return false if @config.max_length.nil?

      str.length > @config.max_length
    end
  end
end
