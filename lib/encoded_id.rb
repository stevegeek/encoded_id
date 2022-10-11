# frozen_string_literal: true

require_relative "encoded_id/version"
require_relative "encoded_id/reversible_id"

module EncodedId
  class EncodedIdFormatError < Hashids::InputError; end
  class InvalidAlphabetError < Hashids::AlphabetError; end
end
