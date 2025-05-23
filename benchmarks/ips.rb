# frozen_string_literal: true

require "benchmark/ips"
require "encoded_id"
require "hashids"

A_SALT = "salt!"

MAX_V = 1_000_000
benchmark_results = {}

def run_check(title, benchmark_results, &block)
  puts "\n\n# #{title}:"
  puts "-------------------\n\n"

  report = Benchmark.ips(time: 3, warmup: 1) do |x|
    block.call(x)
    x.compare!
  end

  # Store results for summary table
  benchmark_results[title] = report.entries.each_with_object({}) do |entry, hash|
    hash[entry.label] = entry.ips
  end
end

def encode_check(title, benchmark_results, size_of_id_collection = 10)
  run_check title, benchmark_results do |x|
    hashids = ::Hashids.new(A_SALT)
    hashids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :hashids, max_inputs_per_id: size_of_id_collection, max_length: 10_000)
    sqids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :sqids, max_inputs_per_id: size_of_id_collection, max_length: 10_000, blocklist: [])
    rand1 = Random.new(1234)

    prepared_inputs = size_of_id_collection.times.map { rand1.rand(MAX_V) }

    x.report("Hashids") { hashids.encode(*prepared_inputs) }
    x.report("EncodedId::ReversibleId (hashids)") { hashids_encoder.encode(prepared_inputs) }
    x.report("EncodedId::ReversibleId (sqids)") { sqids_encoder.encode(prepared_inputs) }

    x.compare!
  end
end

def decode_check(title, benchmark_results, size_of_id_collection = 10)
  run_check title, benchmark_results do |x|
    hashids = ::Hashids.new(A_SALT)
    hashids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :hashids, max_inputs_per_id: size_of_id_collection, max_length: 10_000)
    sqids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :sqids, max_inputs_per_id: size_of_id_collection, max_length: 10_000)
    rand1 = Random.new(1234)

    prepared_inputs = size_of_id_collection.times.map { rand1.rand(MAX_V) }
    hashids_string = hashids.encode(*prepared_inputs)
    hashids_encoder_string = hashids_encoder.encode(prepared_inputs)
    sqids_encoder_string = sqids_encoder.encode(prepared_inputs)

    x.report("Hashids") { hashids.decode(hashids_string) }
    x.report("EncodedId::ReversibleId (hashids)") { hashids_encoder.decode(hashids_encoder_string) }
    x.report("EncodedId::ReversibleId (sqids)") { sqids_encoder.decode(sqids_encoder_string) }

    x.compare!
  end
end

# Print a summary table of all benchmark results
def print_summary_table(benchmark_results)
  puts "\n\n"
  puts "# SUMMARY TABLE:"
  puts "-" * 110

  # Calculate the width needed for the title column
  title_width = [25, benchmark_results.keys.map(&:length).max].max

  # Print header
  puts "| #{"Test".ljust(title_width)} | Hashids gem (i/s) | EncodedId (hashids) (i/s) | EncodedId (sqids) (i/s) | Hashids vs Sqids |"
  puts "| #{"-" * title_width} | ------------ | ------------------------ | ----------------------- | --------------- |"

  # Print each result row
  benchmark_results.each do |title, results|
    hashids_ips = results["Hashids"] || 0
    hashids_encoded_id_ips = results["EncodedId::ReversibleId (hashids)"] || 0
    sqids_encoded_id_ips = results["EncodedId::ReversibleId (sqids)"] || 0

    # Calculate speedup of sqids compared to hashids
    speedup = (hashids_encoded_id_ips > 0) ? hashids_encoded_id_ips / sqids_encoded_id_ips : 0

    puts "| #{title.ljust(title_width)} | #{format_number(hashids_ips).rjust(12)} | #{format_number(hashids_encoded_id_ips).rjust(24)} | #{format_number(sqids_encoded_id_ips).rjust(23)} | #{format("%.2fx", speedup).rjust(15)} |"
  end

  puts "-" * 110
end

# Format a number with thousands separators
def format_number(number)
  whole, decimal = number.to_s.split(".")
  whole_with_commas = whole.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  decimal ? "#{whole_with_commas}.#{decimal[0..2]}" : whole_with_commas
end

# Check implementations generate expected results
hashids = ::Hashids.new(A_SALT)
hashids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :hashids)
sqids_encoder = ::EncodedId::ReversibleId.new(salt: A_SALT, encoder: :sqids)
rand1 = Random.new(1234)
inputs = 10.times.map { rand1.rand(MAX_V) }

# EncodedId takes an array directly, while hashids gem takes varargs
hashids_encoded = hashids.encode(*inputs)
hashids_encoder_encoded = hashids_encoder.encode(inputs)
sqids_encoded = sqids_encoder.encode(inputs)

puts "HashIds gem: #{hashids_encoded}"
puts "EncodedId (hashids): #{hashids_encoder_encoded}"
puts "EncodedId (sqids): #{sqids_encoded}"

# Verify decoding
hashids_decoded = hashids.decode(hashids_encoded)
hashids_encoder_decoded = hashids_encoder.decode(hashids_encoder_encoded)
sqids_decoded = sqids_encoder.decode(sqids_encoded)

puts "\nDecoded values match:" if hashids_decoded == hashids_encoder_decoded.map(&:to_i) &&
  inputs == sqids_decoded

##########

raise "Turn off YJIT please" if defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enable) && RubyVM::YJIT.enabled?

encode_check("#encode - 1 ID", benchmark_results, 1)
decode_check("#decode - 1 ID", benchmark_results, 1)
encode_check("#encode - 10 IDs", benchmark_results, 10)
decode_check("#decode - 10 IDs", benchmark_results, 10)

if defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enable) && !RubyVM::YJIT.enabled?
  RubyVM::YJIT.enable

  encode_check("#encode w YJIT - 1 ID", benchmark_results, 1)
  decode_check("#decode w YJIT - 1 ID", benchmark_results, 1)
  encode_check("#encode w YJIT - 10 IDs", benchmark_results, 10)
  decode_check("#decode w YJIT - 10 IDs", benchmark_results, 10)
  encode_check("#encode w YJIT - 1000 IDs", benchmark_results, 1_000)
  decode_check("#decode w YJIT - 1000 IDs", benchmark_results, 1_000)
end

# Print the summary table at the end
print_summary_table(benchmark_results)
