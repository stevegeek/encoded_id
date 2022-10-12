# frozen_string_literal: true

require "test_helper"

class TestEncodedId < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::VERSION
  end

  def test_it_encodes_an_integer_id
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "p5w9-z27j", coded
  end

  def test_it_encodes_an_integer_id_zero
    id = 0
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "qg7m-ewr2", coded
  end

  def test_it_encodes_differently_with_different_salt
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    coded2 = ::EncodedId::ReversibleId.new(salt: "another salt").encode(id)
    refute_equal coded2, coded
  end

  def test_it_encodes_with_custom_alphabet
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt, alphabet: "0123456789abcdef").encode(id)
    assert_equal "923b-a293", coded
  end

  def test_it_encodes_differently_with_different_alphabet
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    coded2 = ::EncodedId::ReversibleId.new(salt: salt, alphabet: "0123456789abcdef").encode(id)
    refute_equal coded2, coded
  end

  def test_it_encodes_with_custom_length
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 4).encode(id)
    assert_equal "w9z2", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16).encode(id)
    assert_equal "8kdx-p5w9-z27j-4aqv", coded
  end

  def test_it_raises_with_small_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: "1234")
    end
  end

  def test_it_raises_with_negative_id
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.new(salt: salt).encode(-1)
    end
  end

  def test_it_decodes_back_to_an_integer_id
    coded = "p5w9-z27j"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [123], id
  end

  def test_it_decodes_back_to_id_with_mapped_chars
    coded = "p5w9-z27i" # 'i' used instead of 'j'
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [123], id
  end

  def test_it_encodes_a_string_id_w_coercion
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "p5w9-z27j", coded
  end

  def test_it_encodes_with_no_separator
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_at: nil).encode(id)
    assert_equal "p5w9z27j", coded
  end

  def test_it_decodes_back_to_an_integer_id_with_no_separator
    coded = "p5w9z27j"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [123], id
  end

  def test_it_does_not_contain_invalid_chars
    id = "2348723598"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_at: nil).encode(id)
    refute_includes coded, "l"
    refute_includes coded, "i"
    refute_includes coded, "o"
  end

  def test_it_encodes_multiple_ids
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "7aq6-0zqw", coded
  end

  def test_it_encodes_multiple_ids_with_different_length
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16).encode(id)
    assert_equal "z36m-7aq6-0zqw-vj2k", coded
  end

  def test_it_encodes_multiple_ids_with_different_split
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16, split_at: 8).encode(id)
    assert_equal "z36m7aq6-0zqwvj2k", coded
  end

  def test_it_encodes_multiple_ids_with_different_alphabet
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16, alphabet: "0123456789abcdef").encode(id)
    assert_equal "d48e-636e-8069-32ab", coded
  end

  def test_it_decodes_back_to_multiple_ids
    coded = "7aq6-0zqw"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [78, 45], id
  end

  def test_it_decodes_back_to_multiple_ids_with_mapped_chars
    coded = "7aq6-ozqw" # o used instead of 0
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [78, 45], id
  end

  def test_it_grows_the_hash_id_to_encode_many_ids
    id = [78, 45, 32]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "9n80-qbf8-a", coded
  end

  def test_it_decodes_back_to_many_ids
    coded = "9n80-qbf8-a"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [78, 45, 32], id
  end

  def test_it_returns_empty_array_when_nothing_to_decode
    coded = "ozgf-w$65"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [], id
  end

  def test_it_raises_when_hash_format_is_broken
    coded = "ogf-w$5^5"
    assert_raises EncodedId::EncodedIdFormatError do
      ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    end
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
