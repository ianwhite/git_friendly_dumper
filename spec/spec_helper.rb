# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment"))
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
end

def reset_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
end

def migrate_up(version)
  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Migrator.migrate(File.join(File.dirname(__FILE__), 'resources/migrate'), version)
  end
end

def remove_dump
  `rm -rf #{File.join(File.dirname(__FILE__), 'resources/dump')}`
end