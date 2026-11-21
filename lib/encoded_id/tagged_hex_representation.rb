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
      pending = +""
      integers.each do |integer|
        tagged = integer.to_s(16)
        chunk = tagged[1..].to_s
        return [] if chunk.length > CHUNK_SIZE
        case tagged[0]
        when MORE_CHUNKS_TAG
          return [] unless chunk.length == CHUNK_SIZE
          pending << chunk
        when LAST_CHUNK_TAG
          return [] if chunk.empty? && !pending.empty?
          hex_strings << pending + chunk
          pending = +""
        else
          return []
        end
      end
      pending.empty? ? hex_strings : []
    end

    private

    # @rbs (String hex_string) -> Array[Integer]
    def hex_string_as_integers(hex_string)
      cleaned = hex_string.delete("^0-9a-fA-F").downcase
      raise InvalidInputError, "Hex string #{hex_string.inspect} contains no hex digits" if cleaned.empty? && !hex_string.empty?

      integers = [] #: Array[Integer]
      offset = 0
      while cleaned.length - offset > CHUNK_SIZE
        integers << (MORE_CHUNKS_TAG + cleaned[offset, CHUNK_SIZE].to_s).to_i(16)
        offset += CHUNK_SIZE
      end
      integers << (LAST_CHUNK_TAG + cleaned[offset..].to_s).to_i(16)
    end
  end
end
