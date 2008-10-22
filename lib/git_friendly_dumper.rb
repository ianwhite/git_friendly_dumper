# Database independent dump/load
class GitFriendlyDupmper
  attr_accessor :path, :connection, :tables, :force
  
  def initialize(options = {})
    if options[:progress]
      begin
        require 'progressbar'
        @progress = {}
      rescue Exception
        warn "GitFriendlyDupmper requires the progressbar gem for progress option.\n\nsudo gem install progressbar."
      end
    end
    
    self.path       = File.expand_path(options[:path] || 'db/git_friendly_dumper')
    self.connection = options[:connection] || ActiveRecord::Base.establish_connection(options[:connection_name] || Rails.env)
    self.tables     = options[:tables]
    self.force      = options.key?(:force) ? options[:force] : false
  end
  
  def dump
    tables = self.tables || self.connection.tables
    self.connection.transaction do
      tables.each do |table|
        dump_table table
      end
    end
  end
  
  def load
    tables = self.tables || Dir[File.join(path, '*')].select{|f| File.directory?(f)}.map({|f| File.basename(f)})
    
    if !self.force && (self.connection.tables & self.tables).any?
      raise "Tables #{(self.connection.tables & self.tables).to_sentence} already exist"
    end
    
    load_schema if self.structure
    
    self.connection.transaction do
      tables.each do |table|
        files = Dir[File.join(path, table, '*')]
        self.connection.execute("DELETE FROM %s" % table)
        progress = ProgressBar.new(table, files.length)
        files.each do |file|
          fixture = Fixture.new(YAML.load(File.read(file)), table.classify)
          self.connection.insert_fixture fixture, table
          progress.inc
        end
        progress.finish
      end
    end
  end

protected
  def begin_progress(name, total)
    @progress and @progress[name] = ProgressBar.new(name, total)
  end

  def increment_progress(name)
    @progress and @progress[name].inc
  end

  def finish_progress(name)
    @progress and @progress.finish
  end

  def dump_table(table)
    ensure_empty_table_path(table)
    records = self.connection.select_all "SELECT * FROM %s" % table
    begin_progress(table, records.length)
    dump_table_schema(table)
    records.each do |record|
      File.open(File.join(self.path, table, "%08d.yml" % record['id'].to_i), "w") do |record_file|
        record_file.write(record.to_yaml)
      end
      increment_progress(table)
    end
    finish_progress(table)
  end
  
  def load_table(table)
   ensure_no_table(table)
   files = Dir[File.join(path, table, '*')]
   begin_progress(table, files.length)
   load_table_schema(table)
   files.each do |file|
     fixture = Fixture.new(YAML.load(File.read(file)), table.classify)
     self.connection.insert_fixture fixture, table
     increment_progress(table)
   end
   finish_progress(table)
  end
  
  def dump_table_schema(table)
    File.open(File.join(self.path, 'schema.rb'), "w") do |schema_file|
      dumper = ActiveRecord::SchemaDumper.new(self.connection, schema_file)
      dumper.send :table, table
    end
  end
  
  
  def load_table_schema(table)
    ActiveRecord::Schema.define do
      eval File.read(File.join(self.path, table, 'schema.rb'))
    end
  end
  
  def ensure_empty_table_path(table)
    table_path = File.join(self.path, table)
    if File.exists?(table_path)
      if self.force
        rm_rf table_path
      else 
        raise "#{table} dump already exists in #{table_path}"
      end
    end
    mkdir_p table_path
  end

  def ensure_no_table(table)
    if self.connection.tables.include?(table)
      raise "#{table} exists in database #{connection.database}" unless self.force
    end
  end
end