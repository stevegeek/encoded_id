# frozen_string_literal: true

require_relative "lib/encoded_id/version"

Gem::Specification.new do |spec|
  spec.name = "encoded_id-rails"
  spec.version = EncodedId::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "Use `encoded_id` with ActiveRecord models"
  spec.description = "ActiveRecord concern to use EncodedID to turn IDs into reversible and human friendly obfuscated strings."
  spec.homepage = "https://github.com/stevegeek/encoded_id"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem (rails integration)
    all_files = files.select do |f|
      f.match?(%r{^(lib/encoded_id/rails)}) ||
        f.match?(%r{^(lib/generators)})
    end

    # Exclude files from base gemspec
    all_files + [
      "README.md", "LICENSE.txt", "CHANGELOG.md"
    ]
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.2", "< 9"
  spec.add_dependency "activerecord", ">= 7.2", "< 9"
  spec.add_dependency "encoded_id", EncodedId::VERSION
end
