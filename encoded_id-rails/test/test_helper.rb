# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "encoded_id/rails"

require "minitest/autorun"

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
