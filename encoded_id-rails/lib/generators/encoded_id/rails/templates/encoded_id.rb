# frozen_string_literal: true

EncodedId::Rails.configure do |config|
  # The salt is used in the Hashids algorithm to generate the encoded ID. It ensures that the same ID will result in
  # a different encoded ID. You must configure one and it must be longer that 4 characters. It can be configured on a
  # model by model basis too.
  #
  # config.salt = "<%= SecureRandom.hex(24) %>"

  # The number of characters of the encoded ID that are grouped before the hyphen separator is inserted.
  # `nil` disables grouping.
  #
  # nil -> abcdefghijklmnop
  # 4   -> abcd-efgh-ijkl-mnop
  # 8   -> abcdefgh-ijklmnop
  #
  # Default: 4
  #
  # config.character_group_size = 4

  # The separator used between character groups in the encoded ID.
  # `nil` disables grouping.
  #
  # Default: "-"
  #
  # config.group_separator = "-"

  # The characters allowed in the encoded ID.
  # Note, hash ids requires at least 16 unique alphabet characters.
  #
  # Default: a reduced character set Crockford alphabet and split groups, see https://www.crockford.com/wrmg/base32.html
  #
  # config.alphabet = ::EncodedId::Alphabet.new("0123456789abcdef")

  # The minimum length of the encoded ID. Note that this is not a hard limit, the actual length may be longer as hash IDs
  # may expand the length as needed to encode the full input. However encoded IDs will never be shorter than this.
  #
  # 4 -> "abcd"
  # 8 -> "abcd-efgh" (with character_group_size = 4)
  #
  # Default: 8
  #
  # config.id_length = 8
end
