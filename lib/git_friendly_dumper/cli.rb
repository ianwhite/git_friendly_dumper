require 'thor'
require 'git_friendly_dumper'

class GitFriendlyDumper
  class Cli < Thor

    desc "dump [path]", "dump structure and data to path (db/dump)"
    method_option :connection, :type => :hash, :desc => "e.g. --connection=adapter:sqlite3 database:test.sqlite3"
    def dump(path='db/dump')
      establish_connection
      GitFriendlyDumper.dump :path => path, :include_schema => true
    end
    
  protected
    def establish_connection
      if options.connection
        ActiveRecord::Base.establish_connection options.connection
      else
        establish_connection_via_rake_environment_task
      end
    end
    
    def establish_connection_via_rake_environment_task
      require 'rake'
      Rake.application.tap do |app|
        app.init
        app.load_rakefile
        app.invoke_task :environment
      end
      puts "established connection via rake"
    end
  end
end