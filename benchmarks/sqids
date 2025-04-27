#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require "vernier"
require "benchmark/ips"
require "benchmark/memory"

require_relative "../lib/encoded_id/encoders/my_sqids"

if ARGV.include?("--yjit")
  RubyVM::YJIT.enable
end

def run_check(title, &block)
  puts "\n\n# #{title}:"
  puts "-------------------\n\n"

  Benchmark.ips(time: 3, warmup: 1, &block)
  puts "\n\n## Memory:\n\n"
  Benchmark.memory(&block)
end

def assert(condition, message = "")
  raise "Assert failed! #{message}" unless condition
end

one_value = [5].freeze
two_values = 2.times.map { rand(1000) }.freeze
ten_values = 10.times.map { rand(1000) }.freeze
one_hundred_values = 100.times.map { rand(1000) }.freeze
one_thousand_values = 1000.times.map { rand(1000) }.freeze

large_value = [MySqids.max_value]
ten_large_values = large_value * 10

Vernier.start_profile(out: "time_profile.json", interval: 500, allocation_interval: 200)

run_check("Default encoder: input sizes") do |x|
  sqids_default = MySqids.new(blocklist: [])

  x.report("1 value") { sqids_default.encode(one_value) }
  x.report("2 values") { sqids_default.encode(two_values) }
  x.report("10 values") { sqids_default.encode(ten_values) }
  x.report("100 values") { sqids_default.encode(one_hundred_values) }
  x.report("1000 values") { sqids_default.encode(one_thousand_values) }
  x.report("1 max value") { sqids_default.encode(large_value) }
  x.report("2 max values") { sqids_default.encode(ten_large_values[..1]) }
  x.report("10 max values") { sqids_default.encode(ten_large_values) }

  x.compare!
end

Vernier.stop_profile

run_check("Min length comparison: default vs other lengths") do |x|
  sqids_default = MySqids.new # 0
  sqids_custom_5 = MySqids.new(min_length: 5)
  sqids_custom_10 = MySqids.new(min_length: 10)
  sqids_custom_100 = MySqids.new(min_length: 100)

  id = sqids_custom_5.encode(one_value)
  assert id.size == 5, "#{one_value} => '#{id}' should be 5 in length"
  id = sqids_custom_10.encode(one_value)
  assert id.size == 10, "#{one_value} => '#{id}' should be 10 in length"
  id = sqids_custom_100.encode(one_value)
  assert id.size == 100, "#{one_value} => '#{id}' should be 100 in length"

  x.report("min_length 0, 1 value") { sqids_default.encode(one_value) }
  x.report("min_length 0, 100 values") { sqids_default.encode(one_hundred_values) }
  x.report("min_length 5, 1 value") { sqids_custom_5.encode(one_value) }
  x.report("min_length 5, 100 values") { sqids_custom_5.encode(one_hundred_values) }
  x.report("min_length 10, 1 value") { sqids_custom_10.encode(one_value) }
  x.report("min_length 10, 100 values") { sqids_custom_10.encode(one_hundred_values) }
  x.report("min_length 100, 1 value") { sqids_custom_100.encode(one_value) }
  x.report("min_length 100, 100 values") { sqids_custom_100.encode(one_hundred_values) }

  x.compare!
end

run_check("Alphabet comparison: default vs custom smaller alphabet") do |x|
  sqids_default = MySqids.new
  sqids_custom = MySqids.new(alphabet: "1234567890abcdef")

  x.report("default alphabet") { sqids_default.encode(one_hundred_values) }
  x.report("custom alphabet") { sqids_custom.encode(one_hundred_values) }

  x.compare!
end

run_check("Blocklist comparison, default vs no blocklist") do |x|
  sqids_no_blocklist = MySqids.new(blocklist: [])
  sqids_with_blocklist = MySqids.new

  x.report("no blocklist, 1 values") { sqids_no_blocklist.encode(one_value) }
  x.report("with blocklist, 1 value") { sqids_with_blocklist.encode(one_value) }
  x.report("no blocklist, 10 values") { sqids_no_blocklist.encode(ten_values) }
  x.report("with blocklist, 10 values") { sqids_with_blocklist.encode(ten_values) }
  x.report("no blocklist, 100 values") { sqids_no_blocklist.encode(one_hundred_values) }
  x.report("with blocklist, 100 values") { sqids_with_blocklist.encode(one_hundred_values) }
  x.report("no blocklist, 10 max values") { sqids_no_blocklist.encode(ten_large_values) }
  x.report("with blocklist, 10 max values") { sqids_with_blocklist.encode(ten_large_values) }

  x.compare!
end
