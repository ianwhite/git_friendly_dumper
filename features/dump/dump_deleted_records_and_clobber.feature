Feature: What happens to fixtures belonging to deleted records when I perform a new dump
  When dumping a table, any existing fixtures for that table are first removed
  Any tables not being dumped, however, are ignored, and the old fixtures will remain in place

  In order to have fixtures for what's in my database and nothing else
  That is, no leftovers (deleted records, dropped tables, etc) from previous dumps
  I want to CLOBBER them all before dumping

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



  Scenario: when dumping specific TABLES= any other tables' fixtures are left as they were (even if stale or deleted)
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
