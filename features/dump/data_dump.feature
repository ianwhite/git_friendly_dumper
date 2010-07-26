Feature: Data dump
  In order to … 
  I want to dump the data fixtures but not the schema or migrations table

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And the database has a "users" table (with timestamps):
      | name (string) | surname (string) |
      | Fred          | Bloggs           |
      | Ethel         | Smith            |
      | Jane          | Heidie           |
    And the database has a "schema_migrations" table:
      | version (string) | 
      | 01001010123      |


  Scenario: rake db:data:dump dumps all tables' contents but does not dump the schema or migrations table
    When I successfully run "rake db:data:dump FORCE=1"
    Then the output should contain "Dumping data from database to db/dump"
    And the following directories should exist:
      | db/dump/users             |
    But the following directories should not exist:
      | db/dump/schema_migrations |
    And the following files should not exist:
      | db/dump/users/schema.rb |
