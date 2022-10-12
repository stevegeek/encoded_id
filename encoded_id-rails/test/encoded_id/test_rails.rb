# frozen_string_literal: true

require "test_helper"

class EncodedId::TestRails < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::Rails::VERSION
  end

  def test_it_does_something_useful
    m = MyModel.create(foo: "bar", bar: 123.5)
    assert m.persisted?
    asset_equal "bar", m.encoded_id
  end
end
