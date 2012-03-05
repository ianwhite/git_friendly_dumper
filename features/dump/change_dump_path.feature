Feature: Change dump path
  In order to dump somewhere else than db/dump
  I want the rake task to use the DUMP_PATH env variable to override the data path used

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



  Scenario: change dump path
    When I successfully run `rake db:dump FORCE=1 DUMP_PATH=db/override`
    Then the output should contain "Dumping data and structure from database to db/override"
    And the following directories should exist:
      | db/override/users |
    And the following files should exist:
      | db/override/users/schema.rb |
