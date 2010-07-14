require 'spec/rake/spectask'

task :default => [:spec]

desc "Set up tmp stuff for running specs etc"
file "tmp/db" do
  mkdir_p 'tmp/db'
end

desc "Run the specs"
Spec::Rake::SpecTask.new(:spec => ['tmp/db']) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts  = ["--colour"]
end