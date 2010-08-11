Feature: Gfd cli
  In order to be cool
  As a loser
  I want a shiny cli
  
  Background:
    Given I am in an empty app
  
  Scenario: I can type 'gfd --help' and find out what it does
    When I successfully run "bin/gfd --help"
    Then the output should contain "Describe available tasks"
