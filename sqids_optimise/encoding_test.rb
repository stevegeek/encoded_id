# frozen_string_literal: true

require_relative "test_helper"

class EncodingTest < Minitest::Test
  def test_simple
    sqids = Sqids.new
    my_sqids = MySqids.new

    numbers = [1, 2, 3]
    id = "86Rf07"

    assert_equal id, sqids.encode(numbers)
    assert_equal numbers, sqids.decode(id)

    assert_equal id, my_sqids.encode(numbers)
    assert_equal numbers, my_sqids.decode(id)
  end

  def test_different_inputs
    sqids = Sqids.new
    my_sqids = MySqids.new

    numbers = [0, 0, 0, 1, 2, 3, 100, 1_000, 100_000, 1_000_000, Sqids.max_value]

    assert_equal numbers, sqids.decode(sqids.encode(numbers))
    assert_equal numbers, my_sqids.decode(my_sqids.encode(numbers))
  end

  def test_incremental_numbers
    sqids = Sqids.new
    my_sqids = MySqids.new

    ids = {
      "bM" => [0],
      "Uk" => [1],
      "gb" => [2],
      "Ef" => [3],
      "Vq" => [4],
      "uw" => [5],
      "OI" => [6],
      "AX" => [7],
      "p6" => [8],
      "nJ" => [9]
    }

    ids.each do |id, numbers|
      assert_equal id, sqids.encode(numbers)
      assert_equal numbers, sqids.decode(id)

      assert_equal id, my_sqids.encode(numbers)
      assert_equal numbers, my_sqids.decode(id)
    end
  end

  def test_incremental_numbers_same_index_0
    sqids = Sqids.new
    my_sqids = MySqids.new

    ids = {
      "SvIz" => [0, 0],
      "n3qa" => [0, 1],
      "tryF" => [0, 2],
      "eg6q" => [0, 3],
      "rSCF" => [0, 4],
      "sR8x" => [0, 5],
      "uY2M" => [0, 6],
      "74dI" => [0, 7],
      "30WX" => [0, 8],
      "moxr" => [0, 9]
    }

    ids.each do |id, numbers|
      assert_equal id, sqids.encode(numbers)
      assert_equal numbers, sqids.decode(id)

      assert_equal id, my_sqids.encode(numbers)
      assert_equal numbers, my_sqids.decode(id)
    end
  end

  def test_incremental_numbers_same_index_1
    sqids = Sqids.new
    my_sqids = MySqids.new

    ids = {
      "SvIz" => [0, 0],
      "nWqP" => [1, 0],
      "tSyw" => [2, 0],
      "eX68" => [3, 0],
      "rxCY" => [4, 0],
      "sV8a" => [5, 0],
      "uf2K" => [6, 0],
      "7Cdk" => [7, 0],
      "3aWP" => [8, 0],
      "m2xn" => [9, 0]
    }

    ids.each do |id, numbers|
      assert_equal id, sqids.encode(numbers)
      assert_equal numbers, sqids.decode(id)

      assert_equal id, my_sqids.encode(numbers)
      assert_equal numbers, my_sqids.decode(id)
    end
  end

  def test_multi_input
    sqids = Sqids.new
    my_sqids = MySqids.new

    numbers = (0..99).to_a

    assert_equal numbers, sqids.decode(sqids.encode(numbers))
    assert_equal numbers, my_sqids.decode(my_sqids.encode(numbers))
  end

  def test_encoding_no_numbers
    sqids = Sqids.new
    my_sqids = MySqids.new

    assert_equal "", sqids.encode([])
    assert_equal "", my_sqids.encode([])
  end

  def test_encoding_with_float
    sqids = Sqids.new
    my_sqids = MySqids.new

    float = 3.14159265
    encoded_float = sqids.encode([float])
    encoded_int = sqids.encode([float.to_i])

    assert_equal encoded_int, encoded_float

    my_encoded_float = my_sqids.encode([float])
    my_encoded_int = my_sqids.encode([float.to_i])

    assert_equal my_encoded_int, my_encoded_float
  end

  def test_decoding_empty_string
    sqids = Sqids.new
    my_sqids = MySqids.new

    assert_equal [], sqids.decode("")
    assert_equal [], my_sqids.decode("")
  end

  def test_decoding_an_id_with_invalid_character
    sqids = Sqids.new
    my_sqids = MySqids.new

    assert_equal [], sqids.decode("*")
    assert_equal [], my_sqids.decode("*")
  end

  def test_encode_out_of_range_numbers
    sqids = Sqids.new
    my_sqids = MySqids.new

    assert_raises(ArgumentError) { sqids.encode([-1]) }
    assert_raises(ArgumentError) { sqids.encode([Sqids.max_value + 1]) }

    assert_raises(ArgumentError) { my_sqids.encode([-1]) }
    assert_raises(ArgumentError) { my_sqids.encode([MySqids.max_value + 1]) }
  end
end
