# frozen_string_literal: true

require "test_helper"

class SqidsTest < Minitest::Test
  def test_it_encodes_an_integer_id
    id = 123
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    coded = encoder.encode([id])
    refute_nil coded
    assert_equal [id], encoder.decode(coded)
  end

  def test_it_encodes_multiple_ids
    ids = [123, 456, 789]
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    coded = encoder.encode(ids)
    refute_nil coded
    assert_equal ids, encoder.decode(coded)
  end

  def test_it_handles_custom_alphabet
    id = 123
    alphabet = ::EncodedId::Alphabet.new("0123456789abcdef")
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, alphabet)
    coded = encoder.encode([id])
    refute_nil coded
    assert_equal [id], encoder.decode(coded)
  end

  def test_it_encodes_and_decodes_hex
    hex = "deadbeef"
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    coded = encoder.encode_hex(hex)
    refute_nil coded
    decoded = encoder.decode_hex(coded)
    assert decoded.include?(hex.upcase)
  end

  def test_it_handles_empty_input
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    assert_equal "", encoder.encode([])
    assert_equal "", encoder.encode_hex("")
    assert_equal [], encoder.decode("")
    assert_equal "", encoder.decode_hex("")
  end

  def test_it_handles_negative_numbers
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    assert_equal "", encoder.encode([-1])
  end

  def test_it_raises_with_invalid_decode
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    assert_raises(::EncodedId::InvalidInputError) do
      encoder.decode("$%&*")
    end
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
