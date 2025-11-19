# frozen_string_literal: true

require "test_helper"

class BlocklistTest < Minitest::Test
  def setup
    @salt = "test_salt_12345"
    # "123" will be blocklisted for both encoders.
    @blocklist_words = Set.new(["mxyj", "85m3", "ugly", "profane"])
    @custom_blocklist = ::EncodedId::Blocklist.new(@blocklist_words)
  end

  def check_valid_and_invalid(encoder)
    encoded = encoder.encode(124)
    refute_nil encoded
    refute_empty encoded

    assert_raises(::EncodedId::BlocklistError) do
      encoder.encode(123)
    end
  end

  def test_empty_blocklist
    blocklist = EncodedId::Blocklist.empty
    assert blocklist.empty?
    assert_equal 0, blocklist.size
    assert_equal [], blocklist.to_a
    refute blocklist.include?("test")
    refute blocklist.blocks?("This is a test")
  end

  def test_minimal_blocklist
    blocklist = EncodedId::Blocklist.minimal
    refute blocklist.empty?
    assert blocklist.size > 0
    assert blocklist.to_a.any?
    assert blocklist.include?(blocklist.to_a.first)
    assert blocklist.include?(blocklist.to_a.first.upcase)
    refute blocklist.include?("hello")

    test_word = blocklist.to_a.first
    assert_equal test_word, blocklist.blocks?("#{test_word}-1234")
    assert_equal test_word, blocklist.blocks?("abcd#{test_word.upcase}s")
    refute blocklist.blocks?("Hello")
  end

  def test_custom_blocklist
    blocklist = @custom_blocklist
    refute blocklist.empty?
    assert_equal 4, blocklist.size
    assert_includes blocklist.to_a, "ugly"
    assert blocklist.include?("ugly")
    assert blocklist.include?("UGLY")
    refute blocklist.include?("nice")

    assert_equal "ugly", blocklist.blocks?("your-ugly")
    assert_equal "ugly", blocklist.blocks?("52sUGLYs1")
    refute blocklist.blocks?("nice")
  end

  def test_hashids_encoder_raises_error_for_blocklisted_words
    # Create a ReversibleId with a blocklist and hashids encoder
    reversible = ::EncodedId::ReversibleId.hashid(
      salt: @salt,
      blocklist: @custom_blocklist
    )
    check_valid_and_invalid(reversible)
  end

  def test_blocklist_accepts_array_input
    encoder = ::EncodedId::ReversibleId.hashid(
      salt: @salt,
      blocklist: @blocklist_words.to_a
    )

    check_valid_and_invalid(encoder)
  end

  def test_blocklist_raises_error_with_invalid_input
    assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::ReversibleId.hashid(
        salt: @salt,
        blocklist: "bad string input"
      )
    end
  end

  def test_sqids_encoder_respects_blocklist
    encoder = ::EncodedId::ReversibleId.sqids(
      blocklist: @custom_blocklist
    )

    encoded = encoder.encode(123)
    assert_equal "37vq-3u7t", encoded

    encoded = encoder.encode(124)
    refute_nil encoded
    refute_empty encoded
  end

  def test_sqids_blocklist
    blocklist = EncodedId::Blocklist.sqids_blocklist
    refute blocklist.empty?
    assert blocklist.size > 0
  end

  def test_merge_blocklists
    blocklist1 = EncodedId::Blocklist.new(["hello", "world"])
    blocklist2 = EncodedId::Blocklist.new(["test", "world"])
    merged = blocklist1.merge(blocklist2)

    assert_equal 3, merged.size
    assert_includes merged.to_a, "hello"
    assert_includes merged.to_a, "world"
    assert_includes merged.to_a, "test"

    assert_equal 2, blocklist1.size
    assert_equal 2, blocklist2.size
  end

  def test_filter_for_alphabet_with_alphabet_object
    blocklist = EncodedId::Blocklist.new(["test", "hello", "xyz"])
    alphabet = EncodedId::Alphabet.new("abcdefghijklmnopqrstuvwxyz")

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert_equal 3, filtered.size
    assert_includes filtered.to_a, "test"
    assert_includes filtered.to_a, "hello"
    assert_includes filtered.to_a, "xyz"
  end

  def test_filter_for_alphabet_with_string
    blocklist = EncodedId::Blocklist.new(["test", "hello", "xyz"])
    alphabet = "abcdefghijklmnopqrstuvwxyz"

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert_equal 3, filtered.size
    assert_includes filtered.to_a, "test"
    assert_includes filtered.to_a, "hello"
    assert_includes filtered.to_a, "xyz"
  end

  def test_filter_for_alphabet_removes_incompatible_words
    blocklist = EncodedId::Blocklist.new(["test", "hello", "xyz", "123"])
    alphabet = "abcdefghijklmnopqrstuvwxyz"

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert_equal 3, filtered.size
    assert_includes filtered.to_a, "test"
    assert_includes filtered.to_a, "hello"
    assert_includes filtered.to_a, "xyz"
    refute_includes filtered.to_a, "123"
  end

  def test_filter_minimal_blocklist_with_modified_crockford
    blocklist = EncodedId::Blocklist.minimal
    alphabet = EncodedId::Alphabet.modified_crockford

    filtered = blocklist.filter_for_alphabet(alphabet)

    refute filtered.empty?
    assert filtered.size < blocklist.size

    excluded_chars = Set.new(['i', 'l', 'o'])
    filtered.each do |word|
      refute word.chars.any? { |char| excluded_chars.include?(char) }
    end

    (blocklist.to_a - filtered.to_a).each do |word|
      assert word.chars.any? { |char| excluded_chars.include?(char) }
    end
  end

  def test_filter_sqids_blocklist_with_alphanum_alphabet
    blocklist = EncodedId::Blocklist.sqids_blocklist
    alphabet = EncodedId::Alphabet.alphanum

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert_equal blocklist.size, filtered.size
  end

  def test_filter_maintains_minimum_length
    blocklist = EncodedId::Blocklist.new(["ab", "abc", "abcd"])
    alphabet = "abcdefghijklmnopqrstuvwxyz"

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert_equal 2, filtered.size
    refute_includes filtered.to_a, "ab"
    assert_includes filtered.to_a, "abc"
    assert_includes filtered.to_a, "abcd"
  end

  def test_filter_for_alphabet_returns_new_blocklist
    original = EncodedId::Blocklist.new(["test", "hello", "xyz"])
    alphabet = "abcdefghijklmnopqrstuvwxyz"

    filtered = original.filter_for_alphabet(alphabet)

    refute_same original, filtered
    assert_instance_of EncodedId::Blocklist, filtered
  end

  def test_filter_empty_blocklist
    blocklist = EncodedId::Blocklist.empty
    alphabet = EncodedId::Alphabet.modified_crockford

    filtered = blocklist.filter_for_alphabet(alphabet)

    assert filtered.empty?
    assert_equal 0, filtered.size
  end
end
