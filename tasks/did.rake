namespace :git_friendly_dumper do
  desc "dump all tables in the database to db/git_friendly_dump (override with TABLES, RAILS_ENV, DUMP_PATH)"
  task :dump => :environment do
    GitFriendlyDumper.dump :tables => ENV['TABLES'], :path => ENV['DUMP_PATH'], :progress => true, :force => true
  end
  
  desc "replace tables in the database with those in db/git_friendly_dump (override with TABLES, RAILS_ENV, DUMP_PATH)"
  task :load => :environment do
    GitFriendlyDumper.load :tables => ENV['TABLES'], :path => ENV['DUMP_PATH'], :force => true, :progress => true
  end
end

namespace :gfd do
  task :dump => 'git_friendly_dumper:dump'
  task :load => 'git_friendly_dumper:load'
end