require 'fileutils'
require 'active_record/fixtures'
begin; require 'progressbar'; rescue MissingSourceFile; end

# Database independent and git friendly replacement for mysqldump for rails projects
class GitFriendlyDumper
  include FileUtils
  
  attr_accessor :root, :path, :connection, :tables, :force, :include_schema, :show_progress, :clobber_fixtures, :limit, :raise_error, :fixtures
  alias_method :include_schema?, :include_schema
  alias_method :clobber_fixtures?, :clobber_fixtures
  alias_method :show_progress?, :show_progress
  alias_method :force?, :force
  alias_method :raise_error?, :raise_error
  
  class << self
    def dump(options = {})
      new(options).dump
    end
  
    def load(options = {})
      new(options).load
    end
  end
  
  def initialize(options = {})
    options.assert_valid_keys(:root, :path, :connection, :connection_name, :tables, :force, :include_schema, :show_progress, :clobber_fixtures, :limit, :raise_error, :fixtures)

    self.root = options[:root] || (defined?(Rails) && Rails.root) || pwd
    
    if options[:fixtures] && (options[:include_schema] || options[:clobber_fixtures])
      puts options.to_yaml
      raise ArgumentError, "GitFriendlyDumper if :fixtures option given, neither :include_schema, or :clobber_fixtures can be given"
    end
    
    if options[:show_progress] && !defined?(ProgressBar)
      raise RuntimeError, "GitFriendlyDumper requires the progressbar gem for progress option.\n  sudo gem install progressbar"
    end
    
    self.path             = File.expand_path(options[:path] || 'db/dump')
    self.tables           = options[:tables]
    self.fixtures         = options[:fixtures]
    self.limit            = options.key?(:limit) ? options[:limit].to_i : 2500
    self.raise_error      = options.key?(:raise_error) ? options[:raise_error] : true
    self.force            = options.key?(:force) ? options[:force] : false
    self.include_schema   = options.key?(:include_schema) ? options[:include_schema] : false
    self.show_progress    = options.key?(:show_progress) ? options[:show_progress] : false
    self.clobber_fixtures = options.key?(:clobber_fixtures) ? options[:clobber_fixtures] : (options[:tables].blank? ? true : false)
    self.connection       = options[:connection] || begin
      if options[:connection_name]
        ActiveRecord::Base.establish_connection(options[:connection_name])
      end
      ActiveRecord::Base.connection
    end
  end
  
  def dump
    if fixtures
      raise ArgumentError, "Cannot dump when :fixtures option is given"
    end
    self.tables ||= db_tables
    tables.delete('schema_migrations') unless include_schema?
    if force? || (tables & fixtures_tables).empty? || confirm?(:dump)
      puts "Dumping data#{' and structure' if include_schema?} from #{current_database_name} to #{path.sub("#{root}/",'')}\n"
      clobber_all_fixtures if clobber_fixtures?
      connection.transaction do
        tables.each {|table| dump_table(table) }
      end
    end
  end
  
  def load
    fixtures ? load_fixtures : load_tables
  end

