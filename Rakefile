# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

task default: %i[test standard]

# Add RubyCritic task with badge generation
begin
  require "rubycritic_small_badge"
  require "rubycritic/rake_task"

  RubyCriticSmallBadge.configure do |config|
    config.minimum_score = 90
  end

  RubyCritic::RakeTask.new do |task|
    # Exclude generator files from analysis as they aren't tested
    task.paths = FileList["lib/**/*.rb"].exclude("lib/generators/**/*.rb")

    task.options = %(--custom-format RubyCriticSmallBadge::Report
      --minimum-score #{RubyCriticSmallBadge.config.minimum_score}
      --coverage-path coverage/.resultset.json
      --no-browser)
  end

  desc "Run tests with coverage and then RubyCritic"
  task rubycritic_with_coverage: [:coverage, :rubycritic]
rescue LoadError
  desc "Run RubyCritic (not available)"
  task :rubycritic do
    puts "RubyCritic is not available"
  end
end

namespace :website do
  desc "Build the documentation website"
  task :build do
    Dir.chdir("website") do
      puts "Building documentation website..."
      system "bundle install"
      system "bundle exec jekyll build"
      puts "Website built in website/_site/"
    end
  end

  desc "Serve the documentation website locally"
  task :serve do
    Dir.chdir("website") do
      puts "Starting local documentation server..."
      puts "View the website at http://localhost:4000/"
      system "bundle install"
      system "bundle exec jekyll serve"
    end
  end

  desc "Clean the documentation website build"
  task :clean do
    Dir.chdir("website") do
      puts "Cleaning website build..."
      system "bundle exec jekyll clean"
    end
  end
end

desc "Compile extension"
task :compile_ext do
  puts "Compiling extension"
  `cd ext/encoded_id && make clean`
  `cd ext/encoded_id && ruby extconf.rb`
  `cd ext/encoded_id && make`
  puts "Done"
end

desc "Run code coverage"
task :coverage do
  ENV["COVERAGE"] = "1"
  Rake::Task["test"].invoke
end

desc "Build all gems"
task :build do
  # Remove any existing gem files
  puts "Removing existing gem files..."
  FileUtils.rm_f(Dir.glob("*.gem"))

  # Build each gemspec
  Dir.glob("*.gemspec").each do |gemspec|
    puts "Building #{gemspec}..."
    system "gem build #{gemspec}"
  end
end

desc "Inspect gem contents by unpacking them to tmp/inspect"
task :unpack do
  require "fileutils"

  # Create and clean the inspect directory
  inspect_dir = "tmp/inspect"
  FileUtils.rm_rf(inspect_dir) if Dir.exist?(inspect_dir)
  FileUtils.mkdir_p(inspect_dir)

  # Find and unpack all gem files
  Dir.glob("*.gem").each do |gem_file|
    puts "Unpacking #{gem_file}..."
    system "gem unpack #{gem_file} --target=#{inspect_dir}"
  end

  puts "\nGems unpacked to #{inspect_dir}"
end

desc "Push all built gems to RubyGems"
task :release do
  # Get list of gem files
  gem_files = Dir.glob("*.gem")

  if gem_files.empty?
    puts "No gem files found. Run 'rake build' first."
    exit 1
  end

  # Ask for confirmation
  puts "The following gems will be pushed to RubyGems:"
  gem_files.each { |gem| puts "  - #{gem}" }

  print "\nAre you sure you want to continue? [y/N] "
  confirmation = $stdin.gets.chomp.downcase

  if confirmation == "y"
    # Push each gem
    gem_files.each do |gem_file|
      puts "\nPushing #{gem_file}..."
      system "gem push #{gem_file}"

      # Check if push was successful
      if $?.success?
        puts "Successfully pushed #{gem_file}"
      else
        puts "Failed to push #{gem_file}"
      end
    end
  else
    puts "Aborted."
  end
end
