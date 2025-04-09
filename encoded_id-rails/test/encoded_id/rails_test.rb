# frozen_string_literal: true

require "test_helper"

class EncodedId::RailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::Rails::VERSION
  end
end