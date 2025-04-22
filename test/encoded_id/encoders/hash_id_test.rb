# frozen_string_literal: true

require "test_helper"

class HashIdTest < Minitest::Test
  def setup
    @salt = ::EncodedId::Encoders::HashIdSalt.new("this is my salt")
    @hashids = ::EncodedId::Encoders::HashId.new(@salt)
    @default_seps = "cfhistuCFHISTU".chars.map(&:ord)
    @default_alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".chars.map(&:ord)
  end

  def test_has_default_separators
    assert_equal ::EncodedId::Encoders::HashIdOrdinalAlphabetSeparatorGuards::DEFAULT_SEPS, @default_seps
  end

  def test_defaults_to_a_min_length_of_0
    assert_equal 0, @hashids.instance_variable_get(:@min_hash_length)
  end

  def test_invalid_min_length_of_minus_raises_error
    assert_raises ::ArgumentError do
      ::EncodedId::Encoders::HashId.new(@salt, -1)
    end
  end

  def test_has_a_minimum_alphabet_length
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Encoders::HashId.new(@salt, 0, ::EncodedId::Alphabet.new("shortalphabet"))
    end
  end

  def test_has_a_final_alphabet_length_that_can_be_shorter_than_the_minimum
    assert_equal ["1", "0"], ::EncodedId::Encoders::HashId.new(::EncodedId::Encoders::HashIdSalt.new("this is my salt"), 0, EncodedId::Alphabet.new("cfhistuCFHISTU01")).alphabet_ordinals.map(&:chr)
  end

  def test_checks_the_alphabet_for_spaces
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Encoders::HashId.new(@salt, 0, ::EncodedId::Alphabet.new("abc odefghijklmnopqrstuv"))
    end
  end

  def test_encode_single_number
    assert_equal "NkK9", @hashids.encode([12345])

    assert_equal "", @hashids.encode([-1])
    assert_equal "NV", @hashids.encode([1])
    assert_equal "K4", @hashids.encode([22])
    assert_equal "OqM", @hashids.encode([333])
    assert_equal "kQVg", @hashids.encode([9999])
    assert_equal "58LzD", @hashids.encode([123_000])
    assert_equal "5gn6mQP", @hashids.encode([456_000_000])
    assert_equal "oyjYvry", @hashids.encode([987_654_321])
  end

  def test_encode_list_of_numbers
    assert_equal "laHquq", @hashids.encode([1, 2, 3])
    assert_equal "44uotN", @hashids.encode([2, 4, 6])
    assert_equal "97Jun", @hashids.encode([99, 25])
    assert_equal "7xKhrUxm", @hashids.encode([1337, 42, 314])
    assert_equal "aBMswoO2UB3Sj", @hashids.encode([683, 94108, 123, 5])
    assert_equal "3RoSDhelEyhxRsyWpCx5t1ZK", @hashids.encode([547, 31, 241271, 311, 31397, 1129, 71129])
    assert_equal "p2xkL3CK33JjcrrZ8vsw4YRZueZX9k", @hashids.encode([21979508, 35563591, 57543099, 93106690, 150649789])
  end

  def test_encode_list_of_numbers_passed_in_as_array
    assert_equal "laHquq", @hashids.encode([1, 2, 3])
  end

  def test_encode_raises_if_not_an_intger
    assert_raises ArgumentError do
      @hashids.encode(["1"])
    end
  end

  def test_encode_returns_empty_string_if_no_numbers
    assert_equal "", @hashids.encode([])
  end

  def test_encode_returns_empty_string_if_any_of_the_numbers_are_negative
    assert_equal "", @hashids.encode([-1])
    assert_equal "", @hashids.encode([10, -10])
  end

  def test_encode_can_encode_to_a_minimum_length
    h = ::EncodedId::Encoders::HashId.new(@salt, 18)
    assert_equal "aJEDngB0NV05ev1WwP", h.encode([1])
    assert_equal "pLMlCWnJSXr1BSpKgqUwbJ7oimr7l6", h.encode([4140, 21147, 115975, 678570, 4213597, 27644437])
  end

  def test_encode_can_encode_with_a_custom_alphabet
    h = ::EncodedId::Encoders::HashId.new(@salt, 0, ::EncodedId::Alphabet.new("ABCDEFGhijklmn34567890-:"))
    assert_equal "6nhmFDikA0", h.encode([1, 2, 3, 4, 5])
    assert_equal [1, 2, 3, 4, 5], h.decode("6nhmFDikA0")
  end

  def test_encode_does_not_produce_repeating_patterns_for_identical_numbers
    assert_equal "1Wc8cwcE", @hashids.encode([5, 5, 5, 5])
  end

  def test_encode_does_not_produce_repeating_patterns_for_incremented_numbers
    assert_equal "kRHnurhptKcjIDTWC3sx", @hashids.encode((1..10).to_a)
  end

  def test_encode_does_not_produce_similarities_between_incrementing_number_hashes
    assert_equal "NV", @hashids.encode([1])
    assert_equal "6m", @hashids.encode([2])
    assert_equal "yD", @hashids.encode([3])
    assert_equal "2l", @hashids.encode([4])
    assert_equal "rD", @hashids.encode([5])
  end

  def test_encode_hex_encodes_hex_string
    assert_equal "lzY", @hashids.encode_hex("FA")
    assert_equal "MemE", @hashids.encode_hex("26dd")
    assert_equal "eBMrb", @hashids.encode_hex("FF1A")
    assert_equal "D9NPE", @hashids.encode_hex("12abC")
    assert_equal "9OyNW", @hashids.encode_hex("185b0")
    assert_equal "MRWNE", @hashids.encode_hex("17b8d")
    assert_equal "4o6Z7KqxE", @hashids.encode_hex("1d7f21dd38")
    assert_equal "ooweQVNB", @hashids.encode_hex("20015111d")
  end

  def test_encode_hex_returns_empty_string_if_passed_non_hex_string
    assert_equal "", @hashids.encode_hex("XYZ123")
  end

  def test_decode_decodes_an_encoded_number
    assert_equal [12345], @hashids.decode("NkK9")
    assert_equal [666555444], @hashids.decode("5O8yp5P")
    assert_equal [666555444333222], @hashids.decode("KVO9yy1oO5j")

    assert_equal [1337], @hashids.decode("Wzo")
    assert_equal [808], @hashids.decode("DbE")
    assert_equal [303], @hashids.decode("yj8")
  end

  def test_decode_decodes_a_list_of_encoded_numbers
    assert_equal [66655, 5444333, 2, 22], @hashids.decode("1gRYUwKxBgiVuX")
    assert_equal [683, 94108, 123, 5], @hashids.decode("aBMswoO2UB3Sj")

    assert_equal [3, 4], @hashids.decode("jYhp")
    assert_equal [6, 5], @hashids.decode("k9Ib")
    assert_equal [31, 41], @hashids.decode("EMhN")
    assert_equal [13, 89], @hashids.decode("glSgV")
  end

  def test_decode_does_not_decode_with_a_different_salt
    peppers = ::EncodedId::Encoders::HashId.new(::EncodedId::Encoders::HashIdSalt.new("this is my pepper"))

    assert_equal [12345], @hashids.decode("NkK9")
    assert_empty peppers.decode("NkK9")
  end

  def test_decode_can_decode_from_a_hash_with_a_minimum_length
    h = ::EncodedId::Encoders::HashId.new(@salt, 8)
    assert_equal [1], h.decode("gB0NV05e")
    assert_equal [25, 100, 950], h.decode("mxi8XH87")
    assert_equal [5, 200, 195, 1], h.decode("KQcmkIW8hX")
  end

  def test_decode_handles_invalid_input_by_raising_input_error
    assert_raises ::EncodedId::InvalidInputError do
      @hashids.decode("asdf-")
    end
  end

  def test_decode_hex_decodes_hex_string
    assert_equal "FA", @hashids.decode_hex("lzY")
    assert_equal "FF1A", @hashids.decode_hex("eBMrb")
    assert_equal "12ABC", @hashids.decode_hex("D9NPE")
  end

  def test_setup_raises_exception_if_alphabet_has_less_than_16_unique_chars
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Encoders::HashId.new(@salt, 0, ::EncodedId::Alphabet.new("abc"))
    end
  end

  def test_validation_of_attributes_raises_argument_error_unless_salt_is_a_string
    assert_raises ::EncodedId::SaltError do
      ::EncodedId::Encoders::HashId.new(::EncodedId::Encoders::HashIdSalt.new(:not_a_string))
    end
  end

  def test_validation_of_attributes_raises_argument_error_unless_min_length_is_an_integer
    assert_raises ::ArgumentError do
      ::EncodedId::Encoders::HashId.new(@salt, :not_an_integer)
    end
  end

  def test_validation_of_attributes_raises_argument_error_unless_alphabet_is_a_string
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::Encoders::HashId.new(@salt, 2, ::EncodedId::Alphabet.new(:not_a_string))
    end
  end

  def test_unhash_unhashes
    assert_equal 4, @hashids.send(:unhash, "bb", "abc".chars.map(&:ord))
    assert_equal 0, @hashids.send(:unhash, "aaa", "abc".chars.map(&:ord))
    assert_equal 21, @hashids.send(:unhash, "cba", "abc".chars.map(&:ord))
    assert_equal 572, @hashids.send(:unhash, "cbaabc", "abc".chars.map(&:ord))
    assert_equal 2728, @hashids.send(:unhash, "aX11b", "abcXYZ123".chars.map(&:ord))
    assert_equal 59, @hashids.send(:unhash, "abbd", "abcdefg".chars.map(&:ord))
    assert_equal 66, @hashids.send(:unhash, "abcd", "abcdefg".chars.map(&:ord))
    assert_equal 100, @hashids.send(:unhash, "acac", "abcdefg".chars.map(&:ord))
    assert_equal 139, @hashids.send(:unhash, "acfg", "abcdefg".chars.map(&:ord))
    assert_equal 218, @hashids.send(:unhash, "x21y", "xyz1234".chars.map(&:ord))
    assert_equal 440, @hashids.send(:unhash, "yy44", "xyz1234".chars.map(&:ord))
    assert_equal 1045, @hashids.send(:unhash, "1xzz", "xyz1234".chars.map(&:ord))
  end

  def test_consistent_shuffle_returns_the_alphabet_if_empty_salt
    assert_equal @default_alphabet, EncodedId::Encoders::HashIdConsistentShuffle.shuffle!(@default_alphabet, [], nil, 0)
  end

  def test_consistent_shuffle_shuffles_consistently
    salt_chars = @salt.chars.map(&:ord)
    assert_equal "ba".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!("ab".chars.map(&:ord), salt_chars, nil, salt_chars.length)
    assert_equal "bca".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!("abc".chars.map(&:ord), salt_chars, nil, salt_chars.length)
    assert_equal "cadb".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!("abcd".chars.map(&:ord), salt_chars, nil, salt_chars.length)
    assert_equal "dceba".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!("abcde".chars.map(&:ord), salt_chars, nil, salt_chars.length)
    assert_equal "f17a8zvCwo0iuqYDXlJ4RmAS2end5ghTcpjbOWLK9GFyE6xUI3ZBMQtPsNHrkV".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!(@default_alphabet, "salt".chars.map(&:ord), nil, 4)
    assert_equal "fcaodykrgqvblxjwmtupzeisnh".chars.map(&:ord), EncodedId::Encoders::HashIdConsistentShuffle.shuffle!("abcdefghijklmnopqrstuvwxyz".chars.map(&:ord), salt_chars[0..-3], salt_chars[-2..], salt_chars.length)
  end
end
