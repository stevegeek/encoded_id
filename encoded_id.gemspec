# frozen_string_literal: true

require_relative "lib/encoded_id/version"

Gem::Specification.new do |spec|
  spec.name = "encoded_id"
  spec.version = EncodedId::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "EncodedId is a gem for creating reversible obfuscated IDs from numerical IDs. It uses an implementation of Hash IDs under the hood."
  spec.description = "Encode your numerical IDs (eg record primary keys) into obfuscated strings that can be used in URLs. The obfuscated strings are reversible, so you can decode them back into the original numerical IDs. Supports encoding multiple IDs at once, and generating IDs with custom alphabets and separators to make the IDs easier to read or share. Dependency free."
  spec.homepage = "https://github.com/stevegeek/encoded_id"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/stevegeek/encoded_id/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
