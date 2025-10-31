# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    class Coder
      # @rbs @salt: String
      # @rbs @id_length: Integer
      # @rbs @character_group_size: Integer
      # @rbs @separator: String
      # @rbs @alphabet: ::EncodedId::Alphabet
      # @rbs @encoder: (Symbol | ::EncodedId::Encoders::Base)
      # @rbs @blocklist: ::EncodedId::Blocklist?

      # @rbs (salt: String, id_length: Integer, character_group_size: Integer, separator: String, alphabet: ::EncodedId::Alphabet, ?encoder: Symbol?, ?blocklist: ::EncodedId::Blocklist?) -> void
      def initialize(salt:, id_length:, character_group_size:, separator:, alphabet:, encoder: nil, blocklist: nil)
        @salt = salt
        @id_length = id_length
        @character_group_size = character_group_size
        @separator = separator
        @alphabet = alphabet
        @encoder = encoder || EncodedId::Rails.configuration.encoder
        @blocklist = blocklist || EncodedId::Rails.configuration.blocklist
      end

      # @rbs (Integer | Array[Integer] id) -> String
      def encode(id)
        coder.encode(id)
      end

      # @rbs (String encoded_id) -> Array[Integer]?
      def decode(encoded_id)
        coder.decode(encoded_id)
      rescue EncodedId::EncodedIdFormatError, EncodedId::InvalidInputError
        nil
      end

      private

      # @rbs return: ::EncodedId::ReversibleId
      def coder
        ::EncodedId::ReversibleId.new(
          salt: @salt,
          length: @id_length,
          split_at: @character_group_size,
          split_with: @separator,
          alphabet: @alphabet,
          encoder: @encoder,
          blocklist: @blocklist
        )
      end
    end
  end
end
