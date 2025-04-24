# frozen_string_literal: true

require_relative "test_helper"

class AlphabetTest < Minitest::Test
  def test_encodes_and_decodes_using_simple_alphabet
    sqids = Sqids.new(alphabet: "0123456789abcdef")
    my_sqids = MySqids.new(alphabet: "0123456789abcdef")

    numbers = [1, 2, 3]
    id = "489158"

    assert_equal id, sqids.encode(numbers)
    assert_equal numbers, sqids.decode(id)

    assert_equal id, my_sqids.encode(numbers)
    assert_equal numbers, my_sqids.decode(id)
  end

  def test_decodes_after_encoding_with_short_alphabet
    sqids = Sqids.new(alphabet: "abc")
    my_sqids = MySqids.new(alphabet: "abc")

    numbers = [1, 2, 3]

    encoded_sqids = sqids.encode(numbers)
    encoded_my_sqids = my_sqids.encode(numbers)

    assert_equal numbers, sqids.decode(encoded_sqids)
    assert_equal numbers, my_sqids.decode(encoded_my_sqids)
  end

  def test_decodes_after_encoding_with_long_alphabet
    long_alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:'\"/?.>,<`~"

    sqids = Sqids.new(alphabet: long_alphabet)
    my_sqids = MySqids.new(alphabet: long_alphabet)

    numbers = [1, 2, 3]

    encoded_sqids = sqids.encode(numbers)
    encoded_my_sqids = my_sqids.encode(numbers)

    assert_equal numbers, sqids.decode(encoded_sqids)
    assert_equal numbers, my_sqids.decode(encoded_my_sqids)
  end

  def test_fails_when_alphabet_has_multibyte_characters
    assert_raises(ArgumentError) do
      Sqids.new(alphabet: "ë1092")
    end

    assert_raises(ArgumentError) do
      MySqids.new(alphabet: "ë1092")
    end
  end

  def test_fails_when_alphabet_characters_are_repeated
    assert_raises(ArgumentError) do
      Sqids.new(alphabet: "aabcdefg")
    end

    assert_raises(ArgumentError) do
      MySqids.new(alphabet: "aabcdefg")
    end
  end

  def test_fails_when_alphabet_is_too_short
    assert_raises(ArgumentError) do
      Sqids.new(alphabet: "ab")
    end

    assert_raises(ArgumentError) do
      MySqids.new(alphabet: "ab")
    end
  end
end
