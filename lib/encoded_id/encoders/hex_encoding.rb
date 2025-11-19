# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Module providing hex encoding/decoding utilities for encoders.
    # Encoders including this module must implement #encode and #decode methods.
    module HexEncoding
      # @rbs!
      #   interface _Encoder
      #     def encode: (Array[Integer]) -> String
      #     def decode: (String) -> Array[Integer]
      #   end

      # Encode hexadecimal string(s) into a string
      # @rbs (String str) -> String
      def encode_hex(str)
        return "" unless hex_string?(str)

        numbers = str.scan(/[\w\W]{1,12}/).map do |num|
          "1#{num}".to_i(16)
        end

        encode(numbers)
      end

      # Decode a string back into an array of hexadecimal strings
      # @rbs (String hash) -> String
      def decode_hex(hash)
        numbers = decode(hash)
        return "" if numbers.empty?

        ret = numbers.map { _1.to_s(16)[1..] }

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
