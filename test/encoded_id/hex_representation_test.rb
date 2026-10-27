# frozen_string_literal: true

require "test_helper"

class HexRepresentationTest < Minitest::Test
  def setup
    @hex_representor = EncodedId::HexRepresentation.new(4) # using 4 as a sample group size
  end

  def test_initialize_with_valid_digit_group_size
    assert_instance_of EncodedId::HexRepresentation, @hex_representor
  end

  def test_initialize_with_invalid_digit_group_size
    assert_raises(EncodedId::InvalidConfigurationError) { EncodedId::HexRepresentation.new(0) }
    assert_raises(EncodedId::InvalidConfigurationError) { EncodedId::HexRepresentation.new(33) }
  end

  def test_hex_as_integers
    hex_value = "c0"
    result = @hex_representor.hex_as_integers(hex_value)
    assert_instance_of Array, result
    assert_equal [192], result
  end

  def test_larger_hex_as_integers
    hex_value = "ffff"
    result = @hex_representor.hex_as_integers(hex_value)
    assert_instance_of Array, result
    assert_equal [65535], result
  end

  def test_large_hex_splits_with_boundary
    hex_value = "10000"
    result = @hex_representor.hex_as_integers(hex_value)
    assert_instance_of Array, result
    assert_equal [0, 1], result
  end

  def test_large_hex_splits_at_next_boundary
    hex_value = "100010000"
    result = @hex_representor.hex_as_integers(hex_value)
    assert_instance_of Array, result
    assert_equal [0, 1, 1], result
  end

  def test_integers_as_hex
    integers = [0, 1, 1]
    result = @hex_representor.integers_as_hex(integers)
    assert_instance_of Array, result
    assert_equal ["100010000"], result
  end

  def test_hex_with_leading_zeros_as_integers_includes_a_length_marker
    assert_equal [255, 65541], @hex_representor.hex_as_integers("00ff")
  end

  def test_hex_of_only_zeros_as_integers_includes_a_length_marker
    assert_equal [0, 65540], @hex_representor.hex_as_integers("000")
  end

  def test_empty_hex_as_integers_is_a_zero_length_marker
    assert_equal [65537], @hex_representor.hex_as_integers("")
  end

  def test_empty_first_hex_as_integers_is_a_zero_length_marker
    assert_equal [65537, 65536, 171], @hex_representor.hex_as_integers(["", "ab"])
  end

  def test_empty_later_hex_as_integers_has_no_marker
    assert_equal [171, 65536, 65536, 205], @hex_representor.hex_as_integers(["ab", "", "cd"])
  end

  def test_hex_without_leading_zeros_as_integers_has_no_marker
    assert_equal [255], @hex_representor.hex_as_integers("ff")
    assert_equal [0, 1], @hex_representor.hex_as_integers("10000")
    assert_equal [0], @hex_representor.hex_as_integers("0")
  end

  def test_hex_with_no_hex_digits_raises
    error = assert_raises(EncodedId::InvalidInputError) { @hex_representor.hex_as_integers("zz") }
    assert_equal 'Hex string "zz" contains no hex digits', error.message
  end

  def test_later_hex_with_no_hex_digits_raises
    assert_raises(EncodedId::InvalidInputError) { @hex_representor.hex_as_integers(["ab", "--"]) }
  end

  def test_integers_with_length_markers_as_hex
    assert_equal ["00ff"], @hex_representor.integers_as_hex([255, 65541])
    assert_equal ["000"], @hex_representor.integers_as_hex([0, 65540])
    assert_equal [""], @hex_representor.integers_as_hex([65537])
    assert_equal ["", "ab"], @hex_representor.integers_as_hex([65537, 65536, 171])
    assert_equal ["ab", "0012"], @hex_representor.integers_as_hex([171, 65536, 18, 65541])
    assert_equal ["0000", "00000"], @hex_representor.integers_as_hex([0, 65541, 65536, 0, 0])
  end

  def test_integers_with_an_empty_later_element_as_hex
    assert_equal ["ab", "", "cd"], @hex_representor.integers_as_hex([171, 65536, 65536, 205])
    assert_equal ["ab", ""], @hex_representor.integers_as_hex([171, 65536])
  end

  def test_integers_with_an_empty_first_element_and_no_marker_drop_that_element
    assert_equal ["ab"], @hex_representor.integers_as_hex([65536, 171])
  end

  def test_integers_with_a_value_above_the_largest_marker_as_hex_is_empty
    assert_equal [], @hex_representor.integers_as_hex([65542])
    assert_equal [], @hex_representor.integers_as_hex([1, 65542])
  end

  def test_integers_with_a_marker_before_the_most_significant_group_as_hex_is_empty
    assert_equal [], @hex_representor.integers_as_hex([1, 65541, 2])
    assert_equal [], @hex_representor.integers_as_hex([65537, 65537])
  end

  def test_integers_with_a_zero_length_marker_and_groups_as_hex_is_empty
    assert_equal [], @hex_representor.integers_as_hex([5, 65537])
  end

  def test_integers_with_a_length_marker_and_no_groups_as_hex_is_empty
    assert_equal [], @hex_representor.integers_as_hex([65539])
    assert_equal [], @hex_representor.integers_as_hex([171, 65536, 65539])
  end

  def test_integers_with_a_group_wider_than_its_marker_as_hex_is_empty
    assert_equal [], @hex_representor.integers_as_hex([511, 65539])
  end
end
