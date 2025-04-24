# frozen_string_literal: true

require "benchmark/ips"
require "encoded_id"

class OldImplementation
  attr_reader :split_at, :split_with

  def initialize(split_at, split_with)
    @split_at = split_at
    @split_with = split_with
  end

  def split_regex
    @split_regex ||= /.{#{split_at}}(?=.)/
  end

  def humanize_length(hash)
    hash.gsub(split_regex, "\\0#{split_with}")
  end
end

class NewImplementation
  attr_reader :split_at, :split_with

  def initialize(split_at, split_with)
    @split_at = split_at
    @split_with = split_with
  end

  def humanize_length(hash)
    len = hash.length
    return hash if len <= split_at

    separator_count = (len - 1) / split_at
    result = hash.dup # Start with a copy
    insert_offset = 0
    (1..separator_count).each do |i|
      insert_pos = i * split_at + insert_offset
      result.insert(insert_pos, split_with)
      insert_offset += split_with.length
    end
    result
  end
end

# Sample input strings of different lengths
short_string = "abcdefgh"
medium_string = "abcdefghijklmnopqrstuvwxyz"
long_string = "abcdefghijklmnopqrstuvwxyz" * 10

split_at = 4
split_with = "-"

old_impl = OldImplementation.new(split_at, split_with)
new_impl = NewImplementation.new(split_at, split_with)

# Verify both implementations produce identical results
[short_string, medium_string, long_string].each do |str|
  old_result = old_impl.humanize_length(str)
  new_result = new_impl.humanize_length(str)
  if old_result != new_result
    puts "ERROR: Results don't match for '#{str}':"
    puts "  Old: '#{old_result}'"
    puts "  New: '#{new_result}'"
    exit 1
  end
end

puts "Benchmarking with split_at=#{split_at}, split_with='#{split_with}'"

Benchmark.ips do |x|
  x.report("Old Short") { old_impl.humanize_length(short_string) }
  x.report("New Short") { new_impl.humanize_length(short_string) }

  x.report("Old Medium") { old_impl.humanize_length(medium_string) }
  x.report("New Medium") { new_impl.humanize_length(medium_string) }

  x.report("Old Long") { old_impl.humanize_length(long_string) }
  x.report("New Long") { new_impl.humanize_length(long_string) }

  x.compare!
end
