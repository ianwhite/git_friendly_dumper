Feature: Dump a database

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And the database has a "users" table (with timestamps):
     | name (string) | surname (string) |
     | Fred          | Bloggs           |
     | Ethel         | Smith            |
     | Jane          | Heidie           |
    
  Scenario: test step works
    Then the "users" table should consist of:
     | name  | surname |
     | Fred  | Bloggs  |
     | Ethel | Smith   |
     | Jane  | Heidie  |
  
  Scenario: rake db:dump FORCE=true
    When I successfully run "rake db:dump"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users |
    And the following files should exist:
      | db/dump/users/schema.rb |
