Feature: Dump runtime errors

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



  Scenario: by default runtime errors are raised
    When I run "rake db:dump FORCE=1 TABLES=doesntexist"
    Then the exit status should be 1
    And the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"



  Scenario Outline: RAISE_ERROR= toggles silence or raise runtime errors
    When I run "rake db:dump FORCE=1 TABLES=doesntexist RAISE_ERROR=<RAISE_ERROR>"
    Then the exit status should be <EXIT_STATUS>
    But the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"

    Scenarios: don't raise
    | RAISE_ERROR | EXIT_STATUS |
    | false       | 0           |
    | 0           | 0           |

    Scenarios: raise
    | RAISE_ERROR | EXIT_STATUS |
    | true        | 1           |
    | 1           | 1           |



  Scenario: dirty directory warning on failed dump
    When I run "rake db:dump FORCE=1 TABLES=doesntexist"
    Then the exit status should be 1
    And the following directories should exist:
      | db/dump/doesntexist     |
    And the output should contain "Partial dump files have been left behind and you should clean up before continuing (e.g. git status, git checkout, git clean)."



  Scenario: invalid FIXTURES argument raises an error
    When I run "rake db:dump FORCE=1 FIXTURES=a_fixture.yml"
    Then the exit status should be 1
    And the output should contain "GitFriendlyDumper if :fixtures option given, neither :include_schema nor :clobber_fixtures can be given"

    When I run "rake db:data:dump FORCE=1 FIXTURES=a_fixture.yml"
    Then the exit status should be 1
    And the output should contain "Cannot dump when :fixtures option is given"
