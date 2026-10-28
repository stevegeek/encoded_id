# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Encoder implementation using the Sqids algorithm for encoding/decoding IDs.
    class Sqids
      MIN_ALPHABET_SIZE = 3

      # @rbs @sqids: SqidsWithBlocklistMode
      # @rbs @blocklist_mode: Symbol
      # @rbs @blocklist_max_length: Integer

      # @rbs (?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist blocklist, ?Symbol blocklist_mode, ?Integer blocklist_max_length) -> void
      def initialize(min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = Blocklist.empty, blocklist_mode = :length_threshold, blocklist_max_length = 32)
        if alphabet.size < MIN_ALPHABET_SIZE
          raise InvalidAlphabetError, "Sqids requires an alphabet of at least #{MIN_ALPHABET_SIZE} unique characters."
        end
        @min_hash_length = min_hash_length
        @alphabet = alphabet
        @blocklist = blocklist
        @blocklist_mode = blocklist_mode
        @blocklist_max_length = blocklist_max_length

        @sqids = begin
          ::SqidsWithBlocklistMode.new(
            {
              min_length: min_hash_length,
              alphabet: alphabet.characters,
              blocklist: blocklist,
              blocklist_mode: blocklist_mode,
              blocklist_max_length: blocklist_max_length
            }
          )
        rescue TypeError, ArgumentError => error
          raise InvalidInputError, "unable to create sqids instance: #{error.message}"
        end
      end

      attr_reader :min_hash_length #: Integer
      attr_reader :alphabet #: Alphabet
      attr_reader :blocklist #: Blocklist

      # @rbs (Array[Integer] numbers) -> String
      def encode(numbers)
        numbers.all? { Integer(_1) } # raises if conversion fails
        return "" if numbers.empty? || numbers.any?(&:negative?)

        @sqids.encode(numbers)
      end

      # @rbs (String hash) -> Array[Integer]
      def decode(hash)
        return [] if hash.nil? || hash.empty?

        decoded = @sqids.decode(hash)
        raise InvalidInputError, "unable to unhash" if decoded.empty? && !hash.each_char.all? { @alphabet.include?(_1) }
        return [] if decoded.empty? || decoded.any? { _1 > ::MySqids.max_value }
        return [] if @sqids.encode(decoded) != hash

        decoded
      rescue
        raise InvalidInputError, "unable to unhash"
      end
    end
  end
end
