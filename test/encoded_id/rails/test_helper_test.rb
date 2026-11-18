# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::TestHelperTest < Minitest::Test
  include EncodedId::Rails::TestHelper

  def test_with_encoded_id_configuration_applies_overrides_and_returns_the_block_value
    previous = EncodedId::Rails.configuration

    result = with_encoded_id_configuration(id_length: 12) do
      assert_predicate EncodedId::Rails.configuration, :frozen?
      EncodedId::Rails.configuration.id_length
    end

    assert_equal 12, result
    assert_same previous, EncodedId::Rails.configuration
  end

  def test_with_encoded_id_configuration_restores_the_previous_configuration_after_an_error
    previous = EncodedId::Rails.configuration

    assert_raises(RuntimeError) do
      with_encoded_id_configuration(id_length: 12) { raise "boom" }
    end

    assert_same previous, EncodedId::Rails.configuration
  end
end
