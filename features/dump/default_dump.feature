Feature: Default dump
  In order to produce incremental backups of my database using git
  I want to backup my database in a form git can play nicely with

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



  Scenario: rake db:dump dumps all tables' contents and the schema
    When I successfully run "rake db:dump FORCE=1"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users             |
      | db/dump/schema_migrations |
    And the following files should exist:
      | db/dump/users/schema.rb |
      
    And the data in the dumped "users" yaml files should match the database contents

    Given an empty database
    When I execute the schema "db/dump/users/schema.rb"
    Then a "users" table should exist with structure:
      | name       | type         |
      | id         | INTEGER      |
      | created_at | datetime     |
      | updated_at | datetime     |
      | name       | varchar(255) |
      | surname    | varchar(255) |
