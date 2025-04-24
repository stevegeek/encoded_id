# frozen_string_literal: true

require "benchmark/ips"
require "benchmark/memory"
require_relative "../lib/encoded_id"
require "sqids"
require_relative "../sqids_optimise/my_sqids"

def run_check(title, &block)
  puts "\n\n# #{title}:"
  puts "-------------------\n\n"

  Benchmark.ips(time: 3, warmup: 1, &block)
  puts "\n\n## Memory:\n\n"
  Benchmark.memory(&block)
end

my_salt = "salt!"

run_check("Encoder comparison") do |x|
  hashid_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :hashids)
  sqids_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :sqids)
  my_sqids_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :my_sqids)

  x.report("hashids encoder") { hashid_coder.encode([78, 45]) }
  x.report("sqids encoder") { sqids_coder.encode([78, 45]) }
  x.report("my_sqids encoder") { my_sqids_coder.encode([78, 45]) }

  x.compare!
end

run_check("Encoder decode comparison") do |x|
  hashid_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :hashids)
  sqids_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :sqids)
  my_sqids_coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :my_sqids)

  hashid_encoded = hashid_coder.encode([78, 45])
  sqids_encoded = sqids_coder.encode([78, 45])

  x.report("hashids decode") { hashid_coder.decode(hashid_encoded) }
  x.report("sqids decode") { sqids_coder.decode(sqids_encoded) }
  x.report("my_sqids decode") { my_sqids_coder.decode(sqids_encoded) }

  x.compare!
end

# Run the following if -v is passed to script
if ARGV.include?("-v")
  run_check("Longer alphabets are slower") do |x|
    coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :hashids)
    coder2 = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: ::EncodedId::Alphabet.new("1234567890abcdef"), split_with: "x", encoder: :hashids)

    x.report("default alphabet") { coder.encode([78, 45]) }
    x.report("custom alphabet") { coder2.encode([78, 45]) }

    x.compare!
  end

  run_check("Character mappings are slower") do |x|
    coder = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: ::EncodedId::Alphabet.new("1234567890abcdef"), encoder: :hashids)
    coder2 = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: ::EncodedId::Alphabet.new("1234567890abcdef", {"~" => "b", "x" => "d", "y" => "e", "z" => "f"}), encoder: :hashids)
    # b4e5-15eb

    x.report("alphabet") { coder.decode("b4e5-15eb") }
    x.report("alphabet with mappings") { coder2.decode("~4y5-15yb") }

    x.compare!
  end

  run_check("Longer salts don't change much") do |x|
    coder = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :hashids)
    coder2 = ::EncodedId::ReversibleId.new(salt: "a" * 100, encoder: :hashids)

    x.report("default salt") { coder.encode([78, 45]) }
    x.report("longer salt") { coder2.encode([78, 45]) }

    x.compare!
  end

  run_check("Split at vs no split") do |x|
    coder = ::EncodedId::ReversibleId.new(salt: my_salt, split_at: 4, split_with: "-", encoder: :hashids)
    coder2 = ::EncodedId::ReversibleId.new(salt: my_salt, split_at: 2, split_with: "-", encoder: :hashids)
    coder3 = ::EncodedId::ReversibleId.new(salt: my_salt, split_at: nil, encoder: :hashids)

    x.report("split at 4") { coder.encode([78, 45]) }
    x.report("split at 2") { coder2.encode([78, 45]) }
    x.report("no split") { coder3.encode([78, 45]) }

    x.compare!
  end

  run_check("target length") do |x|
    coder = ::EncodedId::ReversibleId.new(salt: my_salt, length: 8, encoder: :hashids)
    coder2 = ::EncodedId::ReversibleId.new(salt: my_salt, length: 16, encoder: :hashids)
    coder3 = ::EncodedId::ReversibleId.new(salt: my_salt, length: 32, encoder: :hashids)

    x.report("length 8") { coder.encode([78, 45]) }
    x.report("length 16") { coder2.encode([78, 45]) }
    x.report("length 32") { coder3.encode([78, 45]) }

    x.compare!
  end

  # Sqids specific benchmarks
  run_check("Sqids: Alphabet comparison") do |x|
    sqids_default = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :sqids)
    sqids_custom = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: ::EncodedId::Alphabet.new("1234567890abcdef"), encoder: :sqids)

    x.report("sqids default alphabet") { sqids_default.encode([78, 45]) }
    x.report("sqids custom alphabet") { sqids_custom.encode([78, 45]) }

    x.compare!
  end

  run_check("Sqids: Blocklist comparison") do |x|
    sqids_no_blocklist = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :sqids)
    sqids_with_blocklist = ::EncodedId::ReversibleId.new(salt: my_salt, encoder: :sqids, blocklist: ["bad", "word"])

    x.report("sqids no blocklist") { sqids_no_blocklist.encode([78, 45]) }
    x.report("sqids with blocklist") { sqids_with_blocklist.encode([78, 45]) }

    x.compare!
  end
end
