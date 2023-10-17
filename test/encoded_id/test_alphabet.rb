# frozen_string_literal: true

require "test_helper"
require "base64"

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

  def test_alphabet_case_sensitive
    alphabet = EncodedId::Alphabet.new("Abcdefghijklmnopqrstuvwxyz0123456789")
    refute alphabet.include?("a")
    assert alphabet.include?("A")
  end

  def test_initialize_with_valid_alphabet_array
    alphabet = EncodedId::Alphabet.new(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.characters
    assert_nil alphabet.equivalences
  end

  def test_it_allows_non_ascii_chars
    alphabet = EncodedId::Alphabet.new("9$�+OmlϏ횲_F123456789")
    assert_equal ["9", "$", "�", "+", "O", "m", "l", "Ϗ", "횲", "_", "F", "1", "2", "3", "4", "5", "6", "7", "8"], alphabet.unique_characters
  end

  def test_initialize_with_invalid_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abc")
    end
  end

  def test_initialize_with_nil_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new(nil)
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

  def test_invalid_equivalence_due_to_size_of_mapped_to
    assert_raises EncodedId::InvalidConfigurationError do
      EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789", {"*" => "aa"})
    end
  end

  def test_invalid_equivalence_due_to_size_of_mapped_from
    assert_raises EncodedId::InvalidConfigurationError do
      EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789", {"**" => "a"})
    end
  end

  def test_it_raises_with_small_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Alphabet.new("1234")
    end
  end

  # hashids can blow up if a resulting hashed value is the string "\0" as it uses #ord of that to the do a division
  # (and "\0".ord == 0)
  def test_it_raises_with_null_char_in_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abcdefghijklmnopqr\0stuvwxyz0123456789")
    end
  end

  # Spaces are not allowed in hashids, but we also restrict other whitespace characters
  def test_it_raises_with_spaces_in_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abcdefghijklmnopqr stuvwxyz0123456789")
    end
  end

  def test_it_raises_with_spaces_in_alphabet_with_non_printable_chars
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new(Base64.strict_decode64("OSTvv70r77+9T++/ve+/vW3vv73vv73vv70577+977+977+977+9K++/vWwkbe+/ve+/ve+/vc+P77+97ZqyK++/vTnvv71fRu+/vUZG77+9Rk9G77+9RjEyMzQ1NiA3ODk="))
    end
  end

  def test_it_raises_with_spaces_in_array_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abcdefghijklmnopqr stuvwxyz0123456789".chars)
    end
  end

  def test_it_raises_with_newline_in_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abcdefghijklmnopqr\nstuvwxyz0123456789")
    end
  end

  def test_it_raises_with_tab_in_alphabet
    assert_raises EncodedId::InvalidAlphabetError do
      EncodedId::Alphabet.new("abcdefghijklmnopqr\tstuvwxyz0123456789")
    end
  end

  def test_it_raises_with_not_enough_unique_chars_in_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Alphabet.new("1234567890abcdff")
    end
  end

  def test_raises_on_invalid_character_equivalences
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", "foo")
    end
  end

  def test_raises_on_character_equivalences_that_map_to_nonexistent_characters
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::Alphabet.new("0123456789abcdefgh", {"o" => "z"})
    end
  end

  def test_raises_on_character_equivalences_that_map_alphabet_characters
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::Alphabet.new("0123456789abcdefgh", {"a" => "e"})
    end
  end

  def test_modified_crockford
    alphabet = EncodedId::Alphabet.modified_crockford
    assert_equal "0123456789abcdefghjkmnpqrstuvwxyz", alphabet.characters
    assert_equal({"o" => "0", "i" => "j", "l" => "1"}, alphabet.equivalences)
  end

  def test_size
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert_equal 36, alphabet.size
    assert_equal 36, alphabet.length
  end

  def test_to_s
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789", alphabet.to_s
  end

  def test_to_a
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert_equal "abcdefghijklmnopqrstuvwxyz0123456789".chars, alphabet.to_a
  end

  def test_inspect
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")
    assert_equal "#<EncodedId::Alphabet chars: [\"a\", \"b\", \"c\", \"d\", \"e\", \"f\", \"g\", \"h\", \"i\", \"j\", \"k\", \"l\", \"m\", \"n\", \"o\", \"p\", \"q\", \"r\", \"s\", \"t\", \"u\", \"v\", \"w\", \"x\", \"y\", \"z\", \"0\", \"1\", \"2\", \"3\", \"4\", \"5\", \"6\", \"7\", \"8\", \"9\"]>", alphabet.inspect
  end
end
