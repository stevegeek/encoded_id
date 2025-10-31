# frozen_string_literal: true

source "https://rubygems.org"

gemspec name: "encoded_id"
gemspec name: "encoded_id-rails"

gem "sqids"   # For new encoder option

gem "rake"
gem "minitest"
gem "standard"
gem "rbs-inline", github: "soutaro/rbs-inline", branch: "main", require: false
gem "steep", github: "soutaro/steep", branch: "master", require: false

gem "simplecov"
gem "rubycritic"

gem "benchmark-ips"
gem "benchmark-memory"
gem "fuzzbert", github: "krypt/FuzzBert", branch: "master"
gem "singed"
gem "stackprof"
gem "vernier"
gem "memory_profiler"
gem "hashids" # For benchmarking against

gem "base64" # For testing custom encoder/decoder

# For generating badges
gem "simplecov-small-badge", require: false
gem "rubycritic-small-badge", require: false
gem "repo-small-badge" # Required by both badge gems

# For Rails integration tests
gem "rails", ">= 7.2.0"
gem "sqlite3"

gem "appraisal"
