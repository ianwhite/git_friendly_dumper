Feature: Figure out git changes since last load
  In order to speed up loading, when using a git based dump
  I want to be able to load fixtures changes since last load

  Scenario: rake db:data:load FIXTURES_FILE=filename loads fixtures in file
  
  Scenario: rake db:data:load SINCE_REF=<git ref> loads fixtures since then

  Scenario: rake db:data:load SINCE_REF=<git ref> borks if DUMP_PATH aint a git repo
  
  Scenario: rake db:data:load SINCE_LAST_LOAD=true loads fixtures since last load

  Scenario: rake db:data:load SINCE_LAST_LOAD=true borks if no last_load_ref exists in DUMP_PATH

  Scenario: rake db:data:load creates a last_load_ref in DUMP_PATH
  
  Scenario: rake db:data:load WRITE_LAST_LOAD_REF=false doesn't create a last_load_ref
  
  
