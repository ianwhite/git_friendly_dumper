Feature: Dump a database

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And the database has a users table
    And the users table has some data
    
  Scenario: rake db:dump FORCE=true
    When I successfully run "rake db:dump"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users |
    And the following files should exist:
      | db/dump/users/schema.rb |
