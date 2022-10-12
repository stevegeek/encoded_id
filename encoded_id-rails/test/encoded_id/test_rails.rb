# frozen_string_literal: true

require "test_helper"

class EncodedId::TestRails < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::Rails::VERSION
  end

  attr_reader :m

  def setup
    @m = MyModel.create
  end

  # find_by_encoded_id(slugged_encoded_id, with_id: nil)
  def test_find_by_encoded_id_gets_model_given_encoded_id
    assert_equal m, MyModel.find_by_encoded_id(m.encoded_id)
  end

  def test_find_by_encoded_id_gets_model_given_encoded_id_with_slug
    assert_equal m, MyModel.find_by_encoded_id("my-cool-slug--#{m.encoded_id}")
  end

  def test_find_by_encoded_id_gets_model_given_encoded_id_with_id_constraint
    assert_equal m, MyModel.find_by_encoded_id(m.encoded_id, with_id: m.id)
  end

  def test_find_by_encoded_id_returns_nil_if_no_model_found_for_encoded_id
    assert_nil MyModel.find_by_encoded_id("aaaa-aaaa")
  end

  def test_find_by_encoded_id_returns_nil_if_encoded_id_unhashable
    assert_nil MyModel.find_by_encoded_id("aa%%aaaa")
  end

  def test_find_by_encoded_id_returns_nil_if_constraint_not_met
    assert_nil MyModel.find_by_encoded_id(m.encoded_id, with_id: 12345)
  end

  # find_by_encoded_id!(slugged_encoded_id, with_id: nil)
  def test_find_by_encoded_id_bang_gets_model_given_encoded_id
    assert_equal m, MyModel.find_by_encoded_id!(m.encoded_id)
  end

  def test_find_by_encoded_id_bang_gets_model_given_encoded_id_with_id_constraint
    assert_equal m, MyModel.find_by_encoded_id!(m.encoded_id, with_id: m.id)
  end

  def test_find_by_encoded_id_bang_raises_if_no_model_found_for_encoded_id
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!("aaaa-aaaa")
    end
  end

  def test_find_by_encoded_id_bang_raises_if_encoded_id_unhashable
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!("aa%%%aaa")
    end
  end

  def test_find_by_encoded_id_bang_raises_if_constraint_not_met
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!(m.encoded_id, with_id: 12345)
    end
  end

  # find_by_fixed_slug(slug, attribute: :slug, with_id: nil)
  # find_by_fixed_slug!(slug, attribute: :slug, with_id: nil)
  # find_by_slugged_id(slugged_id, with_id: nil)
  # find_by_slugged_id!(slugged_id, with_id: nil)

  # where_encoded_id(slugged_encoded_id)
  # where_fixed_slug(slug, attribute: :slug)
  # where_slugged_id(slugged_id)

  # encode_encoded_id(id, options = {})
  # encode_multi_encoded_id(encoded_ids, options = {})
  # decode_encoded_id(slugged_encoded_id, options = {})
  # decode_multi_encoded_id(slugged_encoded_id, options = {})
  # decode_slugged_id(slugged)
  # decode_slugged_ids(slugged)

  # encoded_id_salt

  # Instance methods
  # encoded_id
  def test_it_gets_encoded_id_for_model
    m = MyModel.create
    assert m.persisted?
    eid = ::EncodedId::ReversibleId.new(salt: MyModel.encoded_id_salt).encode(m.id)
    assert_equal eid, m.encoded_id
  end

  # slugged_encoded_id(with: :slug)
  # slugged_id(with: :slug)
  # slug
end
