# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Configuration class for initializer
    class Configuration
      # @rbs @salt: String
      # @rbs @character_group_size: Integer
      # @rbs @alphabet: ::EncodedId::Alphabet
      # @rbs @id_length: Integer
      # @rbs @slug_value_method_name: Symbol
      # @rbs @annotation_method_name: Symbol
      # @rbs @model_to_param_returns_encoded_id: bool
      # @rbs @blocklist: ::EncodedId::Blocklist
      # @rbs @group_separator: String
      # @rbs @slugged_id_separator: String
      # @rbs @annotated_id_separator: String
      # @rbs @encoder: Symbol

      attr_accessor :salt #: String
      attr_accessor :character_group_size #: Integer
      attr_accessor :alphabet #: ::EncodedId::Alphabet
      attr_accessor :id_length #: Integer
      attr_accessor :slug_value_method_name #: Symbol
      attr_accessor :annotation_method_name #: Symbol
      attr_accessor :model_to_param_returns_encoded_id #: bool
      attr_accessor :blocklist #: ::EncodedId::Blocklist
      attr_reader :group_separator #: String
      attr_reader :slugged_id_separator #: String
      attr_reader :annotated_id_separator #: String
      attr_reader :encoder #: Symbol

      # @rbs () -> void
      def initialize
        @character_group_size = 4
        @group_separator = "-"
        @alphabet = ::EncodedId::Alphabet.modified_crockford
        @id_length = 8
        @slug_value_method_name = :name_for_encoded_id_slug
        @slugged_id_separator = "--"
        @annotation_method_name = :annotation_for_encoded_id
        @annotated_id_separator = "_"
        @model_to_param_returns_encoded_id = false
        @encoder = :hashids
        @blocklist = ::EncodedId::Blocklist.empty
      end

      # @rbs (Symbol value) -> Symbol
      def encoder=(value)
        unless ::EncodedId::ReversibleId::VALID_ENCODERS.include?(value)
          raise ArgumentError, "Encoder must be one of: #{::EncodedId::ReversibleId::VALID_ENCODERS.join(", ")}"
        end
        @encoder = value
      end

      # Perform validation vs alphabet on these assignments

      # @rbs (String value) -> String
      def group_separator=(value)
        unless valid_separator?(value, alphabet)
          raise ArgumentError, "Group separator characters must not be part of the alphabet"
        end
        @group_separator = value
      end

      # @rbs (String value) -> String
      def slugged_id_separator=(value)
        if value.blank? || value == group_separator || !valid_separator?(value, alphabet)
          raise ArgumentError, "Slugged ID separator characters must not be part of the alphabet or the same as the group separator"
        end
        @slugged_id_separator = value
      end

      # @rbs (String value) -> String
      def annotated_id_separator=(value)
        if value.blank? || value == group_separator || !valid_separator?(value, alphabet)
          raise ArgumentError, "Annotated ID separator characters must not be part of the alphabet or the same as the group separator"
        end
        @annotated_id_separator = value
      end

      private

      # @rbs (String separator, ::EncodedId::Alphabet characters) -> bool
      def valid_separator?(separator, characters)
        separator.chars.none? { |v| characters.include?(v) }
      end
    end
  end
end
