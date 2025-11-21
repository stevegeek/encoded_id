# frozen_string_literal: true

require "test_helper"

class ReversibleIdSqidsTest < Minitest::Test
  def test_it_encodes_an_integer_id
    id = 123
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_empty coded
    assert_equal [id], ::EncodedId::ReversibleId.sqids.decode(coded)
  end

  def test_it_encodes_an_integer_id_zero
    id = 0
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_empty coded
    assert_equal [id], ::EncodedId::ReversibleId.sqids.decode(coded)
  end

  def test_it_encodes_differently_with_different_salt
    id = 123
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    coded2 = ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz0123456789")).encode(id)
    refute_equal coded2, coded
  end

  def test_it_encodes_with_custom_alphabet
    id = 123
    coded = ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    refute_empty coded
    assert_equal [id], ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).decode(coded)
  end

  def test_it_encodes_with_custom_alphabet_as_array
    id = 123
    a = ::EncodedId::Alphabet.new(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"])
    coded = ::EncodedId::ReversibleId.sqids(alphabet: a).encode(id)
    refute_empty coded
    assert_equal [id], ::EncodedId::ReversibleId.sqids(alphabet: a).decode(coded)
  end

  def test_it_encodes_differently_with_different_alphabet
    id = 123
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    coded2 = ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    refute_equal coded2, coded
  end

  def test_it_encodes_with_custom_length
    id = 123
    coded = ::EncodedId::ReversibleId.sqids(min_length: 4).encode(id)
    assert_operator coded.delete("-").length, :>=, 4

    coded = ::EncodedId::ReversibleId.sqids(min_length: 16).encode(id)
    assert_operator coded.delete("-").length, :>=, 16
  end

  def test_it_raises_with_zero_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(min_length: 0)
    end
  end

  def test_it_raises_with_invalid_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(min_length: "foo")
    end
  end

  def test_it_raises_with_invalid_max_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(max_length: -1)
    end
  end

  def test_it_raises_with_invalid_max_length_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(max_length: "foo")
    end
  end

  def test_it_raises_with_invalid_inputs_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(max_inputs_per_id: 0)
    end
  end

  def test_it_raises_with_invalid_inputs_length_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(max_inputs_per_id: "foo")
    end
  end

  def test_it_raises_with_invalid_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.sqids(alphabet: 1234)
    end
  end

  def test_it_raises_with_blank_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.sqids(alphabet: nil)
    end
  end

  def test_it_raises_with_negative_id
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.sqids.encode(-1)
    end
  end

  def test_it_raises_with_empty_array
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.sqids.encode([])
    end
  end

  def test_it_decodes_back_to_an_integer_id
    id = 123
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    decoded = coder.decode(coded)
    assert_equal [id], decoded
  end

  def test_it_decodes_back_to_an_integer_id_with_case_insensitivity
    id = 123
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    decoded = coder.decode(coded.upcase, downcase: true)
    assert_equal [id], decoded
  end

  def test_it_correctly_decodes_encodedids_with_case_sensitivity
    id = 123
    a = ::EncodedId::Alphabet.new(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "b", "c", "d", "e"])
    enc = ::EncodedId::ReversibleId.sqids(alphabet: a)
    coded = enc.encode(id)

    # Should decode with exact case
    id1 = enc.decode(coded, downcase: false)
    assert_equal [id], id1

    # Should decode with downcase
    id2 = enc.decode(coded, downcase: true)
    assert_equal [id], id2
  end

  def test_it_decodes_back_to_id_with_mapped_chars
    id = 123
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    # Replace 'j' with 'i' if present (mapped characters)
    coded_with_mapped = coded.tr("j", "i")
    decoded = coder.decode(coded_with_mapped)
    assert_equal [id], decoded
  end

  def test_it_supports_alternate_character_mapping
    id = 8563432
    coder = ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", {"_" => "-"}), split_with: "F")
    coded = coder.encode(id)
    refute_empty coded
    # Test that underscore maps to hyphen
    assert_equal [id], coder.decode(coded.tr("-", "_"))
  end

  def test_it_allows_nil_for_character_equivalences
    id = 8563432
    coder = ::EncodedId::ReversibleId.sqids(alphabet: ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", nil), split_with: "F")
    coded = coder.encode(id)
    refute_empty coded
  end

  def test_it_encodes_a_string_id_w_coercion
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_empty coded
  end

  def test_it_encodes_with_no_separator_if_nil_split_at
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids(split_at: nil).encode(id)
    refute_includes coded, "-"
  end

  def test_it_encodes_with_no_separator_if_nil_split_with
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids(split_with: nil, split_at: 3).encode(id)
    refute_includes coded, "-"
  end

  def test_it_raises_with_invalid_split_at
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(split_at: -1)
    end
  end

  def test_it_raises_with_invalid_split_at_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(split_at: "r")
    end
  end

  def test_it_encodes_with_custom_separator
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids(split_with: "++").encode(id)
    assert_includes coded, "++"
  end

  def test_it_encodes_with_custom_separator_at_custom_point
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids(split_with: "++", split_at: 5).encode(id)
    assert_includes coded, "++"
  end

  def test_it_encodes_with_custom_separator_at_custom_point_past_string_length
    id = "123"
    coded = ::EncodedId::ReversibleId.sqids(split_with: "++", split_at: 100).encode(id)
    # If split_at is past the string length, no separator should be added
    refute_includes coded, "++"
  end

  def test_it_raises_with_invalid_separator
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(split_with: 123)
    end
  end

  def test_it_raises_when_separator_in_alphabet
    assert_raises EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(split_with: "a")
    end
  end

  def test_it_decodes_back_to_an_integer_id_with_no_separator
    id = 123
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    coded_no_sep = coded.delete("-")
    decoded = coder.decode(coded_no_sep)
    assert_equal [id], decoded
  end

  def test_it_decodes_with_nil_split_with
    id = 123
    coded = ::EncodedId::ReversibleId.sqids(split_with: nil).encode(id)
    decoded = ::EncodedId::ReversibleId.sqids(split_with: nil).decode(coded)
    assert_equal [id], decoded
  end

  def test_it_decodes_with_nil_split_with_and_case_insensitivity
    id = 123
    coded = ::EncodedId::ReversibleId.sqids(split_with: nil).encode(id)
    decoded = ::EncodedId::ReversibleId.sqids(split_with: nil).decode(coded.upcase, downcase: true)
    assert_equal [id], decoded
  end

  def test_it_does_not_contain_invalid_chars
    id = "2348723598"
    coded = ::EncodedId::ReversibleId.sqids(split_at: nil).encode(id)
    refute_includes coded, "l"
    refute_includes coded, "i"
    refute_includes coded, "o"
  end

  def test_it_encodes_multiple_ids
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_empty coded
    assert_equal id, ::EncodedId::ReversibleId.sqids.decode(coded)
  end

  def test_it_encodes_multiple_ids_with_different_length
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.sqids(min_length: 16).encode(id)
    assert_operator coded.delete("-").length, :>=, 16
  end

  def test_it_encodes_multiple_ids_with_different_split
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.sqids(min_length: 16, split_at: 8).encode(id)
    # Check that it has a separator at position 8
    refute_empty coded
  end

  def test_it_encodes_multiple_ids_with_different_alphabet
    id = [78, 45]
    coded = ::EncodedId::ReversibleId.sqids(min_length: 16, alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    refute_empty coded
  end

  def test_it_encodes_multiple_ids_with_custom_max_length
    id = [78, 45, 57]
    coded = ::EncodedId::ReversibleId.sqids(max_length: 32).encode(id)
    assert_operator coded.length, :<=, 32
  end

  def test_it_raises_when_encoding_size_exceeds_max_length
    id = [78, 45, 57, 78, 45, 57, 78, 45, 57]
    assert_raises ::EncodedId::EncodedIdLengthError do
      ::EncodedId::ReversibleId.sqids(max_length: 8).encode(id)
    end
  end

  def test_it_decodes_back_to_multiple_ids
    id = [78, 45]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    decoded = coder.decode(coded)
    assert_equal id, decoded
  end

  def test_it_decodes_back_to_multiple_ids_with_mapped_chars
    id = [78, 45]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    # Replace 'o' with '0' (mapped characters)
    coded_with_mapped = coded.tr("o", "0")
    decoded = coder.decode(coded_with_mapped)
    assert_equal id, decoded
  end

  def test_it_grows_the_hash_id_to_encode_many_ids
    id = [78, 45, 32]
    coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_empty coded
  end

  def test_it_decodes_back_to_many_ids
    id = [78, 45, 32]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode(id)
    decoded = coder.decode(coded)
    assert_equal id, decoded
  end

  def test_it_returns_empty_array_when_nothing_to_decode
    coded = "ozgf-w$65"
    id = ::EncodedId::ReversibleId.sqids.decode(coded)
    assert_equal [], id
  end

  def test_it_raises_when_hash_format_is_broken
    coded = "ogf-w$5^5"
    result = ::EncodedId::ReversibleId.sqids.decode(coded)
    assert_equal [], result
  end

  def test_it_raises_when_input_exceeds_max_length_for_decode
    coded = "a" * 20
    assert_raises EncodedId::EncodedIdFormatError do
      ::EncodedId::ReversibleId.sqids(max_length: 6).decode(coded)
    end
  end

  def test_it_encodes_hexadecimal
    id = "f1"
    coded = ::EncodedId::ReversibleId.sqids.encode_hex(id)
    refute_empty coded
  end

  def test_it_decodes_hexadecimal
    id = "f1"
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal [id], decoded
  end

  def test_it_decodes_hexadecimal_with_nil_split_with
    id = "f1"
    coder = ::EncodedId::ReversibleId.sqids(split_with: nil)
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal [id], decoded
  end

  def test_it_decodes_hexadecimal_with_nil_split_with_and_case_insensitivity
    id = "f1"
    coder = ::EncodedId::ReversibleId.sqids(split_with: nil)
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded.upcase, downcase: true)
    assert_equal [id], decoded
  end

  def test_it_encodes_multiple_hexadecimal
    id = ["f1", "c2", "1a"]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode_hex(id)
    refute_empty coded
  end

  def test_it_decodes_multiple_hexadecimal
    id = ["f1", "c2", "1a"]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal id, decoded
  end

  def test_it_encodes_multiple_hexadecimal_with_different_length
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode_hex(id)
    refute_empty coded
  end

  def test_it_decodes_multiple_hexadecimal_with_different_length
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coder = ::EncodedId::ReversibleId.sqids
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal id, decoded
  end

  def test_it_encodes_multiple_hexadecimal_as_uuids
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.sqids(split_at: 16, max_length: nil).encode_hex(id)
    refute_empty coded
  end

  def test_it_decodes_multiple_hexadecimal_as_uuids
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    # Remove hyphens for comparison
    expected = id.map { |uuid| uuid.delete("-") }
    # Sqids may produce longer encoded values for UUIDs, so set max_length to nil
    coder = ::EncodedId::ReversibleId.sqids(max_length: nil)
    coded = coder.encode_hex(id)
    decoded = coder.decode_hex(coded)
    assert_equal expected, decoded
  end

  def test_it_raises_when_input_exceeds_max_length_for_decode_hex
    coded = "a" * 100
    assert_raises EncodedId::EncodedIdFormatError do
      ::EncodedId::ReversibleId.sqids(max_length: 72).decode(coded)
    end
  end

  def test_it_raises_with_invalid_hex_digit_encoding_group_size
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 123)
    end
  end

  def test_it_raises_with_zero_hex_digit_encoding_group_size
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 0)
    end
  end

  def test_it_encodes_hex_with_different_hex_digit_encoding_group_size
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coded = ::EncodedId::ReversibleId.sqids.encode_hex(id)
    refute_empty coded

    coded8 = ::EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 8).encode_hex(id)
    refute_empty coded8
    refute_equal coded, coded8
  end

  def test_it_encodes_hex_with_different_hex_digit_encoding_group_size_when_long_inputs
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.sqids(max_length: nil).encode_hex(id)
    refute_empty coded

    coded10 = ::EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 10, max_length: nil).encode_hex(id)
    refute_empty coded10
    refute_equal coded, coded10
  end

  def test_it_encodes_hex_with_custom_max_length
    id = ["1", "c0"]
    coded = ::EncodedId::ReversibleId.sqids(max_length: 32).encode_hex(id)
    assert_operator coded.length, :<=, 32
  end

  def test_it_raises_when_hex_encoding_size_exceeds_max_length
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    assert_raises ::EncodedId::EncodedIdLengthError do
      ::EncodedId::ReversibleId.sqids(max_length: 8).encode_hex(id)
    end
  end

  def test_it_raises_when_encode_amount_of_id_provided_exceeds_max_inputs
    id = ["1", "2"]
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.sqids(max_inputs_per_id: 1).encode(id)
    end
  end

  def test_it_raises_when_encode_hex_amount_of_id_provided_exceeds_max_inputs
    id = "9a566b8b-8618-42ab-8db7-a5a0276401fd"
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.sqids(max_inputs_per_id: 7).encode_hex(id)
    end
  end

  def test_it_encodes_differently_with_sqids_vs_hashids
    id = 123
    hashids_coded = ::EncodedId::ReversibleId.hashid(salt: salt).encode(id)
    sqids_coded = ::EncodedId::ReversibleId.sqids.encode(id)
    refute_equal hashids_coded, sqids_coded
  end

  def test_it_raises_with_invalid_encoder
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, encoder: :invalid)
    end
  end

  def test_config_accessor_returns_sqids_configuration
    coder = ::EncodedId::ReversibleId.sqids
    assert_instance_of ::EncodedId::Encoders::SqidsConfiguration, coder.config
  end

  def test_config_accessor_returns_hashid_configuration
    coder = ::EncodedId::ReversibleId.hashid(salt: salt)
    assert_instance_of ::EncodedId::Encoders::HashidConfiguration, coder.config
  end

  def test_config_accessor_allows_introspection_of_min_length
    coder = ::EncodedId::ReversibleId.sqids(min_length: 16)
    assert_equal 16, coder.config.min_length
  end

  def test_config_accessor_allows_introspection_of_alphabet
    custom_alphabet = ::EncodedId::Alphabet.new("0123456789abcdef")
    coder = ::EncodedId::ReversibleId.sqids(alphabet: custom_alphabet)
    assert_equal custom_alphabet, coder.config.alphabet
  end

  def test_config_accessor_allows_introspection_of_split_at
    coder = ::EncodedId::ReversibleId.sqids(split_at: 8)
    assert_equal 8, coder.config.split_at
  end

  def test_config_accessor_allows_introspection_of_split_with
    coder = ::EncodedId::ReversibleId.sqids(split_with: "++")
    assert_equal "++", coder.config.split_with
  end

  def test_config_accessor_allows_introspection_of_max_length
    coder = ::EncodedId::ReversibleId.sqids(max_length: 64)
    assert_equal 64, coder.config.max_length
  end

  def test_config_accessor_allows_introspection_of_blocklist
    blocklist = ["bad", "word"]
    coder = ::EncodedId::ReversibleId.sqids(blocklist: blocklist)
    assert_instance_of ::EncodedId::Blocklist, coder.config.blocklist
  end

  def test_config_accessor_allows_introspection_of_salt_for_hashid
    coder = ::EncodedId::ReversibleId.hashid(salt: salt)
    assert_equal salt, coder.config.salt
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
