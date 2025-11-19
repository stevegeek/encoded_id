# frozen_string_literal: true

# Configure SimpleCov if COVERAGE is set
if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov_small_badge"

  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch
    minimum_coverage 90

    # Define groups for the coverage report
    add_group "Core", "lib/encoded_id"
    add_group "Rails", "lib/encoded_id/rails"
    add_group "Generators", "lib/generators"
    add_group "Extension", "ext"

    # Configure formatters - HTML and Badge
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCovSmallBadge::Formatter
    ])
  end

  # Configure the badge
  SimpleCovSmallBadge.configure do |config|
    config.rounded_border = true
    config.background = "#ffffcc"
    config.output_path = "badges/"
  end

  # Output a message to indicate coverage is being measured
  puts "SimpleCov enabled with badge generation"
end

Dir.mkdir("test/tmp") unless Dir.exist?("test/tmp")

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"

# Conditionally load modules based on the test file being run
require "encoded_id"
require "encoded_id/rails"

ActiveRecord::Base.logger = Logger.new("test/tmp/test.log")
ActiveRecord::Base.logger.level = Logger::DEBUG

config = {
  adapter: "sqlite3",
  database: "test/tmp/test.db"
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

# Load Rails test support files
require_relative "support/config"
require_relative "support/schema"
require_relative "support/model"
require_relative "support/model_with_persisted_encoded_id"
require_relative "support/model_with_path_param"
require_relative "support/model_with_slugged_path_param"
require_relative "support/auto_path_param_model"
require_relative "support/sti_models"

require "minitest/autorun"
