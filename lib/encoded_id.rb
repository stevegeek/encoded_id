# frozen_string_literal: true

require_relative "encoded_id/version"
require_relative "encoded_id/alphabet"
require_relative "encoded_id/hex_representation"
require_relative "encoded_id/hash_id"
require_relative "encoded_id/reversible_id"

module EncodedId
  class InvalidConfigurationError < StandardError; end

  class InvalidAlphabetError < ArgumentError; end

  class EncodedIdFormatError < ArgumentError; end

  class EncodedIdLengthError < ArgumentError; end

  class InvalidInputError < ArgumentError; end
end
