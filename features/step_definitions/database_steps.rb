Given /^there is a connection$/ do
  ActiveRecord::Base.connection.should_not be_nil
end

Given /^an empty database$/ do
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => "#{current_dir}/test.sqlite3")
  db_table_names.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
end

When /^I refresh the database tables cache$/ do
  # prevents exception SQLite3::SchemaChangedException: no such table: users: SELECT * FROM "users"  (ActiveRecord::StatementInvalid)
  # TODO: is there a public API for this?
  ActiveRecord::Base.connection.tables 
end

When(/^I execute the schema "([^"]*)"$/) do |schema_path|
  schema_definition = File.read(File.join(current_dir, schema_path))
  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Schema.define do
      eval schema_definition
    end
  end
end

Then(/^a "([^"]*)" table should exist with structure:$/) do |table_name, table|
  # table is a Cucumber::Ast::Table
  # TODO: make this db independent, currenlty for sqlite3 only
  table.diff! ActiveRecord::Base.connection.send :table_structure, table_name
end

Then /^list the table names$/ do
  announce db_table_names.to_sentence
end

Then(/^the database should have tables:$/) do |table|
  table.diff! db_table_names.map {|c| [c]}, :surplus_row => true, :surplus_col => true
end

Then(/^the database should not have table "([^"]*)"$/) do |table_name|
  db_table_names.should_not include(table_name)
end

Then /^show me the tables$/ do
  db_table_names.each do |table_name|
    pp table_name
    pp(table_contents(table_name))
  end
end

Then /^show me the "([^"]*)" table$/ do |table_name|
  announce table_contents(table_name).to_yaml
end

Given /^the database has a "([^"]*)" table( \(with timestamps\))?:$/ do |table_name, timestamps, table|
  create_table(table_name, timestamps)
  
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

Then /^the "([^"]*)" table should match exactly:$/ do |table_name, table|
  table.diff! table_to_strings(table_contents(table_name)), :surplus_col => true
end

Then /^the "([^"]*)" table should match exactly \(ignoring (ids)?(?: and )?(timestamps)?\):$/ do |table_name, ids, timestamps, table|
  table.diff! table_to_strings(table_contents(table_name, :ids => !ids, :timestamps => !timestamps)), :surplus_col => true
end

When /^I destroy record (\d+) from the "([^"]*)" table$/ do |id, table_name|
  class_for_table(table_name).destroy(id)
end

Then /^the data in the dumped "([^"]*)" yaml files should match the database contents$/ do |table_name|
  records = class_for_table(table_name).all
  fixtures = fixtures_for_table(table_name)
  records.count.should == fixtures.length
  records.each {|record| match_fixture_file_against_record(record)}
end

module FixtureHelpers
  def fixture_path_for(record)
    fixture_id_path = ("%08d" % record.id).scan(/..../).join('/')
    File.join current_dir, "db/dump", record.class.table_name, "#{fixture_id_path}.yml"
  end

  def replace_record_with_fixture!(record)
    require 'active_record/fixtures'
    fixture_path =fixture_path_for(record)
    fixture = ActiveRecord::Fixture.new(YAML.load(File.read(fixture_path)), record.class)
    record.destroy
    ActiveRecord::Base.connection.insert_fixture fixture, record.class.table_name
    record.class.find(record.id)
  end
  
  def match_fixture_file_against_record(record)
    record.attributes.dup.should == replace_record_with_fixture!(record).attributes
    announce "#{table_name.singularize} #{record.id} data matches its fixture data #{fixture_path_for(record)}" if @announce
  end
  
  def fixtures_for_table(table_name)
    fixtures = Dir.glob File.join(current_dir, "db/dump", table_name, '**', '*.yml')
    announce "Fixtures for #{table_name}:\n#{fixtures.join("\n")}\n" if @announce
    fixtures
  end
end
World(FixtureHelpers)

module DatabaseHelpers
  def create_table(name, timestamps = false)
    ActiveRecord::Base.connection.create_table name do |t|
      t.timestamps if timestamps
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

  #returns ['table', 'names'] with sqlite adapter
  def db_table_names
    ActiveRecord::Base.connection.tables
  end

  # table_contents 'users' # gives back everything
  # table_contents 'users', :timestamps => false # without timestamps
  # table_contents 'users', :ids => false # without ids
  def table_contents(table_name, opts={:timestamps => true, :ids => true})
    contents = class_for_table(table_name).all.map(&:attributes)
    contents.tap do |contents|
      contents.map{|c| c.delete('id')} unless opts[:ids]
      contents.map{|c| c.delete('updated_at'); c.delete('created_at')} unless opts[:timestamps]
    end
  end
  
  #because cucumber table#diff! expects types to match and step transforms are silly
  def table_to_strings(table)
    table.each do |row|
      row.each_pair do |key, value| 
        row[key] = value.is_a?(Time) ? value.utc.to_s(:db) : value.to_s
      end
    end
  end
end

World(DatabaseHelpers)