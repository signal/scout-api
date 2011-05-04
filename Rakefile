require 'bundler'
Bundler.setup(:default, :development)

$LOAD_PATH.unshift 'lib'
require 'scout_api/version'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.version = Scout::VERSION
  gem.name = "scout_api"
  gem.summary = %Q{API wrapper for scoutapp.com}
  gem.description = %Q{A library for interacting with Scout (http://scoutapp.com), a hosted server monitoring service. Query for metric data, manage servers, and more.}
  gem.email = "support@scoutapp.com"
  gem.homepage = "https://scoutapp.com/info/api"
  gem.authors = ["Jesse Newland", "Derek Haynes"]
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  # dependencies are handled in Gemfile
end
Jeweler::GemcutterTasks.new

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = Scout::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "scout_api #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r scout.rb"
end

require "rake/testtask"
Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = [ "test/*.rb" ]
  test.verbose = true
end

task :default => :test