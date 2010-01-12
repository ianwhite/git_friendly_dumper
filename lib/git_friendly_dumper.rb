require 'fileutils'
require 'active_record/fixtures'
begin; require 'progressbar'; rescue MissingSourceFile; end

# Database independent and git friendly replacement for mysqldump for rails projects
class GitFriendlyDumper
  include FileUtils
  
  attr_accessor :path, :connection, :tables, :force, :include_schema, :show_progress, :clobber_fixtures
  alias_method :include_schema?, :include_schema
  alias_method :clobber_fixtures?, :clobber_fixtures
  alias_method :show_progress?, :show_progress
  alias_method :force?, :force
  
  class << self
    def dump(options = {})
      new(options).dump
    end
  
    def load(options = {})
      new(options).load
    end
  end
  
  def initialize(options = {})
    options.assert_valid_keys(:path, :connection, :connection_name, :tables, :force, :include_schema, :show_progress, :clobber_fixtures)
    
    if options[:show_progress] && !defined?(ProgressBar)
      raise RuntimeError, "GitFriendlyDumper requires the progressbar gem for progress option.\n  sudo gem install progressbar"
    end
    
    self.path             = File.expand_path(options[:path] || 'db/dump')
    self.connection       = options[:connection] || ActiveRecord::Base.establish_connection(options[:connection_name] || Rails.env).connection
    self.tables           = options[:tables]
    self.force            = options.key?(:force) ? options[:force] : false
    self.include_schema   = options.key?(:include_schema) ? options[:include_schema] : false
    self.show_progress    = options.key?(:show_progress) ? options[:show_progress] : false
    self.clobber_fixtures = options.key?(:clobber_fixtures) ? options[:clobber_fixtures] : (options[:tables].blank? ? true : false)
  end
  
  def dump
    self.tables ||= db_tables
    tables.delete('schema_migrations') unless include_schema?
    if force? || (tables & fixtures_tables).empty? || confirm?(:dump)
      puts "Dumping data#{' and structure' if include_schema?} from #{current_database_name} to #{path.sub("#{RAILS_ROOT}/",'')}\n"
      clobber_all_fixtures if clobber_fixtures?
      connection.transaction do
        tables.each {|table| dump_table(table) }
      end
    end
  end
  
  def load
    self.tables ||= fixtures_tables
    tables.delete('schema_migrations') unless include_schema?
    if force? || (tables & db_tables).empty? || confirm?(:load)
      puts "Loading data#{' and structure' if include_schema?} into #{current_database_name} from #{path.sub("#{RAILS_ROOT}/",'')}\n"
      connection.transaction do
        tables.each {|table| load_table(table) }
      end
    end
  end

private
  def current_database_name
    @current_database_name ||= (connection.respond_to?(:current_database) && connection.current_database) || RAILS_ENV
  end
  
  def confirm?(type)
    dump_path = path.sub("#{RAILS_ROOT}/", '')
    if clobber_fixtures? && type == :dump
      puts "\nWARNING: all fixtures in #{dump_path}"
    else
      puts "\nWARNING: the following #{type == :dump ? 'fixtures' : 'tables'} in #{type == :dump ? dump_path : current_database_name}:"
      puts "  " + tables.join("\n  ")
    end
    puts "will be replaced with #{type == :dump ? 'records' : 'fixtures'}#{' and table schemas' if include_schema?} from #{type == :dump ? current_database_name : dump_path}."
    puts "Do you wish to proceed? (type 'yes' to proceed)"
    returning $stdin.gets.downcase.strip == 'yes' do |proceed|
      puts "#{type.to_s.capitalize} cancelled at user's request." unless proceed
    end
  end

  def fixtures_tables
    @fixture_tables ||= Dir[File.join(path, '*')].select{|f| File.directory?(f)}.map{|f| File.basename(f)}
  end
  
  def db_tables
    @db_tables ||= connection.tables
  end
  
  def dump_table(table)
    clobber_fixtures(table)
    records = connection.select_all "SELECT * FROM %s" % table
    show_progress? && (progress_bar = ProgressBar.new(table, records.length))
    records.each_with_index do |record, index|
      id = record['id'] ? record['id'].to_i : index + 1
      fixture_file = File.join(path, table, *id_path(id)) + ".yml"
      `mkdir -p #{File.dirname(fixture_file)}`
      File.open(fixture_file, "w") do |record_file|
        record_file.write record.to_yaml
      end
      show_progress? && progress_bar.inc
    end
    show_progress? && progress_bar.finish
    dump_table_schema(table) if include_schema?
  rescue Exception => e
    puts "dumping #{table} failed: #{e.message}"
  end
  
  def load_table(table)
    # create a placeholder AR class for the table without loading anything from the app.
    klass = eval "class #{table.classify} < ActiveRecord::Base; end"
    include_schema? ? load_table_schema(table) : clobber_records(table)
    files = Dir[File.join(path, table, '*.yml')]
    show_progress? && (progress_bar = ProgressBar.new(table, files.length))
    files.each do |file|
      fixture = Fixture.new(YAML.load(File.read(file)), klass)
      connection.insert_fixture fixture, table
      show_progress? && progress_bar.inc
    end
    show_progress? && progress_bar.finish
  rescue Exception => e
    puts "loading #{table} failed: #{e.message}"
    puts e.backtrace
  end
  
  def dump_table_schema(table)
    File.open(File.join(path, table, 'schema.rb'), "w") do |schema_file|
      if table == 'schema_migrations'
        schema_file.write schema_migrations_schema
      else
        schema_dumper.send :table, table, schema_file
      end
    end
  end

  def schema_migrations_schema
    <<-end_eval
  create_table "schema_migrations", :force => true, :id => false do |t|
    t.string "version", :null => false
  end
  add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
    end_eval
  end
  
  def schema_dumper
    @schema_dumper ||= ActiveRecord::SchemaDumper.send :new, @connection
  end
  
  def load_table_schema(table)
    schema_definition = File.read(File.join(path, table, 'schema.rb'))
    ActiveRecord::Migration.suppress_messages do 
      ActiveRecord::Schema.define do
        eval schema_definition
      end
    end
  end

  def clobber_fixtures(table)
    `rm -rf #{File.join(path, table)}`
    `mkdir -p #{File.join(path, table)}`
  end
  
  def clobber_all_fixtures
    fixtures_tables.each {|table| clobber_fixtures(table)}
  end
  
  def clobber_records(table)
    connection.delete "DELETE FROM #{table}"
  end
  
  # Partitions the given id into an array of path components.
  #
  # For example, given an id of 1
  # <tt>["0000", "0001"]</tt>
  #
  # Currently only integer ids are supported
  def id_path(id)
    ("%08d" % id).scan(/..../)
  end
end