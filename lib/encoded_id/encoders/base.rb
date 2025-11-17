# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    class Base
      # @rbs @min_hash_length: Integer
      # @rbs @alphabet: Alphabet
      # @rbs @salt: String
      # @rbs @blocklist: Blocklist

      # @rbs (String salt, ?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist blocklist) -> void
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = Blocklist.empty)
        @min_hash_length = min_hash_length
        @alphabet = alphabet
        @salt = salt
        @blocklist = blocklist
      end

      attr_reader :min_hash_length #: Integer
      attr_reader :alphabet #: Alphabet
      attr_reader :salt #: String
      attr_reader :blocklist #: Blocklist

      # Encode array of numbers into a string
      # @rbs (Array[Integer] numbers) -> String
      def encode(numbers)
        raise NotImplementedError, "#{self.class} must implement #encode"
      end

      # Encode hexadecimal string(s) into a string
      # @rbs (String str) -> String
      def encode_hex(str)
        return "" unless hex_string?(str)

        numbers = str.scan(/[\w\W]{1,12}/).map do |num|
          "1#{num}".to_i(16)
        end

        encode(numbers)
      end

      # Decode a string back into an array of numbers
      # @rbs (String hash) -> Array[Integer]
      def decode(hash)
        raise NotImplementedError, "#{self.class} must implement #decode"
      end

      # Decode a string back into an array of hexadecimal strings
      # @rbs (String hash) -> String
      def decode_hex(hash)
        numbers = decode(hash)
        return "" if numbers.empty?

        ret = numbers.map do |n|
          n.to_s(16)[1..]
        end

        ret.join.upcase
      end

      private

      # @rbs (String string) -> MatchData?
      def hex_string?(string)
        string.to_s.match(/\A[0-9a-fA-F]+\Z/)
      end
    end
  end
end
