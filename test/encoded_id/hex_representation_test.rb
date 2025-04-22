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
end
