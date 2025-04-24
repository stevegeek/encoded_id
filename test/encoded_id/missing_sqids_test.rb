# frozen_string_literal: true

require "test_helper"

# This test verifies that ReversibleId correctly checks for the availability
# of the Sqids encoder before attempting to use it
class MissingSqidsTest < Minitest::Test
  def test_raises_meaningful_error_when_sqids_not_found
    self.class.const_set(:NewClass, ::EncodedId::Encoders::Sqids)
    ::EncodedId::Encoders.send(:remove_const, :Sqids)
    assert_raises(::EncodedId::InvalidConfigurationError) do
      ::EncodedId::ReversibleId.new(salt: "test_salt_12345", encoder: :sqids)
    end
  ensure
    ::EncodedId::Encoders.const_set(:Sqids, NewClass)
    self.class.send(:remove_const, :NewClass) if defined?(NewClass)
  end

  def test_default_hashids_works_regardless
    # Should always work with the default hashids encoder
    coder = ::EncodedId::ReversibleId.new(salt: "test_salt_12345")
    encoded = coder.encode(123)
    refute_nil encoded
    assert_equal [123], coder.decode(encoded)
  end
end
