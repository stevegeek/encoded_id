# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::ActiveRecordFindersTest < Minitest::Test
  class ActiveRecordModel < MyModel
    include EncodedId::Rails::ActiveRecordFinders
  end

  def setup
    @original_config = EncodedId::Rails.configuration
    # Clean all records from my_models table (used by both MyModel and ActiveRecordModel)
    MyModel.delete_all
    @models = 3.times.map { ActiveRecordModel.create }
    @standard_model = MyModel.create
  end

  def teardown
    # Clean all records from my_models table
    MyModel.delete_all
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_find_with_encoded_id
    model = @models.first
    encoded_id = model.encoded_id

    found = ActiveRecordModel.find(encoded_id)
    assert_equal model.id, found.id

    found = ActiveRecordModel.find(model.id)
    assert_equal model.id, found.id
  end

  def test_find_with_invalid_encoded_id
    assert_raises ActiveRecord::RecordNotFound do
      ActiveRecordModel.find("invalid-id")
    end
  end

  def test_find_with_multiple_encoded_ids
    ids = @models.map(&:id)
    encoded_ids = ActiveRecordModel.encode_encoded_id(ids)

    found = ActiveRecordModel.find(encoded_ids)
    assert_equal ids.size, found.size
    assert_equal ids.sort, found.map(&:id).sort
  end

  def test_find_by_id_with_encoded_id
    model = @models.first
    encoded_id = model.encoded_id

    found = ActiveRecordModel.find_by_id(encoded_id)
    assert_equal model.id, found.id

    found = ActiveRecordModel.find_by_id(model.id)
    assert_equal model.id, found.id

    found = ActiveRecordModel.find_by_id("invalid-id")
    assert_nil found
  end

  def test_find_by_id_with_integer_id
    model = @models.first
    # Explicitly pass an integer to ensure we hit the non-String path
    found = ActiveRecordModel.find_by_id(model.id.to_i)
    assert_equal model.id, found.id
  end
end
