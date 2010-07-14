Given /^there is a connection$/ do
  ActiveRecord::Base.connection.should_not be_nil
end

Given /^an empty database$/ do
  require 'active_record'
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => "#{current_dir}/test.sqlite3")
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
end

Then /^show me the "([^"]*)" table$/ do |table_name|
  puts "<pre>#{table_contents(table_name, false).to_yaml}</pre>"
end

Given /^the database has a "([^"]*)" table( \(with timestamps\))?:$/ do |table_name, timestamps, table|
  create_table(table_name)
  add_timestamps_to_table(table_name) if timestamps
  
  columns = []
  table.headers.each do |column_def|
    raise "column_def should look like 'column_name (type)'" unless match = column_def.match(/(\w+) \((\w+)\)/)
    add_column_to_table(table_name, match[1], match[2])
    columns << match[1]
  end
  
  table.rows.each do |row|
    attrs = {}
    columns.each_with_index do |column_name, index|
      attrs[column_name] = row[index]
    end
    insert_record_into_table(table_name, attrs)
  end
end

Then /^the "([^"]*)" table should consist of:$/ do |table_name, table|
  table.diff!(table_contents(table_name))
end

module DatabaseHelpers
  def create_table(name)
    ActiveRecord::Base.connection.create_table name do
    end
  end

  def add_timestamps_to_table(name)
    ActiveRecord::Base.connection.change_table name do |t|
      t.timestamps
    end
  end

  def add_column_to_table(table_name, column_name, type)
    ActiveRecord::Base.connection.change_table table_name do |t|
      t.send type, column_name
    end
  end

  def class_for_table(table_name)
    @class_for_table ||= {}
    @class_for_table[table_name] ||= begin
      Class.new(ActiveRecord::Base).tap {|klass| klass.table_name = table_name }
    end
  end

  def insert_record_into_table(table_name, attrs)
    class_for_table(table_name).create! attrs
  end

  def table_contents(table_name)
    contents = class_for_table(table_name).all.map(&:attributes)
  end
end

World(DatabaseHelpers)