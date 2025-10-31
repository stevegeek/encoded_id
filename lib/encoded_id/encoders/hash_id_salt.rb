# frozen_string_literal: true
# rbs_inline: enabled

module EncodedId
  module Encoders
    class HashIdSalt
      # @rbs @salt: String
      # @rbs @chars: Array[String]

      # @rbs (String salt) -> void
      def initialize(salt)
        unless salt.is_a?(String)
          raise SaltError, "The salt must be a String"
        end
        @salt = salt.freeze
        @chars = salt.chars.freeze
      end

      attr_reader :salt #: String
      attr_reader :chars #: Array[String]
    end
  end
end