private
  def current_database_name
    @current_database_name ||= (connection.respond_to?(:current_database) && connection.current_database)
  end
  
  def confirm?(type)
    dump_path = path.sub("#{root}/", '')
    if clobber_fixtures? && type == :dump
      puts "\nWARNING: all fixtures in #{dump_path}"
    else
      puts "\nWARNING: the following #{type == :dump ? 'fixtures' : 'tables'} in #{type == :dump ? dump_path : current_database_name}:"
      puts "  " + tables.join("\n  ")
    end
    if fixtures
      puts "will have records replaced by the specified #{fixtures.length} fixtures (deleting if fixture file is missing)"
    else
      puts "will be replaced with #{type == :dump ? 'records' : 'fixtures'}#{' and table schemas' if include_schema?} from #{type == :dump ? current_database_name : dump_path}."
    end
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
  
  def load_tables
    self.tables ||= fixtures_tables
    tables.delete('schema_migrations') unless include_schema?
    if force? || (tables & db_tables).empty? || confirm?(:load)
      puts "Loading data#{' and structure' if include_schema?} into #{current_database_name} from #{path.sub("#{root}/",'')}\n"
      connection.transaction do
        tables.each {|table| load_table(table) }
      end
    end
  end
  
  def load_fixtures
    fixtures_tables = []
    fixtures.map! do |fixture|
      raise ArgumentError, "Fixture filename error: #{fixture} should be a relative filename e.g. users/0000/0001.yml" unless fixture =~ /^\w+\/\d+\/\d+\.yml$/
      table = fixture.split('/').first
      if (!tables || tables.include?(table))
        unless fixtures_tables.include?(table)
          klass = eval "class #{table.classify} < ActiveRecord::Base; end"
          fixtures_tables << table
        end
        fixture
      end
    end
  
    self.tables = fixtures_tables
  
    if force? || (tables & db_tables).empty? || confirm?(:load)
      puts "Loading fixtures into #{current_database_name} from #{path.sub("#{root}/",'')}\n"
      show_progress? && (progress_bar = ProgressBar.new("fixtures", fixtures.length))
      connection.transaction do
        fixtures.each do |fixture|
          match_data = fixture.match(/(\w+)\/(.+)\.yml/)
          table, id, file = match_data[1], match_data[2].sub('/','').to_i, File.join(path, fixture)
          
          raise "Couldn't determine id from #{fixture} (id was #{id})" if id < 1
          connection.delete("DELETE FROM #{table} WHERE id=#{id};")
          load_fixture(table.classify.constantize, table, file) if File.exist?(file)
          show_progress? && progress_bar.inc
        end
      end
      show_progress && progress_bar.finish
    end
  end
  
  def dump_table(table)
    clobber_fixtures_for_table(table)
    count = connection.select_value("SELECT COUNT(*) FROM %s" % table).to_i
    show_progress? && (progress_bar = ProgressBar.new(table, count))
    
    offset = 0
    while (records = select_records(table, offset)).any?
      dump_records(table, records, show_progress? && progress_bar)
      offset += limit
    end
    
    show_progress? && progress_bar.finish
    dump_table_schema(table) if include_schema?
  rescue ActiveRecord::ActiveRecordError => e
    puts "dumping #{table} failed: #{e.message}"
    raise e if raise_error?
  end
  
  def select_records(table, offset)
    connection.select_all("SELECT * FROM %s LIMIT #{limit} OFFSET #{offset}" % table)
  end
  
  def dump_records(table, records, progress_bar)
    records.each_with_index do |record, index|
      id = record['id'] ? record['id'].to_i : index + 1
      fixture_file = File.join(path, table, *id_path(id)) + ".yml"
      `mkdir -p #{File.dirname(fixture_file)}`
      File.open(fixture_file, "w") do |record_file|
        record_file.write record.to_yaml
      end
      show_progress? && progress_bar.inc
    end
  end
  
  def load_table(table)
    # create a placeholder AR class for the table without loading anything from the app.
    klass = eval "class #{table.classify} < ActiveRecord::Base; end"
    include_schema? ? load_table_schema(table) : clobber_records(table)
    files = Dir[File.join(path, table, '**', '*.yml')]
    show_progress? && (progress_bar = ProgressBar.new(table, files.length))
    files.each do |file|
      load_fixture(klass, table, file)
      show_progress? && progress_bar.inc
    end
    show_progress? && progress_bar.finish
  rescue ActiveRecord::ActiveRecordError => e
    puts "loading #{table} failed - check log for details"
    raise e if raise_error?
  end
  
  def load_fixture(klass, table, file)
    fixture = Fixture.new(YAML.load(File.read(file)), klass)
    begin
      connection.insert_fixture fixture, table
    rescue ActiveRecord::ActiveRecordError => e
      puts "loading fixture #{file} failed - check log for details"
      raise e if raise_error?
    end
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

  def clobber_fixtures_for_table(table)
    `rm -rf #{File.join(path, table)}`
    `mkdir -p #{File.join(path, table)}`
  end
  
  def clobber_all_fixtures
    fixtures_tables.each {|table| clobber_fixtures_for_table(table)}
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