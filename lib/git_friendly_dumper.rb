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
    @clobber    = options.key?(:clobber) ? options[:clobber] : true
  end
  
  def dump
    tables = @tables || @connection.tables
    tables.delete('schema_migrations') unless @schema
    if ok_to_dump?(tables)
      clobber_all_fixtures if @clobber
      @connection.transaction do
        tables.each {|table| dump_table(table) }
      end
    end
  end
  
  def load
    tables = @tables || fixtures_tables
    tables.delete('schema_migrations') unless @schema
    if ok_to_load?(tables)
      @connection.transaction do
        tables.each {|table| load_table(table) }
      end
    end
  end

protected
  def ok_to_dump?(tables)
    will_be_clobbered = (tables & fixtures_tables)
    if @force || will_be_clobbered.empty?
      true
    else
      puts "\nWARNING: the following fixtures in #{@path.sub("#{RAILS_ROOT}/",'')}:\n  #{will_be_clobbered.join("\n  ")}\nwill be replaced with data from #{@connection.current_database}.\n\nDo you wish to proceed? (type 'yes' to proceed): "
      if gets.downcase.strip == 'yes'
        true
      else
        puts "Dump cancelled at user's request."
      end
    end
  end
  
  def ok_to_load?(tables)
    will_be_clobbered = (tables & @connection.tables)
    if @force || will_be_clobbered.empty?
      true
    else
      puts "\nWARNING: the following tables in #{@connection.current_database}:\n  #{will_be_clobbered.join("\n  ")}\nwill be replaced with fixtures in #{@path.sub("#{RAILS_ROOT}/",'')}.\n\nDo you wish to proceed? (type 'yes' to proceed): "
      if gets.downcase.strip == 'yes'
        true
      else
        puts "Load cancelled at user's request."
      end
    end
  end

  def fixtures_tables
    @fixture_tables ||= Dir[File.join(@path, '*')].select{|f| File.directory?(f)}.map{|f| File.basename(f)}
  end
  
  def dump_table(table)
    clobber_fixtures(table)
    records = @connection.select_all "SELECT * FROM %s" % table
    @progress && (progress_bar = ProgressBar.new(table, records.length))
    records.each_with_index do |record, index|
      id = record['id'] ? record['id'].to_i : index + 1
      File.open(File.join(@path, table, "%08d.yml" % id), "w") do |record_file|
        record_file.write record.to_yaml
      end
      @progress && progress_bar.inc
    end
    dump_table_schema(table) if @schema
    @progress && progress_bar.finish
  end
  
  def load_table(table)
   @schema ? load_table_schema(table) : clobber_records(table)
   files = Dir[File.join(@path, table, '*.yml')]
   @progress && (progress_bar = ProgressBar.new(table, records.length))
   files.each do |file|
     fixture = Fixture.new(YAML.load(File.read(file)), table.classify)
     @connection.insert_fixture fixture, table
     @progress && progress_bar.inc
   end
   @progress && progress_bar.finish
  end
  
  def dump_table_schema(table)
    File.open(File.join(@path, table, 'schema.rb'), "w") do |schema_file|
      if table == 'schema_migrations'
        schema_file.write schema_migrations_schema
      else
        schema_dumper.send :table, table, schema_file
      end
    end
  end

  def schema_migrations_schema
    <<-end_eval
  create_table(:schema_migrations, :id => false) do |t|
    t.column :version, :string, :null => false
  end
  add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
    end_eval
  end
  
  def schema_dumper
    @schema_dumper ||= ActiveRecord::SchemaDumper.send :new, @connection
  end
  
  def load_table_schema(table)
    schema_definition = File.read(File.join(@path, table, 'schema.rb'))
    ActiveRecord::Schema.define do
      eval schema_definition
    end
  end

  def clobber_fixtures(table)
    rm_rf File.join(@path, table)
    mkdir_p File.join(@path, table)
  end
  
  # clobber all fixtures paths
  def clobber_all_fixtures
    fixtures_tables.each {|table| clobber_fixtures(table)}
  end
  
  def clobber_records(table)
    @connection.execute_sql "DELETE * FROM #{table}"
  end
end