# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  # @rbs!
  #   type encodeableHexValue = Array[String] | String

  class HexRepresentation
    # @rbs @hex_digit_encoding_group_size: Integer
    # @rbs @hex_string_separator: Integer

    # @rbs (Integer hex_digit_encoding_group_size) -> void
    def initialize(hex_digit_encoding_group_size)
      @hex_digit_encoding_group_size = validate_hex_digit_encoding_group_size(hex_digit_encoding_group_size)
    end

    # @rbs (encodeableHexValue hexs) -> Array[Integer]
    def hex_as_integers(hexs)
      integer_representation(hexs)
    end

    # @rbs (Array[Integer] integers) -> Array[String]
    def integers_as_hex(integers)
      integers_to_hex_strings(integers)
    end

    private

    # Number of hex digits to encode in each group, larger values will result in shorter hashes for longer inputs.
    # Vice versa for smaller values, ie a smaller value will result in smaller hashes for small inputs.
    # @rbs (Integer hex_digit_encoding_group_size) -> Integer
    def validate_hex_digit_encoding_group_size(hex_digit_encoding_group_size)
      if !hex_digit_encoding_group_size.is_a?(Integer) || hex_digit_encoding_group_size < 1 || hex_digit_encoding_group_size > 32
        raise InvalidConfigurationError, "hex_digit_encoding_group_size must be > 0 and <= 32"
      end
      hex_digit_encoding_group_size
    end

    # @rbs (encodeableHexValue hexs) -> Array[Integer]
    def integer_representation(hexs)
      inputs = Array(hexs).map(&:to_s)
      digits_to_encode = [] #: Array[Integer]

      inputs.map { |hex_string| hex_string_as_integer_representation(hex_string) }.each do |integer_groups|
        digits_to_encode.concat(integer_groups)
        digits_to_encode << hex_string_separator
      end

      digits_to_encode.pop unless digits_to_encode.empty?
      digits_to_encode
    end

    # @rbs (Array[Integer] integers) -> Array[String]
    def integers_to_hex_strings(integers)
      hex_strings = [] #: Array[String]
      hex_string = [] #: Array[String]
      add_leading = false

      integers.reverse_each do |integer|
        if integer == hex_string_separator # Marker to separate hex strings, so start a new one
          hex_strings << hex_string.join
          hex_string = []
          add_leading = false
        else
          # Add leading zeros to maintain group size for all groups except the first
          hex_string << (add_leading ? "%.#{@hex_digit_encoding_group_size}x" % integer : integer.to_s(16))
          add_leading = true
        end
      end

      hex_strings << hex_string.join unless hex_string.empty?
      hex_strings.reverse
    end

    # @rbs (String hex_string) -> Array[Integer]
    def hex_string_as_integer_representation(hex_string)
      cleaned = remove_non_hex_characters(hex_string)
      convert_to_integer_groups(cleaned)
    end

    # Marker to separate hex strings, must be greater than largest value encoded
    # @rbs return: Integer
    def hex_string_separator
      @hex_string_separator ||= 2.pow(@hex_digit_encoding_group_size * 4).to_i
    end

    # @rbs (String hex_string) -> String
    def remove_non_hex_characters(hex_string)
      hex_string.gsub(/[^0-9a-f]/i, "")
    end

    # @rbs (String hex_string_cleaned) -> Array[Integer]
    def convert_to_integer_groups(hex_string_cleaned)
      groups = [] #: Array[Array[String]]
      hex_string_cleaned.chars.reverse.each_with_index do |char, index|
        group_id = index / @hex_digit_encoding_group_size
        group = (groups[group_id] ||= [])
        group.unshift(char)
      end
      groups.map { _1.join.to_i(16) }
    end
  end
end
