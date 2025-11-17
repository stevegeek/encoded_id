# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    class Sqids < Base
      # @rbs @sqids: untyped

      # @rbs (String salt, ?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist blocklist) -> void
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = Blocklist.empty)
        super
        @sqids = ::MySqids.new(
          {
            min_length: min_hash_length,
            alphabet: alphabet.characters,
            blocklist: blocklist
          }
        )
      rescue TypeError, ArgumentError => e
        raise InvalidInputError, "unable to create sqids instance: #{e.message}"
      end

      # @rbs (Array[Integer] numbers) -> String
      def encode(numbers)
        numbers.all? { |n| Integer(n) } # raises if conversion fails
        return "" if numbers.empty? || numbers.any? { |n| n < 0 }

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
