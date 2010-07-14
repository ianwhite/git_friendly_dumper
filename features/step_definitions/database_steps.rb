Given /^there is a connection$/ do
  ActiveRecord::Base.connection.should_not be_nil
end

Given /^an empty database$/ do
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
end

Given /^the database has a users table$/ do
  ActiveRecord::Base.connection.create_table :users, :force => true do |t|
    t.string :name
    t.timestamps
  end
end

Given /^the users table has some data$/ do
  user_class = Class.new(ActiveRecord::Base)
  user_class.table_name = 'users'
  user_class.create! :name => "Fred"
  user_class.create! :name => "Ethel"
  user_class.create! :name => "James"
end