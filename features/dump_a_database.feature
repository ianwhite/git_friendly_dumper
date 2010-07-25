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
    And the database has a "schema_migrations" table:
      | version (string) | 
      | 01001010123      |


  @announce @wip
  Scenario: rake db:dump dumps all tables' contents and the schema
    When I successfully run "rake db:dump FORCE=1"
    Then the output should contain "Dumping data and structure from database to db/dump"
    And the following directories should exist:
      | db/dump/users             |
      | db/dump/schema_migrations |
    And the following files should exist:
      | db/dump/users/schema.rb |
      
    When I successfully run "cat db/dump/users/**/*"
    Then I can verify the content of the dump yml files



  Scenario: rake db:data:dump dumps all tables' contents but does not dump the schema or migrations table
    When I successfully run "rake db:data:dump FORCE=1"
    Then the output should contain "Dumping data from database to db/dump"
    And the following directories should exist:
      | db/dump/users             |
    But the following directories should not exist:
      | db/dump/schema_migrations |
    And the following files should not exist:
      | db/dump/users/schema.rb |



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



  Scenario: by default runtime errors are raised
    When I run "rake db:dump FORCE=1 TABLES=doesntexist"
    Then the exit status should be 1
    And the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"


  Scenario Outline: RAISE_ERROR= toggles silence or raise runtime errors
    When I run "rake db:dump FORCE=1 TABLES=doesntexist RAISE_ERROR=<RAISE_ERROR>"
    Then the exit status should be <EXIT_STATUS>
    But the output should contain "dumping doesntexist failed: SQLite3::SQLException: no such table: doesntexist: SELECT COUNT(*) FROM doesntexist"

    Scenarios: raise
    | RAISE_ERROR | EXIT_STATUS |
    | false       | 0           |
    | 0           | 0           |

    Scenarios: don't raise
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
    And the output should contain "Cannot dump when :fixtures option is given"



  Scenario: fixtures belonging to deleted records are deleted and not recreated
    When I run "rake db:dump FORCE=1"
    Then the following files should exist:
      | db/dump/users/0000/0001.yml |
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |

    When I destroy record 1 from the "users" table
    And I run "rake db:dump FORCE=1"
    Then the following files should exist:
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |
    But the following files should not exist:
      | db/dump/users/0000/0001.yml |



  Scenario: when dumping specific TABLES= any other tables' fixtures are left alone (even if deleted)
    Given the database has a "debts" table (with timestamps):
     | name (string) | surname (string) |
     | Fred          | Bloggs           |
     | Ethel         | Smith            |

    When I run "rake db:dump FORCE=1"
    Then the following files should exist:
      | db/dump/users/0000/0001.yml |
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |
      | db/dump/debts/0000/0001.yml |
      | db/dump/debts/0000/0002.yml |

    When I destroy record 1 from the "debts" table
    And I run "rake db:dump FORCE=1 TABLES=users"
    Then the following files should exist:
      | db/dump/users/0000/0001.yml |
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |
      | db/dump/debts/0000/0001.yml |
      | db/dump/debts/0000/0002.yml |



  Scenario Outline: CLOBBER= removes all existing fixtures before dumping new ones, combining with TABLES= means only those tables' fixtures will exist
    Given the database has a "debts" table (with timestamps):
     | name (string) | surname (string) |
     | Fred          | Bloggs           |
     | Ethel         | Smith            |
    When I run "rake db:dump FORCE=1"
    Then the following files should exist:
      | db/dump/users/0000/0001.yml |
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |
      | db/dump/debts/0000/0001.yml |
      | db/dump/debts/0000/0002.yml |

    When I destroy record 1 from the "users" table
    And I run "rake db:dump FORCE=1 TABLES=users CLOBBER=<CLOBBER>"
    Then the following files should exist:
      | db/dump/users/0000/0002.yml |
      | db/dump/users/0000/0003.yml |
    But the following files should not exist:
      | db/dump/users/0000/0001.yml |
    And the following files <EXISTENCE>:
      | db/dump/debts/0000/0001.yml |
      | db/dump/debts/0000/0002.yml |

    Scenarios: deleting existing dump fixtures with CLOBBER=true|1
      | CLOBBER | EXISTENCE         |
      | true    | should not exist  |
      | 1       | should not exist  |

    Scenarios: not deleting existing dump fixtures with CLOBBER=false|0
      | CLOBBER | EXISTENCE    |
      | false   | should exist |
      | 0       | should exist |
