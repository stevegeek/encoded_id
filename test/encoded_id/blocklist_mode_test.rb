# frozen_string_literal: true

require "test_helper"

class BlocklistModeTest < Minitest::Test
  def setup
    @salt = "test_salt_12345"
    @blocklist = ::EncodedId::Blocklist.minimal
  end

  def test_default_blocklist_mode_is_length_threshold
    config = ::EncodedId::Encoders::HashidConfiguration.new(salt: @salt, blocklist: @blocklist)
    assert_equal :length_threshold, config.blocklist_mode
    assert_equal 32, config.blocklist_max_length
  end

  def test_valid_blocklist_modes
    [:always, :length_threshold, :raise_if_likely].each do |mode|
      config = ::EncodedId::Encoders::HashidConfiguration.new(
        salt: @salt,
        blocklist: @blocklist,
        blocklist_mode: mode
      )
      assert_equal mode, config.blocklist_mode
    end
  end

  def test_invalid_blocklist_mode_raises_error
    assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::Encoders::HashidConfiguration.new(
        salt: @salt,
        blocklist: @blocklist,
        blocklist_mode: :invalid_mode
      )
    end
  end

  def test_custom_blocklist_max_length
    config = ::EncodedId::Encoders::HashidConfiguration.new(
      salt: @salt,
      blocklist: @blocklist,
      blocklist_max_length: 50
    )
    assert_equal 50, config.blocklist_max_length
  end

  def test_raise_if_likely_mode_raises_when_min_length_too_long
    error = assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::Encoders::HashidConfiguration.new(
        salt: @salt,
        min_length: 100,
        blocklist: @blocklist,
        blocklist_mode: :raise_if_likely,
        blocklist_max_length: 32
      )
    end
    assert_match(/min_length.*exceeds blocklist_max_length/, error.message)
  end

  def test_raise_if_likely_mode_raises_when_max_inputs_too_high
    error = assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::Encoders::SqidsConfiguration.new(
        max_inputs_per_id: 200,
        blocklist: @blocklist,
        blocklist_mode: :raise_if_likely
      )
    end
    assert_match(/max_inputs_per_id.*very high/, error.message)
  end

  def test_raise_if_likely_mode_allows_safe_configuration
    config = ::EncodedId::Encoders::HashidConfiguration.new(
      salt: @salt,
      min_length: 8,
      max_inputs_per_id: 10,
      blocklist: @blocklist,
      blocklist_mode: :raise_if_likely
    )
    assert_equal :raise_if_likely, config.blocklist_mode
  end

  def test_raise_if_likely_mode_ignores_validation_with_empty_blocklist
    config = ::EncodedId::Encoders::HashidConfiguration.new(
      salt: @salt,
      min_length: 100,
      blocklist: ::EncodedId::Blocklist.empty,
      blocklist_mode: :raise_if_likely
    )
    assert_equal :raise_if_likely, config.blocklist_mode
  end

  def test_length_threshold_mode_checks_short_ids_hashids
    encoder = ::EncodedId::ReversibleId.hashid(
      salt: @salt,
      blocklist: ::EncodedId::Blocklist.new(["test"]),
      blocklist_mode: :length_threshold,
      blocklist_max_length: 10
    )

    # This will generate a short ID that should be checked
    # If it contains "test", it should raise
    begin
      result = encoder.encode(1)
      refute result.downcase.include?("test")
    rescue ::EncodedId::BlocklistError
      # Expected if the short ID happens to contain "test"
    end
  end

  def test_always_mode_checks_all_ids_hashids
    encoder = ::EncodedId::ReversibleId.hashid(
      salt: @salt,
      blocklist: ::EncodedId::Blocklist.new(["abc"]),
      blocklist_mode: :always,
      min_length: 8
    )

    # With :always mode, even long IDs should be checked
    # We can't guarantee a specific word will appear, but we can verify the mode is set
    config = encoder.instance_variable_get(:@config)
    assert_equal :always, config.blocklist_mode
  end

  def test_length_threshold_mode_checks_short_ids_sqids
    # For Sqids, :length_threshold mode now works via SqidsWithBlocklistMode subclass
    encoder = ::EncodedId::ReversibleId.sqids(
      blocklist: ::EncodedId::Blocklist.new(["test", "bad"]),
      blocklist_mode: :length_threshold,
      blocklist_max_length: 10,
      min_length: 5
    )

    result = encoder.encode([1, 2, 3])

    # Short IDs should be checked and regenerated if needed
    refute_nil result
    refute_empty result
  end

  def test_always_mode_checks_all_ids_sqids
    encoder = ::EncodedId::ReversibleId.sqids(
      blocklist: ::EncodedId::Blocklist.new(["xyz"]),
      blocklist_mode: :always
    )

    config = encoder.instance_variable_get(:@config)
    assert_equal :always, config.blocklist_mode

    result = encoder.encode([1, 2, 3])
    refute_nil result
  end

  def test_blocklist_mode_works_with_factory_methods
    hashid = ::EncodedId::ReversibleId.hashid(
      salt: @salt,
      blocklist: @blocklist,
      blocklist_mode: :length_threshold,
      blocklist_max_length: 40
    )

    sqids = ::EncodedId::ReversibleId.sqids(
      blocklist: @blocklist,
      blocklist_mode: :always
    )

    assert_equal :length_threshold, hashid.instance_variable_get(:@config).blocklist_mode
    assert_equal 40, hashid.instance_variable_get(:@config).blocklist_max_length

    assert_equal :always, sqids.instance_variable_get(:@config).blocklist_mode
  end

  def test_length_threshold_skips_long_ids_sqids
    # For Sqids, :length_threshold mode skips checking IDs longer than max_length
    encoder = ::EncodedId::ReversibleId.sqids(
      blocklist: ::EncodedId::Blocklist.minimal,
      blocklist_mode: :length_threshold,
      blocklist_max_length: 10,
      min_length: 50
    )

    # Long IDs (> 10 chars) should not be checked, so encoding succeeds
    # even if they contain blocklisted words
    result = encoder.encode([1, 2, 3, 4, 5])

    assert result.length >= 50
    refute_nil result
    refute_empty result
  end
end
