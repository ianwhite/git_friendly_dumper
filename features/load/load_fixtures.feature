Feature: Load fixtures
  In order to load particular backups into my database
  I want to pass the rake task a list of specific fixtures to be imported
  FIXTURES -- specific fixture files to load, invalid argument for dump tasks


  Scenario: loading specific fixtures into an existing database
  # FIXTURES - the intended behaviour of fixtures is to only load the specified fixtures.  
  # specifying TABLES should result in only loading the fixtures in the specified tables.  
  # No schema can be loaded when fixtures is specified.  
  # I believe that this feature is buggy at the moment.