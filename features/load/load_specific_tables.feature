Feature: Load specific tables
  In order to only restore particular tables from the dump to my database
  I want to specify a list of table names for the rake task to process
  TABLES=comma,sep,list  tables to dump/load       (default all)


  Background:
    Given I am in an empty app
    And a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database

    Given a file named "db/dump/users/schema.rb" with:
    """
    create_table "users", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name"
      t.string   "surname"
    end
    
    """
    And a file named "db/dump/users/0000/0001.yml" with:
    """
    --- 
    name: Jane
    created_at: 2003-07-26 12:38:10
    updated_at: 2007-07-26 12:48:10
    id: 1
    surname: Heidie
    
    """
    And a file named "db/dump/users/0001/0008.yml" with:
    """
    --- 
    name: Ethel
    created_at: 2008-07-26 19:38:10
    updated_at: 2010-03-22 11:38:10
    id: 10008
    surname: Smith
    """

    And a file named "db/dump/debts/schema.rb" with:
    """
    create_table "debts", :force => true do |t|
      t.string   "name"
      t.integer  "amount"
    end
    
    """
    And a file named "db/dump/debts/0000/0012.yml" with:
    """
    --- 
    name: Jane Heidie
    id: 12
    amount: 3403
    
    """

    And a file named "db/dump/schema_migrations/schema.rb" with:
    """
    create_table "schema_migrations", :force => true do |t|
      t.string   "version"
    end
    
    """
    And a file named "db/dump/schema_migrations/0000/0001.yml" with:
    """
    --- 
    version: "01001010123"
    id: 1
    
    """



    Scenario: load the debts table only
      When I successfully run "rake db:load FORCE=1 TABLES=debts"
      Then the database should have tables:
        | debts |
      But the database should not have table "users"
      But the database should not have table "schema_migrations"
      And a "debts" table should exist with structure:
        | name   | type         |
        | id     | INTEGER      |
        | name   | varchar(255) |
        | amount | integer      |
      And the "debts" table should match exactly:
        | id | name        | amount |
        | 12 | Jane Heidie | 3403   |



    Scenario: load the users and debts tables
      When I successfully run "rake db:load FORCE=1 TABLES=debts,users"
      Then the database should have tables:
        | debts |
        | users |
      But the database should not have table "schema_migrations"

      Then a "users" table should exist with structure:
        | name       | type         |
        | id         | INTEGER      |
        | created_at | datetime     |
        | updated_at | datetime     |
        | name       | varchar(255) |
        | surname    | varchar(255) |
      And the "users" table should match exactly:
        | id    | name  | surname | created_at          | updated_at          |
        | 1     | Jane  | Heidie  | 2003-07-26 12:38:10 | 2007-07-26 12:48:10 |
        | 10008 | Ethel | Smith   | 2008-07-26 19:38:10 | 2010-03-22 11:38:10 |

      And a "debts" table should exist with structure:
        | name   | type         |
        | id     | INTEGER      |
        | name   | varchar(255) |
        | amount | integer      |
      And the "debts" table should match exactly:
        | id | name        | amount |
        | 12 | Jane Heidie | 3403   |
