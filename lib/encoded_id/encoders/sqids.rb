# frozen_string_literal: true

module EncodedId
  module Encoders
    class Sqids < Base
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = nil)
        super
        @sqids = ::Sqids.new(
          min_length: min_hash_length,
          alphabet: alphabet.characters,
          blocklist: blocklist
        )
      end

      def encode(numbers)
        numbers.all? { |n| Integer(n) } # raises if conversion fails
        return "" if numbers.empty? || numbers.any? { |n| n < 0 }

        @sqids.encode(numbers)
      end

      def decode(hash)
        return [] if hash.nil? || hash.empty?

        # Check if the hash contains any characters not in the alphabet
        hash.each_char do |char|
          unless @sqids.instance_variable_get(:@alphabet).include?(char)
            raise InvalidInputError, "unable to unhash"
          end
        end

        @sqids.decode(hash)
      rescue
        raise InvalidInputError, "unable to unhash"
      end
    end
  end
end
