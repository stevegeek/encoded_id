# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Configuration
    # Configuration for SQIDs encoder
    # SQIDs does not use a salt - it shuffles the alphabet deterministically
    class Sqids < Base
      # @rbs (min_length: Integer, alphabet: Alphabet, split_at: Integer?, split_with: String?, hex_digit_encoding_group_size: Integer, max_length: Integer?, max_inputs_per_id: Integer, blocklist: Blocklist | Array[String] | Set[String] | nil) -> void
      def initialize(
        min_length: 8,
        alphabet: Alphabet.modified_crockford,
        split_at: 4,
        split_with: "-",
        hex_digit_encoding_group_size: 4,
        max_length: 128,
        max_inputs_per_id: 32,
        blocklist: Blocklist.empty
      )
        super(
          min_length: min_length,
          alphabet: alphabet,
          split_at: split_at,
          split_with: split_with,
          hex_digit_encoding_group_size: hex_digit_encoding_group_size,
          max_length: max_length,
          max_inputs_per_id: max_inputs_per_id,
          blocklist: blocklist
        )
      end

      # @rbs () -> Symbol
      def encoder_type
        :sqids
      end
    end
  end
end
