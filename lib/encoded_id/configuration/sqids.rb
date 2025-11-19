# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Configuration
    # Configuration for Sqids encoder
    # Sqids does not use a salt - it shuffles the alphabet deterministically
    class Sqids < Base
      # @rbs () -> Symbol
      def encoder_type
        :sqids
      end

      # Create the Sqids encoder instance
      # @rbs () -> Encoders::Sqids
      def create_encoder
        Encoders::Sqids.new(min_length, alphabet, blocklist)
      end
    end
  end
end
