Feature: Load fixtures
  In order to load particular backups into my database
  I want to pass the rake task a list of specific fixtures to be imported
  FIXTURES -- specific fixture files to load, invalid argument for dump tasks

  Background:
    Given I am in an empty app
    And a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And the database has a "users" table:
      | name (string) | surname (string) |
      | Fred          | Bloggs           |
      | Ethel         | Smith            |
      | Jane          | Heidie           |
    And a file named "db/dump/users/0000/0001.yml" with:
    """
    --- 
    name: Frodo
    id: 1
    surname: Bloggo
    """
    And a file named "db/dump/users/0000/0002.yml" with:
    """
    --- 
    name: Ethelene
    id: 2
    surname: Smithy
    """
    
    
  Scenario: can't use rake db:load FIXTURES=…
    When I run "rake db:load FIXTURES=users/0000/0001.yml FORCE=true"
    Then the exit status should be 1
    And the "users" table should match exactly:
      | id | name  | surname |
      | 1  | Fred  | Bloggs  |
      | 2  | Ethel | Smith   |
      | 3  | Jane  | Heidie  |
    

  
  Scenario: loading specific fixtures into an existing table with records only replaces the ones I specify
    When I successfully run "rake db:data:load FIXTURES=users/0000/0001.yml FORCE=true"
    And the "users" table should match exactly:
      | id | name  | surname |
      | 1  | Frodo | Bloggo  |
      | 2  | Ethel | Smith   |
      | 3  | Jane  | Heidie  |



  Scenario: loading a fixture which does not exist deletes its record
    When I successfully run "rake db:data:load FIXTURES=users/0000/0003.yml FORCE=true"
    And the "users" table should match exactly:
      | id | name  | surname |
      | 1  | Fred  | Bloggs  |
      | 2  | Ethel | Smith   |

    
    
  
  Scenario: inserting a non-existant record from fixture
    Given a file named "db/dump/users/0000/0011.yml" with:
    """
    --- 
    name: Bob
    id: 11
    surname: Smith
    """
  
    When I successfully run "rake db:data:load FIXTURES=users/0000/0011.yml FORCE=true"
    And the "users" table should match exactly:
      | id | name  | surname |
      | 1  | Fred  | Bloggs  |
      | 2  | Ethel | Smith   |
      | 3  | Jane  | Heidie  |
      | 11 | Bob   | Smith   |



  Scenario: Updating, Creating & Deleting all in one go
    Given a file named "db/dump/users/0000/0011.yml" with:
    """
    --- 
    name: Bob
    id: 11
    surname: Smith
    """

    When I successfully run "rake db:data:load FIXTURES=users/0000/0001.yml,users/0000/0003.yml,users/0000/0011.yml FORCE=true"
    And the "users" table should match exactly:
      | id | name  | surname |
      | 1  | Frodo | Bloggo  |
      | 2  | Ethel | Smith   |
      | 11 | Bob   | Smith   |



  Scenario: TABLES can be used whitelist a subset of the FIXTURES to operate on
    Given an empty database
    And some User fixtures
    And some Notes fixtures
    
    
    
  
  Scenario: trying to load fixtures with :include_schema should raise an error
    When I run
  
  
  
  