# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Configuration for Hashids encoder
    # Hashids requires a salt for encoding/decoding
    class HashidConfiguration < BaseConfiguration
      attr_reader :salt #: String

      # @rbs (salt: String, **untyped options) -> void
      def initialize(salt:, **options)
        @salt = validate_salt(salt)
        super(**options)
      end

      # Create the Hashid encoder instance
      # @rbs () -> Hashid
      def create_encoder
        Hashid.new(salt, min_length, alphabet, blocklist, blocklist_mode, blocklist_max_length)
      end

      private

      # @rbs (String salt) -> String
      def validate_salt(salt)
        return salt if salt.is_a?(String) && salt.size > 3
        raise InvalidConfigurationError, "salt must be a string longer than 3 characters"
      end
    end
  end
end
