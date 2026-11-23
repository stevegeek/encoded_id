# frozen_string_literal: true

require "benchmark/ips"
require "encoded_id"

A_SALT = "salt!"
LENGTH_SAMPLES = 1_000

def random_hex(random, digits)
  random.bytes((digits + 1) / 2).unpack1("H*")[0, digits]
end

def random_uuid(random)
  random_hex(random, 32).sub(/\A(.{8})(.{4})(.{4})(.{4})/, '\1-\2-\3-\4-')
end

INPUTS = {
  "1 UUID" => ->(random) { random_uuid(random) },
  "16 hex digits" => ->(random) { random_hex(random, 16) },
  "ObjectID (24 hex digits)" => ->(random) { random_hex(random, 24) },
  "2 UUIDs" => ->(random) { [random_uuid(random), random_uuid(random)] }
}.freeze

SCHEMES = {
  "legacy g=4" => {hex_encoding: :legacy, hex_digit_encoding_group_size: 4},
  "legacy g=8" => {hex_encoding: :legacy, hex_digit_encoding_group_size: 8},
  "legacy g=12" => {hex_encoding: :legacy, hex_digit_encoding_group_size: 12},
  "tagged" => {hex_encoding: :tagged}
}.freeze

ENCODERS = {
  "sqids" => ->(options) { EncodedId::ReversibleId.sqids(max_length: nil, **options) },
  "hashid" => ->(options) { EncodedId::ReversibleId.hashid(salt: A_SALT, max_length: nil, **options) }
}.freeze

def hex_digits(input)
  Array(input).map { |hex| hex.delete("-") }
end

def check_round_trip!(coder, input, id)
  return if coder.decode_hex(id) == hex_digits(input)

  raise "#{input.inspect} => #{id.inspect} did not decode to its input"
end

def report_lengths(encoder_name, coders)
  puts "\n\n# #{encoder_name}: ID length over #{LENGTH_SAMPLES} random inputs (min / mean / max, with separators)"
  puts "-------------------\n\n"
  puts "input".ljust(26) + coders.keys.map { |name| name.rjust(22) }.join

  INPUTS.each do |input_name, generator|
    random = Random.new(1234)
    inputs = Array.new(LENGTH_SAMPLES) { generator.call(random) }

    cells = coders.map do |_scheme_name, coder|
      lengths = inputs.map do |input|
        id = coder.encode_hex(input)
        check_round_trip!(coder, input, id)
        id.length
      end
      mean = lengths.sum.fdiv(lengths.size)
      format("%d / %.1f / %d", lengths.min, mean, lengths.max).rjust(22)
    end
    puts input_name.ljust(26) + cells.join
  end
end

def run_check(title, &block)
  puts "\n\n# #{title}:"
  puts "-------------------\n\n"

  Benchmark.ips(time: 3, warmup: 1) do |x|
    block.call(x)
    x.compare!
  end
end

ENCODERS.each do |encoder_name, build|
  coders = SCHEMES.transform_values { |options| build.call(options) }

  report_lengths(encoder_name, coders)

  INPUTS.each do |input_name, generator|
    input = generator.call(Random.new(42))
    ids = coders.transform_values { |coder| coder.encode_hex(input) }

    run_check("#{encoder_name} encode_hex: #{input_name}") do |x|
      coders.each { |scheme_name, coder| x.report(scheme_name) { coder.encode_hex(input) } }
    end

    run_check("#{encoder_name} decode_hex: #{input_name}") do |x|
      coders.each { |scheme_name, coder| x.report(scheme_name) { coder.decode_hex(ids[scheme_name]) } }
    end
  end
end
