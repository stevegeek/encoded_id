# frozen_string_literal: true

module EncodedId
  module Encoders
    class Sqids < Base
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = nil, my_sqids = nil)
        super
        @sqids = (my_sqids ? MySqids : ::Sqids).new(
          {
            min_length: min_hash_length,
            alphabet: alphabet.characters,
            blocklist: blocklist
          }
        )
      rescue TypeError, ArgumentError => e
        raise InvalidInputError, "unable to create sqids instance: #{e.message}"
      end

      def encode(numbers)
        numbers.all? { |n| Integer(n) } # raises if conversion fails
        return "" if numbers.empty? || numbers.any? { |n| n < 0 }

        @sqids.encode(numbers)
      end

      def decode(hash)
        return [] if hash.nil? || hash.empty?

        @sqids.decode(hash)
      rescue
        raise InvalidInputError, "unable to unhash"
      end
    end
  end
end
