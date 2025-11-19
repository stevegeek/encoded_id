# frozen_string_literal: true

require "encoded_id"
require "hashids"
require "memory_profiler"

# Store memory results for the summary table
memory_results = {}

def run_memory_test(title, implementation, action, input)
  puts "\n#{implementation}:\n---------"
  report = MemoryProfiler.report do
    action.call(input)
  end

  report.pretty_print

  # Return the report data
  {
    total_allocated: report.total_allocated_memsize,
    total_retained: report.total_retained_memsize,
    allocated_objects: report.total_allocated,
    retained_objects: report.total_retained
  }
end

my_salt = "salt!"

hashids_lib = ::Hashids.new(my_salt)
hashid_encoder = ::EncodedId::ReversibleId.hashid(salt: my_salt, max_inputs_per_id: 100, max_length: 1000)
sqids_encoder = ::EncodedId::ReversibleId.sqids(max_inputs_per_id: 100, max_length: 1000)

# Small input test
puts "\n\n\n------#encode small input -------"
input = [1235, 12]

memory_results["encode small input"] = {
  "Hashids" => run_memory_test("Hashids Lib", "Hashids", ->(i) { hashids_lib.encode(*i) }, input),
  "EncodedId::ReversibleId (hashids)" => run_memory_test("EncodedId hashids", "EncodedId::ReversibleId (hashids)", ->(i) { hashid_encoder.encode(i) }, input),
  "EncodedId::ReversibleId (sqids)" => run_memory_test("EncodedId sqids", "EncodedId::ReversibleId (sqids)", ->(i) { sqids_encoder.encode(i) }, input)
}

# Large input test
puts "\n\n\n------#encode large input -------"
input = 100.times.map { rand(1000) }.freeze

memory_results["encode large input"] = {
  "Hashids" => run_memory_test("Hashids Lib", "Hashids", ->(i) { hashids_lib.encode(*i) }, input),
  "EncodedId::ReversibleId (hashids)" => run_memory_test("EncodedId hashids", "EncodedId::ReversibleId (hashids)", ->(i) { hashid_encoder.encode(i) }, input),
  "EncodedId::ReversibleId (sqids)" => run_memory_test("EncodedId sqids", "EncodedId::ReversibleId (sqids)", ->(i) { sqids_encoder.encode(i) }, input)
}

# Decode tests
puts "\n\n\n------#decode tests -------"

# Generate encoded strings for decode tests
hashids_encoded = hashids_lib.encode(*input)
hashid_encoded = hashid_encoder.encode(input)
sqids_encoded = sqids_encoder.encode(input)

memory_results["decode test"] = {
  "Hashids" => run_memory_test("Hashids Lib", "Hashids", ->(i) { hashids_lib.decode(i) }, hashids_encoded),
  "EncodedId::ReversibleId (hashids)" => run_memory_test("EncodedId hashids", "EncodedId::ReversibleId (hashids)", ->(i) { hashid_encoder.decode(i) }, hashid_encoded),
  "EncodedId::ReversibleId (sqids)" => run_memory_test("EncodedId sqids", "EncodedId::ReversibleId (sqids)", ->(i) { sqids_encoder.decode(i) }, sqids_encoded)
}

# Print a summary table of all memory results
def print_summary_table(memory_results)
  puts "\n\n"
  puts "# MEMORY USAGE SUMMARY TABLE:"
  puts "-" * 120

  # Print header
  puts "| Test                | Implementation              | Allocated Memory | Retained Memory | Allocated Objects | Retained Objects |"
  puts "| ------------------- | --------------------------- | ---------------- | --------------- | ----------------- | ---------------- |"

  # Print each result row
  memory_results.each do |title, implementations|
    first_row = true

    implementations.each do |impl_name, data|
      # Print the test title only for the first implementation
      test_col = first_row ? title.ljust(19) : " ".ljust(19)

      puts "| #{test_col} | #{impl_name.ljust(27)} | #{format_bytes(data[:total_allocated]).rjust(16)} | #{format_bytes(data[:total_retained]).rjust(15)} | #{data[:allocated_objects].to_s.rjust(17)} | #{data[:retained_objects].to_s.rjust(16)} |"

      first_row = false
    end

    # Add separator between tests
    puts "| #{"-" * 19} | #{"-" * 27} | #{"-" * 16} | #{"-" * 15} | #{"-" * 17} | #{"-" * 16} |"
  end

  puts "-" * 120
end

# Format bytes with KB/MB suffix
def format_bytes(bytes)
  if bytes < 1024
    "#{bytes} B"
  elsif bytes < 1024 * 1024
    format("%.2f KB", bytes / 1024.0)
  else
    format("%.2f MB", bytes / (1024.0 * 1024.0))
  end
end

# Print the summary table at the end
print_summary_table(memory_results)
