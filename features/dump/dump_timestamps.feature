Feature: Dump with TIMESTAMPS=true
  In order to cut down on dump times, by not overriding fixtures with identical data
  I want to be able to dump only changed records

  Scenario: only works for tables with updated_at column
            
  Scenario: only dumps records that have changed since last dump
            
  Scenario: creates fixtures for records that are new since last dump
            
  Scenario: removes fixtures that have been deleted from the table since last dump
            
  Scenario: use case: create, update and delete fixtures that have changed since last dump in one go
  
  Scenario: only available for db:data:dump
  
  Scenario: doesn't work with CLOBBER_FIXTURES

  Scenario: doesn't work with INCLUDE_SCHEMA
  

  
