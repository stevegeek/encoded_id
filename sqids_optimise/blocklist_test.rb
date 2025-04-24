# frozen_string_literal: true

require_relative "test_helper"

class BlocklistTest < Minitest::Test
  def test_uses_default_blocklist_if_no_custom_blocklist_is_provided
    sqids = Sqids.new
    my_sqids = MySqids.new

    assert_equal [4_572_721], sqids.decode("aho1e")
    assert_equal "JExTR", sqids.encode([4_572_721])

    assert_equal [4_572_721], my_sqids.decode("aho1e")
    assert_equal "JExTR", my_sqids.encode([4_572_721])
  end

  def test_does_not_use_any_blocklist_if_empty_blocklist_is_provided
    sqids = Sqids.new(blocklist: Set.new([]))
    my_sqids = MySqids.new(blocklist: Set.new([]))

    assert_equal [4_572_721], sqids.decode("aho1e")
    assert_equal "aho1e", sqids.encode([4_572_721])

    assert_equal [4_572_721], my_sqids.decode("aho1e")
    assert_equal "aho1e", my_sqids.encode([4_572_721])
  end

  def test_uses_provided_blocklist_if_non_empty_blocklist_is_provided
    sqids = Sqids.new(blocklist: Set.new(["ArUO"]))
    my_sqids = MySqids.new(blocklist: Set.new(["ArUO"]))

    assert_equal [4_572_721], sqids.decode("aho1e")
    assert_equal "aho1e", sqids.encode([4_572_721])

    assert_equal [100_000], sqids.decode("ArUO")
    assert_equal "QyG4", sqids.encode([100_000])
    assert_equal [100_000], sqids.decode("QyG4")

    assert_equal [4_572_721], my_sqids.decode("aho1e")
    assert_equal "aho1e", my_sqids.encode([4_572_721])

    assert_equal [100_000], my_sqids.decode("ArUO")
    assert_equal "QyG4", my_sqids.encode([100_000])
    assert_equal [100_000], my_sqids.decode("QyG4")
  end

  def test_uses_blocklist_to_prevent_certain_encodings
    blocklist = Set.new(%w[JSwXFaosAN OCjV9JK64o rBHf 79SM 7tE6])
    sqids = Sqids.new(blocklist: blocklist)
    my_sqids = MySqids.new(blocklist: blocklist)

    assert_equal "1aYeB7bRUt", sqids.encode([1_000_000, 2_000_000])
    assert_equal [1_000_000, 2_000_000], sqids.decode("1aYeB7bRUt")

    assert_equal "1aYeB7bRUt", my_sqids.encode([1_000_000, 2_000_000])
    assert_equal [1_000_000, 2_000_000], my_sqids.decode("1aYeB7bRUt")
  end

  def test_can_decode_blocklist_words
    blocklist = Set.new(%w[86Rf07 se8ojk ARsz1p Q8AI49 5sQRZO])
    sqids = Sqids.new(blocklist: blocklist)
    my_sqids = MySqids.new(blocklist: blocklist)

    assert_equal [1, 2, 3], sqids.decode("86Rf07")
    assert_equal [1, 2, 3], sqids.decode("se8ojk")
    assert_equal [1, 2, 3], sqids.decode("ARsz1p")
    assert_equal [1, 2, 3], sqids.decode("Q8AI49")
    assert_equal [1, 2, 3], sqids.decode("5sQRZO")

    assert_equal [1, 2, 3], my_sqids.decode("86Rf07")
    assert_equal [1, 2, 3], my_sqids.decode("se8ojk")
    assert_equal [1, 2, 3], my_sqids.decode("ARsz1p")
    assert_equal [1, 2, 3], my_sqids.decode("Q8AI49")
    assert_equal [1, 2, 3], my_sqids.decode("5sQRZO")
  end

  def test_matches_against_a_short_blocklist_word
    sqids = Sqids.new(blocklist: Set.new(["pnd"]))
    my_sqids = MySqids.new(blocklist: Set.new(["pnd"]))

    assert_equal [1_000], sqids.decode(sqids.encode([1_000]))
    assert_equal [1_000], my_sqids.decode(my_sqids.encode([1_000]))
  end

  def test_blocklist_filtering_in_constructor
    # lowercase blocklist in only-uppercase alphabet
    sqids = Sqids.new(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ", blocklist: Set.new(["sxnzkl"]))
    my_sqids = MySqids.new(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ", blocklist: Set.new(["sxnzkl"]))

    id_sqids = sqids.encode([1, 2, 3])
    numbers_sqids = sqids.decode(id_sqids)

    id_my_sqids = my_sqids.encode([1, 2, 3])
    numbers_my_sqids = my_sqids.decode(id_my_sqids)

    assert_equal "IBSHOZ", id_sqids # without blocklist, would've been "SXNZKL"
    assert_equal [1, 2, 3], numbers_sqids

    assert_equal "IBSHOZ", id_my_sqids # without blocklist, would've been "SXNZKL"
    assert_equal [1, 2, 3], numbers_my_sqids
  end

  def test_max_encoding_attempts
    alphabet = "abc"
    min_length = 3
    blocklist = Set.new(%w[cab abc bca])

    sqids = Sqids.new(alphabet: alphabet, min_length: min_length, blocklist: blocklist)
    my_sqids = MySqids.new(alphabet: alphabet, min_length: min_length, blocklist: blocklist)

    assert_equal min_length, alphabet.length
    assert_equal min_length, blocklist.size

    assert_raises(ArgumentError) do
      sqids.encode([0])
    end

    assert_raises(ArgumentError) do
      my_sqids.encode([0])
    end
  end
end
