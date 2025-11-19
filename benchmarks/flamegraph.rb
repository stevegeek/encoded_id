# frozen_string_literal: true

require "encoded_id"
require "singed"

Singed.output_directory = "./tmp"

input_for_flamegraph = 100.times.map { rand(1000) }.freeze

# HashId encoder
hashid_coder = ::EncodedId::ReversibleId.hashid(salt: "Salt!", max_inputs_per_id: 100)
hashid_encoded = hashid_coder.encode(input_for_flamegraph)

flamegraph("hashid_encode") {
  10_000.times { hashid_coder.encode(input_for_flamegraph) }
}

flamegraph("hashid_decode") {
  10_000.times { hashid_coder.decode(hashid_encoded) }
}

# Sqids encoder
sqids_coder = ::EncodedId::ReversibleId.sqids(max_inputs_per_id: 100, max_length: 10_000)
sqids_encoded = sqids_coder.encode(input_for_flamegraph)

flamegraph("sqids_encode") {
  10_000.times { sqids_coder.encode(input_for_flamegraph) }
}

flamegraph("sqids_decode") {
  10_000.times { sqids_coder.decode(sqids_encoded) }
}
