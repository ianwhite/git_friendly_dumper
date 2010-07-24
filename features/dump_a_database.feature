Feature: Dump a database
# n.b. FORCE=1 short-circuits stdin prompts to 'yes', i.e. run as non-interactive

  Background:
    Given I am in an empty app
    Given a Rakefile exists which has an environment task and loads git_friendly_dumper tasks
    And an empty database
    And the database has a "users" table (with timestamps):
     | name (string) | surname (string) |
     | Fred          | Bloggs           |
     | Ethel         | Smith            |
     | Jane          | Heidie           |



  Scenario: test step works
    Then the "users" table should match exactly (ignoring ids and timestamps):
     | name  | surname |
     | Fred  | Bloggs  |
     | Ethel | Smith   |
     | Jane  | Heidie  |


  @announce
  Scenario: rake db:dump
    When I successfully run "rake db:dump FORCE=1"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users |
    And the following files should exist:
      | db/dump/users/schema.rb |
    When I successfully run "cat db/dump/users/**/*"
    Then I can verify the content of the dump yml files



  Scenario: change dump path
    When I successfully run "rake db:dump FORCE=1 DUMP_PATH=db/override"
    Then the output should contain "Dumping data and structure from database to db/override"
    And the following directories should exist:
      | db/override/users |
    And the following files should exist:
      | db/override/users/schema.rb |



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



  Scenario: silence runtime errors
    When I run "rake db:dump FORCE=1 TABLES=doesntexist"
    Then the exit status should be 1
    And the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"

    When I run "rake db:dump FORCE=1 TABLES=doesntexist RAISE_ERROR=0"
    Then the exit status should be 0
    But the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"

    When I run "rake db:dump FORCE=1 TABLES=alsodoesntexist RAISE_ERROR=false"
    Then the exit status should be 0
    But the output should contain "dumping alsodoesntexist failed: SQLite3::SQLException: no such table: alsodoesntexist: SELECT COUNT(*) FROM alsodoesntexist"



  Scenario: dirty directory warning on failed dump
    When I run "rake db:dump FORCE=1 TABLES=doesntexist"
    Then the exit status should be 1
    And the following directories should exist:
      | db/dump/doesntexist     |
    And the output should contain "Partial dump files have been left behind and you should clean up before continuing (e.g. git status, git checkout, git clean)."


