# frozen_string_literal: true

require "test_helper"

class EncodedId::Encoders::SqidsTest < Minitest::Test
  def test_it_encodes_an_integer_id
    id = 123
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    coded = encoder.encode([id])
    assert_equal coded, "37vq3u7t"
    refute_nil coded
    assert_equal [id], encoder.decode(coded)
  end

  def test_it_encodes_multiple_ids
    ids = [123, 456, 789]
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    coded = encoder.encode(ids)
    assert_equal coded, "qa1u2mqvb"
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

  def test_it_handles_invalid_decode
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    # For invalid characters, Sqids returns an empty array
    assert_equal [], encoder.decode("$%&*")
  end

  def test_it_raises_invalid_input_error_on_alphabet_with_multibyte_chars
    # Create alphabet with 16+ characters including multibyte chars
    multibyte_alphabet = "abcdefghijklmnop😀😁"
    error = assert_raises(::EncodedId::InvalidInputError) do
      ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.new(multibyte_alphabet))
    end
    assert_match(/unable to create sqids instance/, error.message)
    assert_match(/Alphabet cannot contain multibyte characters/, error.message)
  end

  def test_it_raises_invalid_input_error_on_invalid_min_length
    error = assert_raises(::EncodedId::InvalidInputError) do
      ::EncodedId::Encoders::Sqids.new(salt, 300, ::EncodedId::Alphabet.modified_crockford)
    end
    assert_match(/unable to create sqids instance/, error.message)
    assert_match(/Minimum length has to be between 0 and 255/, error.message)
  end

  def test_it_raises_invalid_input_error_on_negative_min_length
    error = assert_raises(::EncodedId::InvalidInputError) do
      ::EncodedId::Encoders::Sqids.new(salt, -1, ::EncodedId::Alphabet.modified_crockford)
    end
    assert_match(/unable to create sqids instance/, error.message)
    assert_match(/Minimum length has to be between 0 and 255/, error.message)
  end

  def test_it_raises_invalid_input_error_on_decode_internal_error
    encoder = ::EncodedId::Encoders::Sqids.new(salt, 8, ::EncodedId::Alphabet.modified_crockford)
    # Mock the internal @sqids object to raise an error during decode
    encoder.instance_variable_get(:@sqids).define_singleton_method(:decode) do |_|
      raise "simulated internal error"
    end

    error = assert_raises(::EncodedId::InvalidInputError) do
      encoder.decode("test")
    end
    assert_match(/unable to unhash/, error.message)
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
