Given /I am in an empty app/ do
  steps %q{
    Given a directory named "app"
    Given I cd to "app"
  }
  in_current_dir { `ln -s ../../../lib lib` }
end

Given /a Rakefile exists which has an environment task and loads git_friendly_dumper tasks/ do
  steps %q{
    Given a file named "Rakefile" with:
    """
    $LOAD_PATH.unshift("lib")
    require 'rake'
    require 'active_record'
    
    require 'git_friendly_dumper/tasks'
    
    task :environment do
      require 'active_record'
      ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => "test.sqlite3")
    end
    """
  }
end