Given /^there is a connection$/ do
  ActiveRecord::Base.connection.should_not be_nil
end
