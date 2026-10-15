# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Configuration for Sqids encoder
    # Sqids does not use a salt - it shuffles the alphabet deterministically
    class SqidsConfiguration < BaseConfiguration
      # Create the Sqids encoder instance
      # @rbs () -> Sqids
      def create_encoder
        Sqids.new(min_length, alphabet, blocklist, blocklist_mode, blocklist_max_length)
      end

      private

      # @rbs (Alphabet alphabet) -> Alphabet
      def validate_alphabet(alphabet)
        validate_alphabet_size(super, Sqids::MIN_ALPHABET_SIZE)
      end
    end
  end
end
