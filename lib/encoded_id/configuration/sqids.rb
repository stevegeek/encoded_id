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
    end
  end
end
