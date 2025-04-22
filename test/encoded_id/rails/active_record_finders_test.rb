# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::ActiveRecordFindersTest < Minitest::Test
  class ActiveRecordModel < MyModel
    include EncodedId::Rails::ActiveRecordFinders
  end

  def setup
    # Store the original configuration
    @original_config = EncodedId::Rails.configuration
    # Create test models
    @models = 3.times.map { ActiveRecordModel.create }
    # Create a model with standard finder methods
    @standard_model = MyModel.create
  end

  def teardown
    # Restore original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_find_with_encoded_id
    model = @models.first
    encoded_id = model.encoded_id

    # Test finding with encoded ID
    found = ActiveRecordModel.find(encoded_id)
    assert_equal model.id, found.id

    # Test finding with non-encoded ID (original behavior)
    found = ActiveRecordModel.find(model.id)
    assert_equal model.id, found.id
  end

  def test_find_with_invalid_encoded_id
    assert_raises ActiveRecord::RecordNotFound do
      ActiveRecordModel.find("invalid-id")
    end
  end

  def test_find_with_multiple_encoded_ids
    # Encode multiple IDs
    ids = @models.map(&:id)
    encoded_ids = ActiveRecordModel.encode_encoded_id(ids)

    # Test finding with encoded IDs containing multiple IDs
    found = ActiveRecordModel.find(encoded_ids)
    assert_equal ids.size, found.size
    assert_equal ids.sort, found.map(&:id).sort
  end

  def test_find_by_id_with_encoded_id
    model = @models.first
    encoded_id = model.encoded_id

    # Test find_by_id with encoded ID
    found = ActiveRecordModel.find_by_id(encoded_id)
    assert_equal model.id, found.id

    # Test find_by_id with non-encoded ID (original behavior)
    found = ActiveRecordModel.find_by_id(model.id)
    assert_equal model.id, found.id

    # Test find_by_id with invalid encoded ID
    found = ActiveRecordModel.find_by_id("invalid-id")
    assert_nil found
  end
end
