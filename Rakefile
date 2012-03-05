#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'GitFriendlyDumper'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

task :default => [:spec]

desc "Set up tmp stuff for running specs etc"
file "tmp/db" do
  mkdir_p 'tmp/db'
end

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec => ['tmp/db']) do |t|
  t.pattern = "./spec/**/*_spec.rb"
end