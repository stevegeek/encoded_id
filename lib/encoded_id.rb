# frozen_string_literal: true

# rbs_inline: enabled

require_relative "encoded_id/version"
require_relative "encoded_id/alphabet"
require_relative "encoded_id/hex_representation"
require_relative "encoded_id/blocklist"

# Load the encoder framework
require_relative "encoded_id/encoders/base"
require_relative "encoded_id/encoders/hash_id_salt"
require_relative "encoded_id/encoders/hash_id_consistent_shuffle"
require_relative "encoded_id/encoders/hash_id_ordinal_alphabet_separator_guards"
require_relative "encoded_id/encoders/hash_id"

# Only load Sqids encoder if the gem is available
begin
  require "sqids"
  require_relative "encoded_id/encoders/my_sqids"
  require_relative "encoded_id/encoders/sqids"
rescue LoadError
  # Sqids gem not available, encoder will not be loaded
end

require_relative "encoded_id/reversible_id"

# @rbs!
#   class Integer
#     MAX: Integer
#   end
#
#   # Optional Sqids gem support
#   module Sqids
#     DEFAULT_BLOCKLIST: Array[String]
#   end

module EncodedId
  # @rbs InvalidConfigurationError: singleton(StandardError)
  class InvalidConfigurationError < StandardError; end

  # @rbs InvalidAlphabetError: singleton(ArgumentError)
  class InvalidAlphabetError < ArgumentError; end

  # @rbs EncodedIdFormatError: singleton(ArgumentError)
  class EncodedIdFormatError < ArgumentError; end

  # @rbs EncodedIdLengthError: singleton(ArgumentError)
  class EncodedIdLengthError < ArgumentError; end

  # @rbs InvalidInputError: singleton(ArgumentError)
  class InvalidInputError < ArgumentError; end

  # @rbs BlocklistError: singleton(StandardError)
  class BlocklistError < StandardError; end

  # @rbs SaltError: singleton(ArgumentError)
  class SaltError < ArgumentError; end
end
