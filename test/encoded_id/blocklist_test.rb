# frozen_string_literal: true

require "test_helper"

class BlocklistTest < Minitest::Test
  def setup
    @salt = "test_salt_12345"
    # "123" will be blocklisted for both encoders.
    @blocklist_words = Set.new(["mxyj", "85m3", "ugly", "profane"])
  end

  def check_valid_and_invalid(encoder)
    encoded = encoder.encode(124)
    refute_nil encoded
    refute_empty encoded

    assert_raises(::EncodedId::InvalidInputError) do
      encoder.encode(123)
    end
  end

  def test_hashids_encoder_raises_error_for_blocklisted_words
    # Create a ReversibleId with a blocklist and hashids encoder
    encoder = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :hashids,
      blocklist: @blocklist_words
    )

    check_valid_and_invalid(encoder)
  end

  def test_blocklist_accepts_array_input
    encoder = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :hashids,
      blocklist: @blocklist_words.to_a
    )

    check_valid_and_invalid(encoder)
  end

  def test_blocklist_raises_error_with_invalid_input
    assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::ReversibleId.new(
        salt: @salt,
        encoder: :hashids,
        blocklist: "bad string input"
      )
    end
  end

  def test_sqids_encoder_respects_blocklist
    encoder = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :sqids,
      blocklist: @blocklist_words
    )

    # Sqids generate new ID on blocklist (id with "85m3" is blocked)
    encoded = encoder.encode(123)
    assert_equal "37vq-3u7t", encoded

    encoded = encoder.encode(124)
    refute_nil encoded
    refute_empty encoded
  end
end
