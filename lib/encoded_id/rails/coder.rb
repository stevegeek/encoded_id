# frozen_string_literal: true

module EncodedId
  module Rails
    class Coder
      def initialize(salt:, id_length:, character_group_size:, separator:, alphabet:, encoder: nil, blocklist: nil)
        @salt = salt
        @id_length = id_length
        @character_group_size = character_group_size
        @separator = separator
        @alphabet = alphabet
        @encoder = encoder || EncodedId::Rails.configuration.encoder
        @blocklist = blocklist || EncodedId::Rails.configuration.blocklist
      end

      def encode(id)
        coder.encode(id)
      end

      def decode(encoded_id)
        coder.decode(encoded_id)
      rescue EncodedId::EncodedIdFormatError, EncodedId::InvalidInputError
        nil
      end

      private

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
