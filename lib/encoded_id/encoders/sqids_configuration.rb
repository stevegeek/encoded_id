# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Configuration for Sqids encoder
    # Sqids does not use a salt - it shuffles the alphabet deterministically
    class SqidsConfiguration < BaseConfiguration
      # @rbs () -> Symbol
      def encoder_type
        :sqids
      end

      # Create the Sqids encoder instance
      # @rbs () -> Sqids
      def create_encoder
        Sqids.new(min_length, alphabet, blocklist)
      end
    end
  end
end
