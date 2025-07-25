# frozen_string_literal: true

require_relative "lib/encoded_id/version"

# Collect files from other gemspecs to exclude them from the main gem
plugin_files = []

Dir["encoded_id-*.gemspec"].each do |gemspec_file|
  spec = Gem::Specification.load(gemspec_file)
  plugin_files << spec.files if spec
end

# Flatten and make unique
ignored_files = plugin_files.flatten.uniq

Gem::Specification.new do |spec|
  spec.name = "encoded_id"
  spec.version = EncodedId::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "EncodedId is a gem for creating reversible obfuscated IDs from numerical IDs. It uses an implementation of Hash IDs under the hood."
  spec.description = "Encode your numerical IDs (eg record primary keys) into obfuscated strings that can be used in URLs. The obfuscated strings are reversible, so you can decode them back into the original numerical IDs. Supports encoding multiple IDs at once, and generating IDs with custom alphabets and separators to make the IDs easier to read or share. Dependency free."
  spec.homepage = "https://github.com/stevegeek/encoded_id"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem (base library)
    all_files = files.select do |f|
      f.match?(%r{^(lib/encoded_id)}) && !f.match?(%r{^(lib/encoded_id/rails)})
    end

    # Exclude files from other gemspecs
    all_files - ignored_files + [
      "README.md", "LICENSE.txt", "CHANGELOG.md", "context/encoded_id.md",
    ]
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
