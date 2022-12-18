# frozen_string_literal: true

module EncodedId
  module Rails
    class Coder
      def initialize(salt:, id_length:, character_group_size:, separator:, alphabet:)
        @salt = salt
        @id_length = id_length
        @character_group_size = character_group_size
        @separator = separator
        @alphabet = alphabet
      end

      def encode(id)
        coder.encode(id)
      end

      def decode(encoded_id)
        coder.decode(encoded_id)
      rescue EncodedId::EncodedIdFormatError
        nil
      end

      private

      def coder
        ::EncodedId::ReversibleId.new(
          salt: @salt,
          length: @id_length,
          split_at: @character_group_size,
          split_with: @separator,
          alphabet: @alphabet
        )
      end
    end
  end
end
