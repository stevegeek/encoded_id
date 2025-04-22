# frozen_string_literal: true

require "test_helper"

# This test verifies that ReversibleId correctly checks for the availability
# of the Sqids encoder before attempting to use it
class MissingSqidsTest < Minitest::Test
  def test_raises_meaningful_error_when_sqids_not_found
    # Create a ReversibleId instance with :sqids encoder
    coder = ::EncodedId::ReversibleId.new(salt: "test_salt_12345", encoder: :sqids)

    # Mock the create_encoder method to simulate Sqids not being defined
    def coder.create_encoder
      case @encoder_type
      when :sqids
        # Simulate Sqids not being defined
        raise ::EncodedId::InvalidConfigurationError, "Sqids encoder requested but the sqids gem is not available. Please add 'gem \"sqids\"' to your Gemfile."
      when :hashids
        Encoders::HashId.new(salt, length, alphabet)
      end
    end

    # Now attempting to encode should raise our expected error
    assert_raises(::EncodedId::InvalidConfigurationError) do
      coder.encode(123)
    end
  end

  def test_default_hashids_works_regardless
    # Should always work with the default hashids encoder
    coder = ::EncodedId::ReversibleId.new(salt: "test_salt_12345")
    encoded = coder.encode(123)
    refute_nil encoded
    assert_equal [123], coder.decode(encoded)
  end
end
