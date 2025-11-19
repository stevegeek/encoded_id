# frozen_string_literal: true

# rbs_inline: enabled

require_relative "encoded_id/version"
require_relative "encoded_id/alphabet"
require_relative "encoded_id/hex_representation"
require_relative "encoded_id/blocklist"

# Load the encoder framework
require_relative "encoded_id/encoders/hex_encoding"
require_relative "encoded_id/encoders/hashid_salt"
require_relative "encoded_id/encoders/hashid_consistent_shuffle"
require_relative "encoded_id/encoders/hashid_ordinal_alphabet_separator_guards"
require_relative "encoded_id/encoders/hashid"

require "sqids"
# TODO: move back to only using gem once upstreamed our changes
require_relative "encoded_id/encoders/my_sqids"

require_relative "encoded_id/encoders/sqids"

# Load configuration classes
require_relative "encoded_id/configuration/base"
require_relative "encoded_id/configuration/hashid"
require_relative "encoded_id/configuration/sqids"

require_relative "encoded_id/reversible_id"

# @rbs!
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
