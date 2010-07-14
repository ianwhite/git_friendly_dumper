Given /an app exists/ do
  steps %q{
    Given a file named "Rakefile" with:
      """
      require 'rake'
      load "#{File.dirname(__FILE__)}/../../lib/tasks/db.rake"
      """
  }
end