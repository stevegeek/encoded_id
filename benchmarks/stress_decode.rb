# frozen_string_literal: true

require "benchmark/ips"
require "benchmark/memory"
require "encoded_id"

my_salt = "salt!"

# Test decode largest possible HTTP request param
hashid_coder = ::EncodedId::ReversibleId.new(salt: my_salt, max_length: 1_000_000, encoder: :hashids)
sqids_coder = ::EncodedId::ReversibleId.new(salt: my_salt, max_length: 1_000_000, encoder: :sqids)

# Puma by default allows path length is 8192
# Max URI length is 1024 * 12
# Max query length is 1024 * 10
# https://github.com/puma/puma/blob/master/docs/compile_options.md

# If too long Puma raises:
# > Puma caught this error: HTTP element REQUEST_PATH is longer than the (8192) allowed length (was 12503) (Puma::HttpParserError)

# These can be increased but assume they wont be. Take the worst case scenario:

typical_id_hashid = "aaaa-aaaa"
typical_id_sqids = "aaaa-aaaa"
long_id = "a" * 1_024 * 12

puts "\n\n# HashIds encoder stress test:"
puts "-------------------\n\n"

Benchmark.ips(time: 3, warmup: 1) do |x|
  x.report("hashids typical id") { hashid_coder.decode(typical_id_hashid) }
  x.report("hashids long id") { hashid_coder.decode(long_id) }

  x.compare!
end

puts "\n\n## Memory:\n\n"
Benchmark.memory do |x|
  x.report("hashids typical id") { hashid_coder.decode(typical_id_hashid) }
  x.report("hashids long id") { hashid_coder.decode(long_id) }
  x.compare!
end

puts "\n\n# Sqids encoder stress test:"
puts "-------------------\n\n"

Benchmark.ips(time: 3, warmup: 1) do |x|
  x.report("sqids typical id") { sqids_coder.decode(typical_id_sqids) }
  x.report("sqids long id") { sqids_coder.decode(long_id) }

  x.compare!
end

puts "\n\n## Memory:\n\n"
Benchmark.memory do |x|
  x.report("sqids typical id") { sqids_coder.decode(typical_id_sqids) }
  x.report("sqids long id") { sqids_coder.decode(long_id) }
  x.compare!
end
