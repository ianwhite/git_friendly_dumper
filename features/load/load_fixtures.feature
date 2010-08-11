Feature: Load fixtures
  In order to load particular backups into my database
  I want to pass the rake task a list of specific fixtures to be imported
  FIXTURES -- specific fixture files to load, invalid argument for dump tasks


  Scenario: loading specific fixtures into an existing database
  # FIXTURES - the intended behaviour of fixtures is to only load the specified fixtures.  
  # specifying TABLES should result in only loading the fixtures in the specified tables.  
  # No schema can be loaded when fixtures is specified.  
  # I believe that this feature is buggy at the moment.
    
  Scenario: loading specific fixtures into an existing table with records only replaces the ones I specify
    Given a users table exists with some records
    And fixtures exist for all of the table records, but their attributes are different
    When I load specific fixtures
    Then only the associated records should be changed


  Scenario: loading a fixture which does not exist deletes its record
    Given record 1 exists
    But fixture 1 does not exist
    And I load fixture 1
    Then record 1 should be destroyed

  
  Scenario: inserting a non-existant record from fixture
    Given record 1 does not exist
    But fixture 1 does exist
    And I load fixture 1
    Then record 1 should exist
  
  
  Scenario: TABLES can be used whitelist a subset of the FIXTURES to operate on
    Given an empty database
    And some User fixtures
    And some Notes fixtures
    
    
    
  
  
  