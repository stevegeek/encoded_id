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

  def test_warns_when_included_in_model_with_string_id
    # Capture warnings
    original_logger = ::Rails.logger

    # Create a custom logger that captures warnings
    logger = Object.new
    def logger.warn(message)
      @warnings ||= []
      @warnings << message
    end

    def logger.warnings
      @warnings ||= []
    end

    def logger.info(*)
    end

    def logger.debug(*)
    end

    def logger.error(*)
    end

    def logger.fatal(*)
    end

    ::Rails.logger = logger

    begin
      # Create a delegator that wraps a column but returns :string for type
      column_wrapper = Class.new do
        def initialize(column)
          @column = column
        end

        def type
          :string
        end

        def method_missing(method, *args, &block)
          @column.send(method, *args, &block)
        end

        def respond_to_missing?(method, include_private = false)
          @column.respond_to?(method, include_private) || super
        end
      end

      # Create a temporary model class that reports string ID
      string_id_model_class = Class.new(MyModel) do
        # Stub columns_hash to report string type for id column
        def self.columns_hash
          return @_stubbed_columns_hash if @_stubbed_columns_hash

          # Call super to get real columns, then wrap id column
          real_columns = super
          id_column = real_columns["id"]

          wrapper_class = const_get(:ColumnWrapper)
          stubbed_id_column = wrapper_class.new(id_column)

          @_stubbed_columns_hash = real_columns.merge("id" => stubbed_id_column)
        end

        def self.name
          "StringIdTestModel"
        end

        # Store the wrapper class in the model class
        const_set(:ColumnWrapper, column_wrapper)
      end

      string_id_model_class.include(EncodedId::Rails::ActiveRecordFinders)

      assert logger.warnings.any? { |msg|
        msg.include?("StringIdTestModel") &&
          msg.include?("string-based IDs") &&
          msg.include?("conflicts")
      }, "Expected warning about string-based IDs, got: #{logger.warnings.inspect}"

      refute logger.warnings.any? { |msg|
        msg.include?("no 'id' column")
      }, "Should not warn about missing id column"

      refute logger.warnings.any? { |msg|
        msg.include?("primary key is")
      }, "Should not warn about non-id primary key"
    ensure
      ::Rails.logger = original_logger
    end
  end

  def test_warns_when_included_in_model_without_id_column
    original_logger = ::Rails.logger
    logger = Object.new
    def logger.warn(message)
      @warnings ||= []
      @warnings << message
    end

    def logger.warnings
      @warnings ||= []
    end

    def logger.info(*)
    end

    def logger.debug(*)
    end

    def logger.error(*)
    end

    def logger.fatal(*)
    end

    ::Rails.logger = logger

    begin
      no_id_model_class = Class.new(MyModel) do
        def self.columns_hash
          super.except("id")
        end

        def self.name
          "NoIdColumnModel"
        end
      end

      no_id_model_class.include(EncodedId::Rails::ActiveRecordFinders)

      assert logger.warnings.any? { |msg|
        msg.include?("NoIdColumnModel") &&
          msg.include?("no 'id' column")
      }, "Expected warning about missing id column, got: #{logger.warnings.inspect}"

      refute logger.warnings.any? { |msg|
        msg.include?("string-based IDs")
      }, "Should not warn about string-based IDs"

      refute logger.warnings.any? { |msg|
        msg.include?("primary key is")
      }, "Should not warn about non-id primary key"
    ensure
      ::Rails.logger = original_logger
    end
  end

  def test_warns_when_included_in_model_with_non_id_primary_key
    original_logger = ::Rails.logger
    logger = Object.new
    def logger.warn(message)
      @warnings ||= []
      @warnings << message
    end

    def logger.warnings
      @warnings ||= []
    end

    def logger.info(*)
    end

    def logger.debug(*)
    end

    def logger.error(*)
    end

    def logger.fatal(*)
    end

    ::Rails.logger = logger

    begin
      non_id_pk_model_class = Class.new(MyModel) do
        self.primary_key = "name"

        def self.name
          "NonIdPrimaryKeyModel"
        end
      end

      non_id_pk_model_class.include(EncodedId::Rails::ActiveRecordFinders)

      assert logger.warnings.any? { |msg|
        msg.include?("NonIdPrimaryKeyModel") &&
          msg.include?("primary key is 'name'") &&
          msg.include?("unexpected behavior")
      }, "Expected warning about non-id primary key, got: #{logger.warnings.inspect}"

      refute logger.warnings.any? { |msg|
        msg.include?("string-based IDs")
      }, "Should not warn about string-based IDs"

      refute logger.warnings.any? { |msg|
        msg.include?("no 'id' column")
      }, "Should not warn about missing id column"
    ensure
      ::Rails.logger = original_logger
    end
  end
end
