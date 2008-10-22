namespace :git_friendly_dumper do
  desc "dump all tables in the database to db/git_friendly_dumper (override with TABLES, RAILS_ENV, DUMP_PATH)"
  task :dump => :environment do
    dumper = GitFriendlyDupmper.new :tables => ENV['TABLES'], :path => ENV['DUMP_PATH'], :force => true, :progress => true
    dumper.dump
  end
  
  desc "replace tables in the database with those in db/git_friendly_dumper (override with TABLES, RAILS_ENV, DUMP_PATH)"
  task :load => :environment do
    dumper = GitFriendlyDupmper.new :tables => ENV['TABLES'], :path => ENV['DUMP_PATH'], :force => true, :progress => true
    dumper.load
  end
end

namespace :gfd do
  task :dump => 'git_friendly_dumper:dump'
  task :load => 'git_friendly_dumper:load'
end