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

      inputs.each_with_index do |hex_string, index|
        digits_to_encode.concat(hex_string_as_integer_representation(hex_string, first: index.zero?))
        digits_to_encode << hex_string_separator
      end

      digits_to_encode.pop unless digits_to_encode.empty?
      digits_to_encode
    end

    # @rbs (Array[Integer] integers) -> Array[String]
    def integers_to_hex_strings(integers)
      elements = [[]] #: Array[Array[Integer]]
      integers.each do |integer|
        if integer == hex_string_separator
          elements << []
        else
          elements.last&.push(integer)
        end
      end

      hex_strings = [] #: Array[String]
      elements.each_with_index do |groups, index|
        # IDs encoded before length markers existed give an empty first string no groups, and it decodes to nothing as it did then
        next if index.zero? && groups.empty?
        hex_string = groups_to_hex_string(groups)
        return [] if hex_string.nil?
        hex_strings << hex_string
      end
      hex_strings
    end

    # @rbs (Array[Integer] groups) -> String?
    def groups_to_hex_string(groups)
      return "" if groups.empty?

      most_significant_length = nil #: Integer?
      last_group = groups.last #: Integer
      if last_group > hex_string_separator
        return nil if last_group > length_marker(@hex_digit_encoding_group_size)
        most_significant_length = last_group - length_marker(0)
        groups = groups[0...-1] || []
      end
      return nil if groups.any? { |group| group > hex_string_separator }

      most_significant = groups.last
      return (most_significant_length&.zero? ? "" : nil) if most_significant.nil?
      return nil if most_significant_length&.zero?

      leading = most_significant_length ? "%.#{most_significant_length}x" % most_significant : most_significant.to_s(16)
      return nil if most_significant_length && leading.length > most_significant_length

      rest = groups[0...-1] || []
      leading + rest.reverse.map { |group| "%.#{@hex_digit_encoding_group_size}x" % group }.join
    end

    # @rbs (String hex_string, first: bool) -> Array[Integer]
    def hex_string_as_integer_representation(hex_string, first:)
      cleaned = remove_non_hex_characters(hex_string)
      if cleaned.empty?
        raise InvalidInputError, "Hex string #{hex_string.inspect} contains no hex digits" unless hex_string.empty?
        # Only a first empty string needs a marker: a later one already round-trips as an empty slot between separators
        return first ? [length_marker(0)] : []
      end

      groups = convert_to_integer_groups(cleaned)
      most_significant_length = (cleaned.length - 1) % @hex_digit_encoding_group_size + 1
      return groups if groups.last.to_s(16).length == most_significant_length
      groups + [length_marker(most_significant_length)]
    end

    # Values above the separator record the digit count of a string's most significant group, which integers alone lose for leading zeros
    # @rbs (Integer length) -> Integer
    def length_marker(length)
      hex_string_separator + 1 + length
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
