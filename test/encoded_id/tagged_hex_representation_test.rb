# frozen_string_literal: true

require "test_helper"

class TaggedHexRepresentationTest < Minitest::Test
  def setup
    @representation = EncodedId::TaggedHexRepresentation.new
  end

  def test_a_short_hex_string_is_one_last_chunk
    assert_equal [0x2c0], @representation.hex_as_integers("c0")
  end

  def test_leading_zeros_are_kept_in_the_chunk
    assert_equal [0x200ff], @representation.hex_as_integers("00ff")
  end

  def test_an_empty_string_is_an_empty_last_chunk
    assert_equal [0x2], @representation.hex_as_integers("")
  end

  def test_a_uuid_is_split_into_balanced_chunks
    assert_equal [0x19a566b8b861, 0x1842ab8db7a5, 0x2a0276401fd], @representation.hex_as_integers("9a566b8b-8618-42ab-8db7-a5a0276401fd")
  end

  def test_chunk_boundaries
    assert_equal [0x2000000000000000], @representation.hex_as_integers("0" * 15)
    assert_equal [0x100000000, 0x200000000], @representation.hex_as_integers("0" * 16)
    assert_equal [0x1000000000000000, 0x2000000000000000], @representation.hex_as_integers("0" * 30)
    assert_equal [0x100000000000, 0x10000000000, 0x20000000000], @representation.hex_as_integers("0" * 31)
  end

  def test_multiple_strings_each_end_with_a_last_chunk
    assert_equal [0x2ab, 0x2, 0x2cd], @representation.hex_as_integers(["ab", "", "cd"])
  end

  def test_upper_case_input_encodes_as_lower_case
    assert_equal @representation.hex_as_integers("abcdef"), @representation.hex_as_integers("ABCDEF")
  end

  def test_a_string_with_no_hex_digits_raises
    error = assert_raises(EncodedId::InvalidInputError) { @representation.hex_as_integers(["ab", "zz"]) }
    assert_equal 'Hex string "zz" contains no hex digits', error.message
  end

  def test_integers_as_hex_round_trips
    ["00ff", ["", "0"], ["ab", "", "0012"], "f" * 15, "0" * 31, ["9a566b8b861842ab8db7a5a0276401fd", ""]].each do |input|
      assert_equal Array(input), @representation.integers_as_hex(@representation.hex_as_integers(input)), "round trip of #{input.inspect}"
    end
  end

  def test_integers_as_hex_rejects_values_without_a_valid_tag
    assert_equal [], @representation.integers_as_hex([0x3ab])
    assert_equal [], @representation.integers_as_hex([0])
    assert_equal [], @representation.integers_as_hex([-0x2ab])
  end

  def test_integers_as_hex_rejects_a_string_without_a_last_chunk
    assert_equal [], @representation.integers_as_hex([0x2ab, 0x1000000000000000])
  end

  def test_integers_as_hex_rejects_lists_that_are_not_how_the_strings_encode
    assert_equal [], @representation.integers_as_hex([0x1ab, 0x2cd])
    assert_equal [], @representation.integers_as_hex([0x1, 0x2ab])
    assert_equal [], @representation.integers_as_hex([0x1000000000000000, 0x2])
    assert_equal [], @representation.integers_as_hex([0x20000000000000000])
    assert_equal [], @representation.integers_as_hex([0x1000000000000000, 0x20])
    assert_equal [], @representation.integers_as_hex([0x10000, 0x200000000000])
    assert_equal [], @representation.integers_as_hex([0x100, 0x2])
    assert_equal [], @representation.integers_as_hex([0x1000000000000000, 0x1000000000000000, 0x20])
    assert_equal [], @representation.integers_as_hex([0x10000000000, 0x100000000000, 0x20000000000])
    assert_equal [], @representation.integers_as_hex([0x100000000000, 0x1000000000, 0x200000000000])
  end
end
