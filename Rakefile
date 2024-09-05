# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: %i[test standard]

task :compile_ext do
  puts "Compiling extension"
  `cd ext/encoded_id && make clean`
  `cd ext/encoded_id && ruby extconf.rb`
  `cd ext/encoded_id && make`
  puts "Done"
end
