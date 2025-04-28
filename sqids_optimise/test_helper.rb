# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/lib/encoded_id/encoders/sqids"
  add_group "MySqids", "lib/encoded_id/encoders/my_sqids"
end

require "minitest/autorun"
require "sqids"
require_relative "../lib/encoded_id/encoders/my_sqids"
