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