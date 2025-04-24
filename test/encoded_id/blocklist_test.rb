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

    assert_raises(::EncodedId::InvalidInputError) do
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
    assert_includes blocklist.to_a, "fuck"
    assert blocklist.include?("fuck")
    assert blocklist.include?("FUCK")
    refute blocklist.include?("hello")

    assert_equal "fuck", blocklist.blocks?("fuck-1234")
    assert_equal "fuck", blocklist.blocks?("abcdFUCKs")
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
    reversible = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :hashids,
      blocklist: @custom_blocklist
    )
    check_valid_and_invalid(reversible)
  end

  def test_blocklist_accepts_array_input
    encoder = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :hashids,
      blocklist: @blocklist_words.to_a
    )

    check_valid_and_invalid(encoder)
  end

  def test_blocklist_raises_error_with_invalid_input
    assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::ReversibleId.new(
        salt: @salt,
        encoder: :hashids,
        blocklist: "bad string input"
      )
    end
  end

  def test_sqids_encoder_respects_blocklist
    encoder = ::EncodedId::ReversibleId.new(
      salt: @salt,
      encoder: :sqids,
      blocklist: @custom_blocklist
    )

    # Sqids generate new ID on blocklist (id with "85m3" is blocked)
    encoded = encoder.encode(123)
    assert_equal "37vq-3u7t", encoded

    encoded = encoder.encode(124)
    refute_nil encoded
    refute_empty encoded
  end

  def test_sqids_blocklist
    skip unless defined?(::Sqids::DEFAULT_BLOCKLIST)

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

    # Original blocklists should remain unchanged
    assert_equal 2, blocklist1.size
    assert_equal 2, blocklist2.size
  end
end
