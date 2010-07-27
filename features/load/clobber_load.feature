Feature: CLOBBER is ignored when loading
  CLOBBER=false|0        clobber fixtures on dump  (default true)
  Is ignored by db:load

  Scenario: setting CLOBBER on load does nothing (fixtures are not deleted afterwards)
    Given I am in an empty app
    And a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
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
    And a file named "db/dump/users/0000/0002.yml" with:
    """
    --- 
    name: Ethel
    created_at: 2008-07-26 19:38:10
    updated_at: 2010-03-22 11:38:10
    id: 2
    surname: Smith
    """

    When I successfully run "rake db:load FORCE=1 CLOBBER=true"
    And I refresh the database tables cache
    And the "users" table should match exactly:
    | id    | name  | surname | created_at          | updated_at          |
    | 1     | Jane  | Heidie  | 2003-07-26 12:38:10 | 2007-07-26 12:48:10 |
    | 2     | Ethel | Smith   | 2008-07-26 19:38:10 | 2010-03-22 11:38:10 |

    But the following files should exist:
      | db/dump/users/schema.rb     |
      | db/dump/users/0000/0001.yml |
      | db/dump/users/0000/0002.yml |
