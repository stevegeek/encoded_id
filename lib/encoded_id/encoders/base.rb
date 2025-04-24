# frozen_string_literal: true

module EncodedId
  module Encoders
    class Base
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = Blocklist.empty, my_sqids = nil)
        @min_hash_length = min_hash_length
        @alphabet = alphabet
        @salt = salt
        @blocklist = blocklist
      end

      attr_reader :min_hash_length, :alphabet, :salt, :blocklist

      # Encode array of numbers into a string
      def encode(numbers)
        raise NotImplementedError, "#{self.class} must implement #encode"
      end

      # Encode hexadecimal string(s) into a string
      def encode_hex(str)
        return "" unless hex_string?(str)

        numbers = str.scan(/[\w\W]{1,12}/).map do |num|
          "1#{num}".to_i(16)
        end

        encode(numbers)
      end

      # Decode a string back into an array of numbers
      def decode(hash)
        raise NotImplementedError, "#{self.class} must implement #decode"
      end

      # Decode a string back into an array of hexadecimal strings
      def decode_hex(hash)
        numbers = decode(hash)
        return "" if numbers.empty?

        ret = numbers.map do |n|
          n.to_s(16)[1..]
        end

        ret.join.upcase
      end

      private

      def hex_string?(string)
        string.to_s.match(/\A[0-9a-fA-F]+\Z/)
      end
    end
  end
end
