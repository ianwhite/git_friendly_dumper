Feature: Dump specific tables
  In order to only backup certain tables
  I want TABLES to list the tables the rake task will dump

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



  Scenario: dump specific tables
    Given the database has a "seen" table (with timestamps):
      | bird (string) | seen (integer) |
      | Parrot        | 1              |
      | Robin         | 3              |
      | Goldfinch     | 6              |
    Given the database has a "notes" table:
      | content (text)          |
      | Fred spotted a parrot?? |

    When I successfully run "rake db:dump FORCE=1 TABLES=seen,users"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users |
      | db/dump/seen |
    And the following files should exist:
      | db/dump/users/schema.rb |
      | db/dump/seen/schema.rb  |
    But the following directories should not exist:
      | db/dump/notes |
