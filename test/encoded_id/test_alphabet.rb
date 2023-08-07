# frozen_string_literal: true

require "test_helper"

class TestAlphabet < Minitest::Test
  def test_initialize_with_valid_alphabet_string
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.characters
    assert_nil alphabet.equivalences
  end

  def test_initialize_with_alphabet_string_with_dupes
    alphabet = EncodedId::Alphabet.new("abcccccdefghijklmnopqrstuvwxyz0123456789")
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.characters
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789".chars, alphabet.unique_characters
  end

  def test_include?
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert alphabet.include?("a")
    assert alphabet.include?("0")
    refute alphabet.include?("A")
    refute alphabet.include?("!")
  end

  def test_initialize_with_valid_alphabet_array
    alphabet = EncodedId::Alphabet.new(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.characters
    assert_nil alphabet.equivalences
  end

  def test_initialize_with_invalid_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abc")
    end
  end

  def test_initialize_with_valid_equivalences
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789", {"*" => "a"})
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.characters
    assert_equal({"*" => "a"}, alphabet.equivalences)
  end

  def test_initialize_with_invalid_equivalences
    assert_raises EncodedId::InvalidConfigurationError do
      EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789", {"a" => "*"})
    end
  end

  def test_modified_crockford
    alphabet = EncodedId::Alphabet.modified_crockford
    assert_equal "0123456789abcdefghjkmnpqrstuvwxyz", alphabet.characters
    assert_equal({"o" => "0", "i" => "j", "l" => "1"}, alphabet.equivalences)
  end
end
