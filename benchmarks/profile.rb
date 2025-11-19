# frozen_string_literal: true

require "stackprof"
require "encoded_id"

A_SALT = "salt!"
NUM_IDS = 1000
NUM_ITERATIONS = 1000
MAX_V = 1_000_000

def setup_encoders
  hashids_encoder = ::EncodedId::ReversibleId.hashid(salt: A_SALT, max_inputs_per_id: NUM_IDS, max_length: 10_000)
  sqids_encoder = ::EncodedId::ReversibleId.sqids(max_inputs_per_id: NUM_IDS, max_length: 10_000)
  rand1 = Random.new(1234)
  inputs = NUM_IDS.times.map { rand1.rand(MAX_V) }

  [hashids_encoder, sqids_encoder, inputs]
end

def profile_encode
  hashids_encoder, sqids_encoder, inputs = setup_encoders

  puts "\n=== PROFILING ENCODE OPERATIONS ===\n"

  puts "\n--- HashIds Encode Profile ---"
  result = StackProf.run(mode: :cpu) do
    NUM_ITERATIONS.times.each do
      hashids_encoder.encode(inputs)
    end
  end
  StackProf::Report.new(result).print_text

  puts "\n--- Sqids Encode Profile ---"
  result = StackProf.run(mode: :cpu) do
    NUM_ITERATIONS.times.each do
      sqids_encoder.encode(inputs)
    end
  end
  StackProf::Report.new(result).print_text
end

def profile_decode
  hashids_encoder, sqids_encoder, inputs = setup_encoders

  # Generate encoded values to decode
  hashids_encoded = hashids_encoder.encode(inputs)
  sqids_encoded = sqids_encoder.encode(inputs)

  puts "\n=== PROFILING DECODE OPERATIONS ===\n"

  puts "\n--- HashIds Decode Profile ---"
  result = StackProf.run(mode: :cpu) do
    NUM_ITERATIONS.times.each do
      hashids_encoder.decode(hashids_encoded)
    end
  end
  StackProf::Report.new(result).print_text

  puts "\n--- Sqids Decode Profile ---"
  result = StackProf.run(mode: :cpu) do
    NUM_ITERATIONS.times.each do
      sqids_encoder.decode(sqids_encoded)
    end
  end
  StackProf::Report.new(result).print_text
end

# Ensure stackprof directory exists
Dir.mkdir("tmp") unless Dir.exist?("tmp")

# Run the profiles
profile_encode
profile_decode

puts "\nProfile dumps saved to tmp/ directory"
