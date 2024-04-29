# frozen_string_literal: true

require "test_helper"

class TestReversibleId < Minitest::Test
  def test_it_raises_with_invalid_salt
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: 123)
    end
  end

  def test_it_raises_with_invalid_salt_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: "1")
    end
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
    coded = ::EncodedId::ReversibleId.new(salt: salt, alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    assert_equal "923b-a293", coded
  end

  def test_it_encodes_with_custom_alphabet_as_array
    id = 123
    a = ::EncodedId::Alphabet.new(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"])
    coded = ::EncodedId::ReversibleId.new(salt: salt, alphabet: a).encode(id)
    assert_equal "923b-a293", coded
  end

  def test_it_encodes_differently_with_different_alphabet
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    coded2 = ::EncodedId::ReversibleId.new(salt: salt, alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    refute_equal coded2, coded
  end

  def test_it_encodes_with_custom_length
    id = 123
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 4).encode(id)
    assert_equal "w9z2", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16).encode(id)
    assert_equal "8kdx-p5w9-z27j-4aqv", coded
  end

  def test_it_raises_with_zero_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, length: 0)
    end
  end

  def test_it_raises_with_invalid_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, length: "foo")
    end
  end

  def test_it_raises_with_invalid_max_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: -1)
    end
  end

  def test_it_raises_with_invalid_max_length_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: "foo")
    end
  end

  def test_it_raises_with_invalid_inputs_length
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, max_inputs_per_id: 0)
    end
  end

  def test_it_raises_with_invalid_inputs_length_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, max_inputs_per_id: "foo")
    end
  end

  def test_it_raises_with_invalid_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: 1234)
    end
  end

  def test_it_raises_with_blank_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: nil)
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

  def test_it_decodes_back_to_an_integer_id_with_case_insensitivity
    coded = "P5w9-z27j"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded, downcase: true)
    assert_equal [123], id
  end

  def test_it_correctly_decodes_encodedids_with_case_sensitivity
    coded1 = "e5bd-ea58"
    coded2 = "e5bd-eA58"
    a = ::EncodedId::Alphabet.new(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "b", "c", "d", "e"])
    enc = ::EncodedId::ReversibleId.new(salt: salt, alphabet: a)
    id1 = enc.decode(coded1, downcase: false)
    assert_equal [123], id1
    id2 = enc.decode(coded2)
    assert_equal [123], id2
    id2 = enc.decode(coded2, downcase: true)
    assert_equal [123], id2
    id2 = enc.decode(coded2, downcase: false)
    assert_equal [], id2
  end

  def test_it_decodes_back_to_id_with_mapped_chars
    coded = "p5w9-z27i" # 'i' used instead of 'j'
    id = ::EncodedId::ReversibleId.new(salt: salt).decode(coded)
    assert_equal [123], id
  end

  def test_it_supports_alternate_character_mapping
    id = 8563432
    coder = ::EncodedId::ReversibleId.new(salt: salt, alphabet: ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", {"_" => "-"}), split_with: "F")
    coded = coder.encode(id)
    assert_equal "+={+F~-~}", coded
    assert_equal [id], coder.decode("+={+F~_~}")
  end

  def test_it_allows_nil_for_character_equivalences
    id = 8563432
    coder = ::EncodedId::ReversibleId.new(salt: salt, alphabet: ::EncodedId::Alphabet.new("!@#$%^&*()+-={}~", nil), split_with: "F")
    coded = coder.encode(id)
    assert_equal "+={+F~-~}", coded
  end

  def test_it_encodes_a_string_id_w_coercion
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode(id)
    assert_equal "p5w9-z27j", coded
  end

  def test_it_encodes_with_no_separator_if_nil_split_at
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_at: nil).encode(id)
    assert_equal "p5w9z27j", coded
  end

  def test_it_encodes_with_no_separator_if_nil_split_with
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_with: nil, split_at: 3).encode(id)
    assert_equal "p5w9z27j", coded
  end

  def test_it_raises_with_invalid_split_at
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, split_at: -1)
    end
  end

  def test_it_raises_with_invalid_split_at_type
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, split_at: "r")
    end
  end

  def test_it_encodes_with_custom_separator
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_with: "++").encode(id)
    assert_equal "p5w9++z27j", coded
  end

  def test_it_encodes_with_custom_separator_at_custom_point
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_with: "++", split_at: 5).encode(id)
    assert_equal "p5w9z++27j", coded
  end

  def test_it_encodes_with_custom_separator_at_custom_point_past_string_length
    id = "123"
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_with: "++", split_at: 8).encode(id)
    assert_equal "p5w9z27j", coded
  end

  def test_it_raises_with_invalid_separator
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, split_with: 123)
    end
  end

  def test_it_raises_when_separator_in_alphabet
    assert_raises EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, split_with: "a")
    end
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
    coded = ::EncodedId::ReversibleId.new(salt: salt, length: 16, alphabet: ::EncodedId::Alphabet.new("0123456789abcdef")).encode(id)
    assert_equal "d48e-636e-8069-32ab", coded
  end

  def test_it_encodes_multiple_ids_with_custom_max_length
    id = [78, 45, 57]
    coded = ::EncodedId::ReversibleId.new(salt: salt, max_length: 16).encode(id)
    assert_equal "nmd0-xdf4-8", coded
  end

  def test_it_raises_when_encoding_size_exceeds_max_length
    id = [78, 45, 57, 78, 45, 57, 78, 45, 57]
    assert_raises ::EncodedId::EncodedIdLengthError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: 8).encode(id)
    end
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

  def test_it_raises_when_input_exceeds_max_length_for_decode
    coded = "ogf-w$5^5"
    assert_raises EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: 6).decode(coded)
    end
  end

  def test_it_encodes_hexadecimal
    id = "f1"
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "zryg-pey4", coded
  end

  def test_it_decodes_hexadecimal
    coded = "zryg-pey4"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["f1"], id
  end

  def test_it_encodes_multiple_hexadecimal
    id = ["f1", "c2", "1a"]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "x2vh-kjrg-t4qt-nzm3-fn2", coded
  end

  def test_it_decodes_multiple_hexadecimal
    coded = "x2vh-kjrg-t4qt-nzm3-fn2"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["f1", "c2", "1a"], id
  end

  def test_it_encodes_multiple_hexadecimal_with_different_length
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "bbhb-495h-bzud-269u-pc3k-nfnm-3gsj-9xa0-zg24-trtz", coded
  end

  def test_it_decodes_multiple_hexadecimal_with_different_length
    coded = "bbhb-495h-bzud-269u-pc3k-nfnm-3gsj-9xa0-zg24-trtz"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["1", "c0", "97349ffe152d0013", "f0000"], id
  end

  def test_it_encodes_multiple_hexadecimal_as_uuids
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_at: 16, max_length: nil).encode_hex(id)
    assert_equal "qrrgfpbqcjnm2t6p-zqc83gncbqjgfbne-qcea2msrx6b026d3-s444ruvz35c6m8rs-3ernu4pbburzemur-5g4hjkn9uvn8ktqv-xef89x8tdkeeur3a-gfgqkahjb64h69na", coded
  end

  def test_it_decodes_multiple_hexadecimal_as_uuids
    coded = "qrrgfpbqcjnm2t6p-zqc83gncbqjgfbne-qcea2msrx6b026d3-s444ruvz35c6m8rs-3ernu4pbburzemur-5g4hjkn9uvn8ktqv-xef89x8tdkeeur3a-gfgqkahjb64h69na"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["9a566b8b861842ab8db7a5a0276401fd", "59f3905ae7044714b42e960c82b699fe", "9c0498f3639d41ed87c3715c61e14798"], id
  end

  def test_it_raises_when_input_exceeds_max_length_for_decode_hex
    coded = "qrrgfpbqcjnm2t6p-zqc83gncbqjgfbne-qcea2msrx6b026d3-s444ruvz35c6m8rs-3ernu4pbburzemur-5g4hjkn9uvn8ktqv-xef89x8tdkeeur3a-gfgqkahjb64h69na"
    assert_raises EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: 72).decode(coded)
    end
  end

  def test_it_raises_with_invalid_hex_digit_encoding_group_size
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 123)
    end
  end

  def test_it_raises_with_zero_hex_digit_encoding_group_size
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 0)
    end
  end

  def test_it_encodes_hex_with_different_hex_digit_encoding_group_size
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "bbhb-495h-bzud-269u-pc3k-nfnm-3gsj-9xa0-zg24-trtz", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 8).encode_hex(id)
    assert_equal "54ha-289r-a95t-4j0j-4pa2-ja9c-v3m8-z2g1-qxjp-ak8n-08j6-ga8g-kujj-ae6", coded
  end

  def test_it_encodes_hex_with_different_hex_digit_encoding_group_size_when_long_inputs
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.new(salt: salt, max_length: nil).encode_hex(id)
    assert_equal "qrrg-fpbq-cjnm-2t6p-zqc8-3gnc-bqjg-fbne-qcea-2msr-x6b0-26d3-s444-ruvz-35c6-m8rs-3ern-u4pb-burz-emur-5g4h-jkn9-uvn8-ktqv-xef8-9x8t-dkee-ur3a-gfgq-kahj-b64h-69na", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 10, max_length: nil).encode_hex(id)
    assert_equal "zezp-vxep-mzc3-4gbj-p63b-hx5d-kqeg-rpug-6tav-2ma3-n5mu-rdjv-4bpx-fbae-p5g5-280n-mqd3-6bqv-sx2h-rknv-rb5z-vhvd-jnbv-ng4t-m5vb-22kk-5hrk-36qg-rrh4-2", coded
  end

  def test_it_encodes_hex_with_custom_max_length
    id = ["1", "c0"]
    coded = ::EncodedId::ReversibleId.new(salt: salt, max_length: 32).encode_hex(id)
    assert_equal "d4h2-xerh-rk", coded
  end

  def test_it_raises_when_hex_encoding_size_exceeds_max_length
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    assert_raises ::EncodedId::EncodedIdLengthError do
      ::EncodedId::ReversibleId.new(salt: salt, max_length: 8).encode_hex(id)
    end
  end

  def test_it_raises_when_encode_amount_of_id_provided_exceeds_max_inputs
    id = ["1", "2"]
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.new(salt: salt, max_inputs_per_id: 1).encode(id)
    end
  end

  def test_it_raises_when_encode_hex_amount_of_id_provided_exceeds_max_inputs
    id = "9a566b8b-8618-42ab-8db7-a5a0276401fd"
    assert_raises ::EncodedId::InvalidInputError do
      ::EncodedId::ReversibleId.new(salt: salt, max_inputs_per_id: 7).encode_hex(id)
    end
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
