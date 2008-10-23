require 'fileutils'
require 'active_record/fixtures'
begin; require 'progressbar'; rescue MissingSourceFile; end

# Database independent and git friendly replacement for mysqldump for rails projects
class GitFriendlyDumper
  include FileUtils
  
  def self.dump(options = {})
    new(options).dump
  end
  
  def self.load(options = {})
    new(options).load
  end
  
  def initialize(options = {})
    if options[:progress] && !defined?(ProgressBar)
      raise RuntimeError, "GitFriendlyDumper requires the progressbar gem for progress option.\n  sudo gem install progressbar"
    end
    
    @path       = File.expand_path(options[:path] || 'db/dump')
    @connection = options[:connection] || ActiveRecord::Base.establish_connection(options[:connection_name] || Rails.env).connection
    @tables     = options[:tables]
    @force      = options.key?(:force) ? options[:force] : false
    @schema     = options.key?(:schema) ? options[:schema] : false
    @progress   = options.key?(:progress) ? options[:progress] : false
  end
  
  def dump
    tables = @tables || @connection.tables
    tables.delete('schema_migrations') unless @schema
    @connection.transaction do
      tables.each do |table|
        dump_table table
      end
    end
  end
  
  def load
    tables = @tables || Dir[File.join(path, '*')].select{|f| File.directory?(f)}.map{|f| File.basename(f)}
    tables.delete('schema_migrations') unless @schema
    @connection.transaction do
      tables.each do |table|
        load_table table
      end
    end
  end

protected
  def dump_table(table)
    ensure_empty_table_path(table)
    
    records = @connection.select_all "SELECT * FROM %s" % table
    @progress && (progress_bar = ProgressBar.new(table, records.length))
    
    dump_table_schema(table) if @schema
    
    id = 0
    records.each do |record|
      id = record['id'] ? record['id'].to_i : id + 1
      File.open(File.join(@path, table, "%08d.yml" % id), "w") do |record_file|
        record_file.write(record.to_yaml)
      end
      @progress && progress_bar.inc
    end
    
    @progress && progress_bar.finish
  end
  
  def load_table(table)
   ensure_no_table(table)
   files = Dir[File.join(@path, table, '*.yml')]
   
   @progress && (progress_bar = ProgressBar.new(table, records.length))
   
   load_table_schema(table) if @schema
   
   files.each do |file|
     fixture = Fixture.new(YAML.load(File.read(file)), table.classify)
     @connection.insert_fixture fixture, table
     @progress and progress_bar.inc
   end
   
   @progress and progress_bar.finish
  end
  
  def dump_table_schema(table)
    if table == 'schema_migrations'
      dump_schema_migrations_table_schema
    else
      File.open(File.join(@path, table, 'schema.rb'), "w") do |schema_file|
        schema_dumper.send :table, table, schema_file
      end
    end
  end
  
  def dump_schema_migrations_table_schema
    File.open(File.join(@path, 'schema_migrations', 'schema.rb'), "w") do |schema_file|
      schema_file <<-end_eval
  create_table(:schema_migrations, :id => false) do |t|
    t.column :version, :string, :null => false
  end
  add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
      end_eval
    end
  end
  
  def schema_dumper
    @schema_dumper ||= ActiveRecord::SchemaDumper.send :new, self.connection
  end
  
  def load_table_schema(table)
    schema_definition = File.read(File.join(@path, table, 'schema.rb'))
    ActiveRecord::Schema.define do
      eval schema_definition
    end
  end
  
  def ensure_empty_table_path(table)
    table_path = File.join(@path, table)
    if File.exists?(table_path)
      if @force
        rm_rf table_path
      else 
        raise "#{table} dump already exists in #{table_path}"
      end
    end
    mkdir_p table_path
  end

  def ensure_no_table(table)
    if @connection.tables.include?(table)
      raise "#{table} exists in database #{@connection.database}" unless @force
    end
  end
end