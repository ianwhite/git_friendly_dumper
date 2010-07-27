Feature: Raise load errors
  RAISE_ERROR=false|0    silence runtime errors    (default true)

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database



  Scenario Outline: if a schema isn't found it always blows up, ignoring RAISE_ERROR
    When I run "rake db:load FORCE=1 TABLES=doesnotexist RAISE_ERROR=<RAISE_ERROR>"
    Then the exit status should be <EXIT_STATUS>
    And the output should contain "No such file or directory"

    Scenarios: always raises
    | RAISE_ERROR | EXIT_STATUS |
    |             | 1           |
    | false       | 1           |
    | 0           | 1           |
    | true        | 1           |
    | 1           | 1           |



  Scenario Outline: using RAISE_ERROR to toggle raising ActiveRecord insertion errors
    Given a file named "db/dump/users/schema.rb" with:
    """
    create_table "users", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      # t.string   "name"
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

    When I run "rake db:load FORCE=1 TABLES=users RAISE_ERROR=<RAISE_ERROR>"
    Then the exit status should be <EXIT_STATUS>
    And the output <SEE_MESSAGE> contain "SQLite3::SQLException: table users has no column named name:"

    Scenarios: don't raise
    | RAISE_ERROR | EXIT_STATUS | SEE_MESSAGE |
    | false       | 0           | should not  |
    | 0           | 0           | should not  |

    Scenarios: raise
    | RAISE_ERROR | EXIT_STATUS | SEE_MESSAGE |
    |             | 1           | should      |
    | true        | 1           | should      |
    | 1           | 1           | should      |


  @announce
  Scenario Outline: can also silence errors loading a fixture
    Given a file named "db/dump/users/schema.rb" with:
    """
    create_table "users", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name"
      t.string   "surname"
    end
    """
    And I successfully run "rake db:load FORCE=1"

    When I write to "db/dump/users/0000/0001.yml" with:
    """
    ---
    forename: Jane
    created_at: 2003-07-26 12:38:10
    updated_at: 2007-07-26 12:48:10
    id: 1
    surname: Heidie
    """
    And I run "rake db:data:load FORCE=1 FIXTURES='users/0000/0001.yml' RAISE_ERROR=<RAISE_ERROR>"
    Then the exit status should be <EXIT_STATUS>
    And the output <SEE_MESSAGE> contain "SQLite3::SQLException: table users has no column named forename:"

    Scenarios: don't raise
    | RAISE_ERROR | EXIT_STATUS | SEE_MESSAGE |
    | false       | 0           | should not  |
    | 0           | 0           | should not  |

    Scenarios: raise
    | RAISE_ERROR | EXIT_STATUS | SEE_MESSAGE |
    |             | 1           | should      |
    | true        | 1           | should      |
    | 1           | 1           | should      |


