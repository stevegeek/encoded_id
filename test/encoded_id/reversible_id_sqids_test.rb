# frozen_string_literal: true

require "test_helper"

class ReversibleIdSqidsTest < Minitest::Test
  def test_it_uses_sqids_encoder_when_specified
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids).encode(id)
    assert_equal [id], ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids).decode(coded)
  end

  def test_it_encodes_differently_with_sqids_vs_hashids
    id = 123
    hashids_coded = ::EncodedId::ReversibleId.new(salt: salt, encoder: :hashids).encode(id)
    sqids_coded = ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids).encode(id)
    refute_equal hashids_coded, sqids_coded
  end

  def test_it_raises_for_invalid_decode_with_sqids
    coded = "ozgf-w$65"
    assert_raises(::EncodedId::EncodedIdFormatError) do
      ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids).decode(coded)
    end
  end

  def test_it_encodes_and_decodes_hexadecimal_with_sqids
    id = "deadbeef"
    coder = ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids)
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal decoded, [id]
  end

  def test_it_supports_custom_separators_with_sqids
    id = 8563432
    coder = ::EncodedId::ReversibleId.new(
      salt: salt,
      alphabet: ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", {"_" => "-"}),
      split_with: "F",
      encoder: :sqids
    )
    coded = coder.encode(id)
    id_val = coder.decode(coded)
    assert_equal [id], id_val
  end

  def test_it_handles_multiple_ids_with_sqids
    ids = [123, 456, 789]
    coder = ::EncodedId::ReversibleId.new(salt: salt, encoder: :sqids)
    coded = coder.encode(ids)
    assert_equal ids, coder.decode(coded)
  end

  def test_it_raises_with_invalid_encoder
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, encoder: :invalid)
    end
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
