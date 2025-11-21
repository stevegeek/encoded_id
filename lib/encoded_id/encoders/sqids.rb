# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Encoder implementation using the Sqids algorithm for encoding/decoding IDs.
    class Sqids
      # @rbs @sqids: SqidsWithBlocklistMode
      # @rbs @blocklist_mode: Symbol
      # @rbs @blocklist_max_length: Integer

      # @rbs (?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist blocklist, ?Symbol blocklist_mode, ?Integer blocklist_max_length) -> void
      def initialize(min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = Blocklist.empty, blocklist_mode = :length_threshold, blocklist_max_length = 32)
        @min_hash_length = min_hash_length
        @alphabet = alphabet
        @blocklist = blocklist
        @blocklist_mode = blocklist_mode
        @blocklist_max_length = blocklist_max_length

        @sqids = ::SqidsWithBlocklistMode.new(
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

        @sqids.decode(hash)
      rescue
        raise InvalidInputError, "unable to unhash"
      end
    end
  end
end
