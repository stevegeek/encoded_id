# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Encodes and decodes IDs using the configured encoder and settings.
    class Coder
      # @rbs @salt: String?
      # @rbs @id_length: Integer
      # @rbs @character_group_size: Integer
      # @rbs @separator: String
      # @rbs @alphabet: ::EncodedId::Alphabet
      # @rbs @encoder: Symbol
      # @rbs @blocklist: ::EncodedId::Blocklist?
      # @rbs @blocklist_mode: Symbol
      # @rbs @blocklist_max_length: Integer
      # @rbs @downcase_on_decode: bool

      # @rbs (salt: String?, id_length: Integer, character_group_size: Integer, separator: String, alphabet: ::EncodedId::Alphabet, ?encoder: Symbol?, ?blocklist: ::EncodedId::Blocklist?, ?blocklist_mode: Symbol?, ?blocklist_max_length: Integer?, ?downcase_on_decode: bool?) -> void
      def initialize(salt:, id_length:, character_group_size:, separator:, alphabet:, encoder: nil, blocklist: nil, blocklist_mode: nil, blocklist_max_length: nil, downcase_on_decode: nil)
        @salt = salt
        @id_length = id_length
        @character_group_size = character_group_size
        @separator = separator
        @alphabet = alphabet
        config = EncodedId::Rails.configuration
        @encoder = encoder || config.encoder
        @blocklist = blocklist || config.blocklist
        @blocklist_mode = blocklist_mode || config.blocklist_mode
        @blocklist_max_length = blocklist_max_length || config.blocklist_max_length
        @downcase_on_decode = downcase_on_decode.nil? ? config.downcase_on_decode : downcase_on_decode
      end

      # @rbs (Integer | Array[Integer] id) -> String
      def encode(id)
        coder.encode(id)
      end

      # @rbs (String encoded_id) -> Array[Integer]
      def decode(encoded_id)
        coder.decode(encoded_id, downcase: @downcase_on_decode)
      rescue EncodedId::EncodedIdFormatError, EncodedId::InvalidInputError
        []
      end

      private

      # @rbs return: ::EncodedId::ReversibleId
      def coder
        # Build the appropriate configuration based on encoder type
        config = case @encoder
        when :hashids
          ::EncodedId::Encoders::HashidConfiguration.new(
            salt: @salt || raise(ArgumentError, "Salt is required for hashids encoder"),
            min_length: @id_length,
            split_at: @character_group_size,
            split_with: @separator,
            alphabet: @alphabet,
            blocklist: @blocklist,
            blocklist_mode: @blocklist_mode,
            blocklist_max_length: @blocklist_max_length
          )
        when :sqids
          ::EncodedId::Encoders::SqidsConfiguration.new(
            min_length: @id_length,
            split_at: @character_group_size,
            split_with: @separator,
            alphabet: @alphabet,
            blocklist: @blocklist,
            blocklist_mode: @blocklist_mode,
            blocklist_max_length: @blocklist_max_length
          )
        else
          raise ArgumentError, "Unknown encoder type: #{@encoder}"
        end

        ::EncodedId::ReversibleId.new(config)
      end
    end
  end
end
