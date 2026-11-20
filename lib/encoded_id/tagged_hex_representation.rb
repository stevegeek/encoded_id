# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  # Encodes each hex string as chunks of up to 15 hex digits. A chunk becomes the integer
  # of its digits prefixed with the hex digit 1 (more chunks follow) or 2 (last chunk of
  # the string), so leading zeros and empty strings round-trip and every value stays
  # below the Sqids maximum of 2**62 - 1.
  class TaggedHexRepresentation
    CHUNK_SIZE = 15 #: Integer
    MORE_CHUNKS_TAG = "1" #: String
    LAST_CHUNK_TAG = "2" #: String

    # @rbs (encodeableHexValue hexs) -> Array[Integer]
    def hex_as_integers(hexs)
      Array(hexs).flat_map { |hex_string| hex_string_as_integers(hex_string.to_s) }
    end

    # Returns [] unless the integers are exactly what encoding the decoded strings gives,
    # so each list of hex strings has a single ID.
    # @rbs (Array[Integer] integers) -> Array[String]
    def integers_as_hex(integers)
      hex_strings = [] #: Array[String]
      current = +""
      ended = true
      integers.each do |integer|
        return [] if integer.negative?
        tagged = integer.to_s(16)
        case tagged[0]
        when MORE_CHUNKS_TAG then ended = false
        when LAST_CHUNK_TAG then ended = true
        else return []
        end
        current << tagged[1..].to_s
        next unless ended
        hex_strings << current
        current = +""
      end
      return [] unless ended
      return [] unless hex_as_integers(hex_strings) == integers
      hex_strings
    end

    private

    # @rbs (String hex_string) -> Array[Integer]
    def hex_string_as_integers(hex_string)
      cleaned = hex_string.gsub(/[^0-9a-f]/i, "").downcase
      raise InvalidInputError, "Hex string #{hex_string.inspect} contains no hex digits" if cleaned.empty? && !hex_string.empty?

      chunks = cleaned.empty? ? [""] : cleaned.chars.each_slice(CHUNK_SIZE).map(&:join)
      chunks.each_with_index.map do |chunk, index|
        tag = (index == chunks.length - 1) ? LAST_CHUNK_TAG : MORE_CHUNKS_TAG
        (tag + chunk).to_i(16)
      end
    end
  end
end
