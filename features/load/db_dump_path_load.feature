Feature: populate database with data and stucture in a custom directory
  In order to load data found elsewhere than db/dump
  I want the rake task to use the DUMP_PATH env variable to override the data path used


  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And a file named "db/dump/users/schema.rb" with:
    """
    create_table "users", :force => true do |t|
      t.string   "wont_use"
      t.string   "this_schema"
    end
    
    """
    And a file named "db/dump/users/0000/0001.yml" with:
    """
    --- 
    name: shouldnt
    surname: be_loaded
    created_at: 2003-07-26 12:38:10
    updated_at: 2007-07-26 12:48:10
    id: 1
    
    """


  Scenario: rake db:load with different DUMP_PATH
    Given a file named "db/alt/dump/users/schema.rb" with:
    """
    create_table "users", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name"
      t.string   "surname"
    end

    """
    And a file named "db/alt/dump/users/0000/0001.yml" with:
    """
    ---
    name: Fred
    created_at: 2002-07-23 12:28:10
    updated_at: 2004-07-22 12:18:14
    id: 1
    surname: Bloggs
    
    """
    When I successfully run `rake db:load FORCE=1 DUMP_PATH=db/alt/dump`
    And I refresh the database tables cache
    Then a "users" table should exist with structure:
      | name       | type         |
      | id         | INTEGER      |
      | created_at | datetime     |
      | updated_at | datetime     |
      | name       | varchar(255) |
      | surname    | varchar(255) |
    And the "users" table should match exactly:
    | id    | name  | surname | created_at          | updated_at          |
    | 1     | Fred  | Bloggs  | 2002-07-23 12:28:10 | 2004-07-22 12:18:14 |

