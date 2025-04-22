# frozen_string_literal: true

module EncodedId
  module Encoders
    class Base
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum)
        @min_hash_length = min_hash_length
        @alphabet = alphabet
        @salt = salt
      end

      # Encode array of numbers into a string
      def encode(numbers)
        raise NotImplementedError, "#{self.class} must implement #encode"
      end

      # Encode hexadecimal string(s) into a string
      def encode_hex(str)
        raise NotImplementedError, "#{self.class} must implement #encode_hex"
      end

      # Decode a string back into an array of numbers
      def decode(hash)
        raise NotImplementedError, "#{self.class} must implement #decode"
      end

      # Decode a string back into an array of hexadecimal strings
      def decode_hex(hash)
        raise NotImplementedError, "#{self.class} must implement #decode_hex"
      end

      protected

      attr_reader :min_hash_length, :alphabet, :salt

      def hex_string?(string)
        string.to_s.match(/\A[0-9a-fA-F]+\Z/)
      end
    end
  end
end
