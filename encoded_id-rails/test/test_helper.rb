# frozen_string_literal: true

# Configure SimpleCov if COVERAGE is set
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch

    # Define groups for the coverage report
    add_group "Core", "lib/encoded_id/rails"
    add_group "Generators", "lib/generators"
  end

  # Output a message to indicate coverage is being measured
  puts "SimpleCov enabled"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "encoded_id/rails"

require "minitest/autorun"
require "rails"
require "rails/generators"

# Thanks to https://github.com/zdennis/activerecord-import/tree/master/test for the config here
require "active_record"

ActiveRecord::Base.logger = Logger.new("test.log")
ActiveRecord::Base.logger.level = Logger::DEBUG

config = {
  adapter: "sqlite3",
  database: "test.db"
}
db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "sqlite3", config)
ActiveRecord::Base.configurations.configurations << db_config

if ActiveRecord.respond_to?(:default_timezone)
  ActiveRecord.default_timezone = :utc
else
  ActiveRecord::Base.default_timezone = :utc
end

ActiveRecord::Base.establish_connection :test

ActiveSupport::Notifications.subscribe(/active_record.sql/) do |_, _, _, _, hsh|
  ActiveRecord::Base.logger.info hsh[:sql]
end

require_relative "support/config"
require_relative "support/schema"
require_relative "support/model"
require_relative "support/model_with_persisted_encoded_id"
require_relative "support/model_with_path_param"
require_relative "support/model_with_slugged_path_param"
require_relative "support/auto_path_param_model"
