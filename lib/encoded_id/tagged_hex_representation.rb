# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  # Splits each hex string into the fewest chunks of at most 15 hex digits, with lengths
  # that differ by at most one. A chunk becomes the integer of its digits prefixed with
  # the hex digit 1 (more chunks follow) or 2 (last chunk of the string), so leading zeros
  # and empty strings round-trip and every value stays below the Sqids maximum of 2**62 - 1.
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
        return [] if tagged.length > CHUNK_SIZE + 1
        case tagged[0]
        when MORE_CHUNKS_TAG
          pending << tagged[1..].to_s
        when LAST_CHUNK_TAG
          hex_strings << pending + tagged[1..].to_s
          pending = +""
        else
          return []
        end
      end
      return [] unless pending.empty?
      (hex_as_integers(hex_strings) == integers) ? hex_strings : []
    end

    private

    # @rbs (String hex_string) -> Array[Integer]
    def hex_string_as_integers(hex_string)
      cleaned = hex_string.delete("^0-9a-fA-F").downcase
      raise InvalidInputError, "Hex string #{hex_string.inspect} contains no hex digits" if cleaned.empty? && !hex_string.empty?

      chunk_count = [cleaned.length.ceildiv(CHUNK_SIZE), 1].max
      short_length, longer_chunks = cleaned.length.divmod(chunk_count)
      offset = 0
      Array.new(chunk_count) do |index|
        length = (index < longer_chunks) ? short_length + 1 : short_length
        tag = (index == chunk_count - 1) ? LAST_CHUNK_TAG : MORE_CHUNKS_TAG
        chunk = cleaned[offset, length].to_s
        offset += length
        (tag + chunk).to_i(16)
      end
    end
  end
end
