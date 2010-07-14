Feature: Dump a database

  Background:
    Given a an app exists
    And an empty database
    And the database has a users table
    And the users table has some data
    
  Scenario: rake db:dump FORCE=true
    When I successfully run "rake db:dump"
