# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Run tests with coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["test"].invoke
end

require "standard/rake"

task default: %i[test standard]
