Feature: Load a database
# n.b. FORCE=1 short-circuits stdin prompts to 'yes', i.e. run as non-interactive

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And a file named "db/dump/users/schema.rb" with:
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



  Scenario: rake db:load replace database with data and stucture in db/dump
    When I successfully run "rake db:load FORCE=1"
    And I refresh the database tables cache
    Then the "users" table should match exactly:
    | id    | name  | surname | created_at          | updated_at          |
    | 1     | Jane  | Heidie  | 2003-07-26 12:38:10 | 2007-07-26 12:48:10 |
    | 10008 | Ethel | Smith   | 2008-07-26 19:38:10 | 2010-03-22 11:38:10 |

    And the "debts" table should match exactly:
    | id | name        | amount |
    | 12 | Jane Heidie | 3403   |

    And the "schema_migrations" table should match exactly:
    | id    | version      |
    | 1     | 01001010123  |



  Scenario: rake db:load with different DUMP_PATH replaces database with data and stucture DUMP_PATH
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
    When I successfully run "rake db:load FORCE=1 DUMP_PATH=db/alt/dump"
    And I refresh the database tables cache
    Then the "users" table should match exactly:
    | id    | name  | surname | created_at          | updated_at          |
    | 1     | Fred  | Bloggs  | 2002-07-23 12:28:10 | 2004-07-22 12:18:14 |

