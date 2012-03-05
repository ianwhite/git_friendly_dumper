$:.push File.expand_path("../lib", __FILE__)

require "git_friendly_dumper/version"

Gem::Specification.new do |s|
  s.name        = "git_friendly_dumper"
  s.version     = GitFriendlyDumper::VERSION
  s.authors     = ["Ian White"]
  s.email       = ["ian.w.white@gmail.com"]
  s.homepage    = "http://github.com/ianwhite/git_friendly_dumper"
  s.summary     = "Use fixtures to create a db independent and git friendly db dump."
  s.description = "Use fixtures to create a db independent and git friendly db dump.  It's git friendly because each record is in its own file (git doesn't do very well with large files that are committed all at once)."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "History.txt", "README.rdoc"]
  s.test_files = Dir["spec/**/*","features/**/*"]


  s.add_dependency "activerecord"
  
  s.add_development_dependency "mysql2"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
  s.add_development_dependency "progressbar"
  
end
