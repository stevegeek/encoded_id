# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Base configuration class for encoder-specific settings
    # This provides common parameters shared across all encoders
    class BaseConfiguration
      # @rbs @min_length: Integer
      # @rbs @alphabet: Alphabet
      # @rbs @split_at: Integer?
      # @rbs @split_with: String?
      # @rbs @hex_digit_encoding_group_size: Integer
      # @rbs @max_length: Integer?
      # @rbs @max_inputs_per_id: Integer
      # @rbs @blocklist: Blocklist

      attr_reader :min_length, :alphabet, :split_at, :split_with,
                  :hex_digit_encoding_group_size, :max_length,
                  :max_inputs_per_id, :blocklist

      # @rbs (?min_length: Integer, ?alphabet: Alphabet, ?split_at: Integer?, ?split_with: String?, ?hex_digit_encoding_group_size: Integer, ?max_length: Integer?, ?max_inputs_per_id: Integer, ?blocklist: Blocklist | Array[String] | Set[String] | nil) -> void
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
        @min_length = validate_min_length(min_length)
        @alphabet = validate_alphabet(alphabet)
        @split_at = validate_split_at(split_at)
        @split_with = validate_split_with(split_with, @alphabet)
        @hex_digit_encoding_group_size = hex_digit_encoding_group_size
        @max_length = validate_max_length(max_length)
        @max_inputs_per_id = validate_max_inputs_per_id(max_inputs_per_id)
        @blocklist = validate_blocklist(blocklist)
      end

      # @rbs () -> Symbol
      def encoder_type
        raise NotImplementedError, "Subclasses must implement encoder_type"
      end

      # Create the encoder instance for this configuration
      # @rbs () -> untyped
      def create_encoder
        raise NotImplementedError, "Subclasses must implement create_encoder"
      end

      private

      # @rbs (Alphabet alphabet) -> Alphabet
      def validate_alphabet(alphabet)
        return alphabet if alphabet.is_a?(Alphabet)
        raise InvalidAlphabetError, "alphabet must be an instance of Alphabet"
      end

      # @rbs (Integer min_length) -> Integer
      def validate_min_length(min_length)
        return min_length if valid_integer_option?(min_length)
        raise InvalidConfigurationError, "min_length must be an integer greater than 0"
      end

      # @rbs (Integer? max_length) -> Integer?
      def validate_max_length(max_length)
        return max_length if valid_integer_option?(max_length) || max_length.nil?
        raise InvalidConfigurationError, "max_length must be an integer greater than 0 or nil"
      end

      # @rbs (Integer max_inputs_per_id) -> Integer
      def validate_max_inputs_per_id(max_inputs_per_id)
        return max_inputs_per_id if valid_integer_option?(max_inputs_per_id)
        raise InvalidConfigurationError, "max_inputs_per_id must be an integer greater than 0"
      end

      # @rbs (Integer? split_at) -> Integer?
      def validate_split_at(split_at)
        return split_at if valid_integer_option?(split_at) || split_at.nil?
        raise InvalidConfigurationError, "split_at must be an integer greater than 0 or nil"
      end

      # @rbs (String? split_with, Alphabet alphabet) -> String?
      def validate_split_with(split_with, alphabet)
        return split_with if split_with.nil? || (split_with.is_a?(String) && !alphabet.characters.include?(split_with))
        raise InvalidConfigurationError, "split_with must be a string not part of the alphabet, or nil"
      end

      # @rbs (Integer? value) -> bool
      def valid_integer_option?(value)
        value.is_a?(Integer) && value > 0
      end

      # @rbs (Blocklist | Array[String] | Set[String] | nil blocklist) -> Blocklist
      def validate_blocklist(blocklist)
        return blocklist if blocklist.is_a?(Blocklist)
        return Blocklist.empty if blocklist.nil?
        return Blocklist.new(blocklist) if blocklist.is_a?(Array) || blocklist.is_a?(Set)

        raise InvalidConfigurationError, "blocklist must be a Blocklist, Set, or Array of strings"
      end
    end
  end
end
