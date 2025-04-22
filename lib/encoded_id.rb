# frozen_string_literal: true

require_relative "encoded_id/version"
require_relative "encoded_id/alphabet"
require_relative "encoded_id/hex_representation"

# Load the encoder framework
require_relative "encoded_id/encoders/base"
require_relative "encoded_id/encoders/hash_id_salt"
require_relative "encoded_id/encoders/hash_id_consistent_shuffle"
require_relative "encoded_id/encoders/hash_id_ordinal_alphabet_separator_guards"
require_relative "encoded_id/encoders/hash_id"

# Only load Sqids encoder if the gem is available
begin
  require "sqids"
  require_relative "encoded_id/encoders/sqids"
rescue LoadError
  # Sqids gem not available, encoder will not be loaded
end

require_relative "encoded_id/reversible_id"

module EncodedId
  class InvalidConfigurationError < StandardError; end

  class InvalidAlphabetError < ArgumentError; end

  class EncodedIdFormatError < ArgumentError; end

  class EncodedIdLengthError < ArgumentError; end

  class InvalidInputError < ArgumentError; end

  class SaltError < ArgumentError; end
end
