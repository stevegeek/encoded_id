# frozen_string_literal: true

require "test_helper"

class TestEncodedId < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::VERSION
  end

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

  def test_it_raises_with_invalid_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: 1234)
    end
  end

  def test_it_raises_with_blank_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: "")
    end
  end

  def test_it_raises_with_small_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: "1234")
    end
  end

  def test_it_raises_with_not_enough_unique_chars_in_alphabet
    assert_raises ::EncodedId::InvalidAlphabetError do
      ::EncodedId::ReversibleId.new(salt: salt, alphabet: "1234567890abcdff")
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

  def test_it_supports_alternate_character_mapping
    id = 8563432
    coder = ::EncodedId::ReversibleId.new(salt: salt, alphabet: "!@#$%^&*()+-={}~", split_with: "F", character_equivalences: {"_" => "-"})
    coded = coder.encode(id)
    assert_equal "+={+F~-~}", coded
    assert_equal [id], coder.decode("+={+F~_~}")
  end

  def test_it_allows_nil_for_character_equivalences
    id = 8563432
    coder = ::EncodedId::ReversibleId.new(salt: salt, alphabet: "!@#$%^&*()+-={}~", split_with: "F", character_equivalences: nil)
    coded = coder.encode(id)
    assert_equal "+={+F~-~}", coded
  end

  def test_raises_on_invalid_character_equivalences
    assert_raises ::EncodedId::InvalidConfigurationError do
      ::EncodedId::ReversibleId.new(salt: salt, character_equivalences: "123")
    end
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
    assert_equal "a3kf-xjk9-u9zh-5bdq-hbd", coded
  end

  def test_it_decodes_multiple_hexadecimal
    coded = "a3kf-xjk9-u9zh-5bdq-hbd"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["f1", "c2", "1a"], id
  end

  def test_it_encodes_multiple_hexadecimal_with_different_length
    id = ["1", "c0", "97349ffe152d0013", "f0000"]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "rmhv-gr91-vatq-2knh-mcj3-dfmp-n6sn-epms-aed5-hkt2", coded
  end

  def test_it_decodes_multiple_hexadecimal_with_different_length
    coded = "rmhv-gr91-vatq-2knh-mcj3-dfmp-n6sn-epms-aed5-hkt2"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["1", "c0", "97349ffe152d0013", "f0000"], id
  end

  def test_it_encodes_multiple_hexadecimal_as_uuids
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.new(salt: salt, split_at: 16).encode_hex(id)
    assert_equal "mxxbfa8xtqxmvt3k-4dfbz3jhg9ebuem6-jtmx6r06e3qczk56-srrrxsn5v41qb5ah-zqx2sj2aau2e3jsx-59gcd96nh8mqksdm-9jcbz8b0dkeeuxpv-bh3x6pfq5en03pbx", coded
  end

  def test_it_decodes_multiple_hexadecimal_as_uuids
    coded = "mxxbfa8xtqxmvt3k-4dfbz3jhg9ebuem6-jtmx6r06e3qczk56-srrrxsn5v41qb5ah-zqx2sj2aau2e3jsx-59gcd96nh8mqksdm-9jcbz8b0dkeeuxpv-bh3x6pfq5en03pbx"
    id = ::EncodedId::ReversibleId.new(salt: salt).decode_hex(coded)
    assert_equal ["9a566b8b861842ab8db7a5a0276401fd", "59f3905ae7044714b42e960c82b699fe", "9c0498f3639d41ed87c3715c61e14798"], id
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
    assert_equal "rmhv-gr91-vatq-2knh-mcj3-dfmp-n6sn-epms-aed5-hkt2", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 8).encode_hex(id)
    assert_equal "x3hx-m3r5-xrnu-4205-2kmr-5m4h-bzxq-d9nf-ra28-vpd9-u4dr-v84v-2hdd-km3", coded
  end

  def test_it_encodes_hex_with_different_hex_digit_encoding_group_size_when_long_inputs
    id = ["9a566b8b-8618-42ab-8db7-a5a0276401fd", "59f3905a-e704-4714-b42e-960c82b699fe", "9c0498f3-639d-41ed-87c3-715c61e14798"]
    coded = ::EncodedId::ReversibleId.new(salt: salt).encode_hex(id)
    assert_equal "mxxb-fa8x-tqxm-vt3k-4dfb-z3jh-g9eb-uem6-jtmx-6r06-e3qc-zk56-srrr-xsn5-v41q-b5ah-zqx2-sj2a-au2e-3jsx-59gc-d96n-h8mq-ksdm-9jcb-z8b0-dkee-uxpv-bh3x-6pfq-5en0-3pbx", coded

    coded = ::EncodedId::ReversibleId.new(salt: salt, hex_digit_encoding_group_size: 10).encode_hex(id)
    assert_equal "vxdj-2vxj-ndfp-rjn5-e4pn-cd6g-4xqn-5asd-bcjx-2rjg-v46h-meg4-2zp3-tze3-kmqm-rg0m-dbr8-pxb2-t2n1-5avg-5pbk-9hjd-r65j-6qpu-n5ke-qqbb-5s6v-pg9m-6612-e", coded
  end

  private

  def salt
    "lha83hk73y9r3jp9js98ugo84"
  end
end
