require 'spec_helper'

module GitFriendlyDumperSpec
  include FileUtils
  
  # sample app
  class First < ActiveRecord::Base
  end

  class Second < ActiveRecord::Base
  end

  # spec helper methods
  def reset_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table table
    end
  end

  def migrate_up(version)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migrator.migrate ['spec/resources/migrate'], version
    end
  end
  
  def remove_dump(path = @path)
    rm_rf @path
  end
  
  def dump_files_set(path = @path)
    Dir["#{path}/**/*"].map{|f| f.sub("#{path}/", '')}.to_set
  end
  
  def next_string
    @next ||= 0
    @next += 1
    ['Foo', 'Bar', 'Baz'][rand(3)] + ("%04d" % @next)
  end
  
  def connection
    ActiveRecord::Base.connection
  end
  
  describe 'GitFriendlyDumper' do
    include GitFriendlyDumperSpec

    before do
      reset_db
      @path = File.join(File.dirname(__FILE__), '../../tmp/dump')
      remove_dump
    end
    
    describe "when progressbar not installed" do
      before do
        if defined?(ProgressBar)
          @progress_bar_class = ProgressBar
          Object.send :remove_const, 'ProgressBar'
        end
      end

      after do
        if @progress_bar_class
          ProgressBar = @progress_bar_class
        end
      end
      
      it ":show_progress => true should raise error" do
        lambda { GitFriendlyDumper.new :show_progress => true }.should raise_error(RuntimeError)
      end
    end
    
    describe "when db data exists" do
      before do
        migrate_up(20070101010000)
        First.create!(:name => next_string)
        First.create!(:name => next_string)
        Second.create!(:name => next_string)
        Second.create!(:name => next_string)
      end
  
      it "connection should have tables == ['firsts', 'seconds', 'schema_migrations']" do
        ActiveRecord::Base.connection.tables.to_set.should == ['firsts', 'seconds', 'schema_migrations'].to_set
      end

      shared_examples_for "when dump files do not exist" do
        it "should not require confirmation on dump" do
          $stdin.should_not_receive(:gets)
          @dumper.dump
        end
      end

      shared_examples_for "when dump files exist" do
        it "should require confirmation, and not proceed if not 'yes'" do
          $stdin.should_receive(:gets).and_return("\n")
          @dumper.should_not_receive(:dump_table)
          @dumper.dump
        end

        it "should require confirmation, and proceed if 'yes'" do
          $stdin.should_receive(:gets).and_return("yes\n")
          @dumper.should_receive(:dump_table).at_least(1)
          @dumper.dump
        end

        describe ", but :force => true" do
          before do
            @dumper.force = true
          end

          it "should not ask for confirmation" do
            $stdin.should_not_receive(:gets)
            @dumper.dump
          end
        end
      end

      describe "dump :include_schema => false" do
        before do
          @dumper = GitFriendlyDumper.new :include_schema => false, :path => @path
        end

        it_should_behave_like "when dump files do not exist"
        
        describe "when dump files exist" do
          before { mkdir_p "#{@path}/firsts" }
          it_should_behave_like "when dump files exist"
        end
      
        describe "(after dump)" do
          before do
            @dumper.dump
          end
      
          it "should create only dump/firsts and dump/seconds with record fixtures" do
            dump_files_set.should == [
              'firsts', 'firsts/0000', 'firsts/0000/0001.yml', 'firsts/0000/0002.yml',
              'seconds', 'seconds/0000', 'seconds/0000/0001.yml', 'seconds/0000/0002.yml'
            ].to_set
          end
    
          it "should create fixtures for firsts" do
            File.read("#{@path}/firsts/0000/0001.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=1").to_yaml
            File.read("#{@path}/firsts/0000/0002.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=2").to_yaml
          end
        
          it "should create fixtures for seconds" do
            File.read("#{@path}/seconds/0000/0001.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=1").to_yaml
            File.read("#{@path}/seconds/0000/0002.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=2").to_yaml
          end
        end
      end
      
      describe "dump :include_schema => true" do
        before do
          @dumper = GitFriendlyDumper.new :include_schema => true, :path => @path
        end

        it_should_behave_like "when dump files do not exist"
        
        describe "when dump files exist" do
          before { mkdir_p "#{@path}/firsts" }
          it_should_behave_like "when dump files exist"
        end
      
        describe "(after dump)" do
          before do
            @dumper.dump
          end
      
          it "should create dump/firsts, dump/seconds dump/schema_migrations, with record fixtures, and table schemas" do
            dump_files_set.should == [
              'firsts', 'firsts/0000', 'firsts/0000/0001.yml', 'firsts/0000/0002.yml', 'firsts/schema.rb',
              'seconds', 'seconds/0000', 'seconds/0000/0001.yml', 'seconds/0000/0002.yml', 'seconds/schema.rb',
              'schema_migrations', 'schema_migrations/0000', 'schema_migrations/0000/0001.yml', 'schema_migrations/0000/0002.yml', 'schema_migrations/schema.rb'
            ].to_set
          end

          it "should create fixtures for firsts" do
            File.read("#{@path}/firsts/0000/0001.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=1").to_yaml
            File.read("#{@path}/firsts/0000/0002.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=2").to_yaml
          end
        
          it "should create fixtures for seconds" do
            File.read("#{@path}/seconds/0000/0001.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=1").to_yaml
            File.read("#{@path}/seconds/0000/0002.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=2").to_yaml
          end
        
          it "should create fixtures for schema_migrations" do
            YAML.load(File.read("#{@path}/schema_migrations/0000/0001.yml")).should == {"version" => "20070101000000"}
            YAML.load(File.read("#{@path}/schema_migrations/0000/0002.yml")).should == {"version" => "20070101010000"}
          end
        
          it "should contain create schema for firsts" do
            File.read("#{@path}/firsts/schema.rb").should =~ /create_table "firsts".*string "name"/m
          end
        
          it "should contain create schema for seconds" do
            File.read("#{@path}/seconds/schema.rb").should =~ /create_table "seconds".*string "name"/m
          end

          it "should contain create schema for schema_migrations" do
            File.read("#{@path}/schema_migrations/schema.rb").should =~ /create_table "schema_migrations".*:id => false.*string "version"/m
          end
        end
      end
      
      
      describe "dumping when RAISE_ERROR=false" do
        let(:dumper) {GitFriendlyDumper.new(:include_schema => true, :raise_error => false, :path => @path)}
        subject{ dumper }

        describe "when #dump_records raises a runtime error" do
          before(:each) do
            dumper.should_receive(:dump_records).and_raise(RuntimeError)
          end
          
          it "#dump should raise a runtime error" do
            lambda { dumper.dump }.should raise_error(RuntimeError)                  
          end
        end
        
        describe "when #dump_records raises an ActiveRecord::Error" do
          before(:each) do
            dumper.should_receive(:dump_records).at_least(1).times.and_raise(ActiveRecord::ActiveRecordError)
          end
          
          it "#dump should not raise a runtime error" do
            lambda { dumper.dump }.should_not raise_error
          end
        end
      end
    end
  
    describe "when fixtures exist" do
      before do
        migrate_up(20070101010000)
        First.create!(:name => next_string)
        First.create!(:name => next_string)
        Second.create!(:name => next_string)
        Second.create!(:name => next_string)
        GitFriendlyDumper.dump :include_schema => true, :force => true, :path => @path
        reset_db
      end
      
      shared_examples_for "when db data does not exist" do
        it "should not require confirmation on load" do
          $stdin.should_not_receive(:gets)
          @dumper.load
        end
      end

      shared_examples_for "when db data exists" do
        it "should require confirmation, and not proceed if not 'yes'" do
          $stdin.should_receive(:gets).and_return("\n")
          @dumper.should_not_receive(:load_table)
          @dumper.load
        end

        it "should require confirmation, and proceed if 'yes'" do
          $stdin.should_receive(:gets).and_return("yes\n")
          @dumper.should_receive(:load_table).at_least(1)
          @dumper.load
        end

        describe ", but :force => true" do
          before do
            @dumper.force = true
          end

          it "should not ask for confirmation" do
            $stdin.should_not_receive(:gets)
            @dumper.load
          end
        end
      end
        
      describe "load :include_schema => true" do
        before do
          @dumper = GitFriendlyDumper.new :include_schema => true, :path => @path
        end

        it_should_behave_like "when db data does not exist"
        
        describe "when db data exists" do
          before do
            migrate_up(20070101010000)
          end
          
          it_should_behave_like "when db data exists"
        end
      end
      
      describe "loading when RAISE_ERROR=false" do
        let(:dumper) {GitFriendlyDumper.new(:include_schema => true, :raise_error => false, :path => @path)}
        subject{ dumper }

        describe "when connection raises a runtime error" do
          before(:each) do
            dumper.connection.should_receive(:insert_fixture).and_raise(RuntimeError)
          end
          
          it "#load should raise a runtime error" do
            lambda { dumper.load }.should raise_error(RuntimeError)                  
          end
        end
        
        describe "when connection raises an ActiveRecord::Error" do
          before(:each) do
            dumper.connection.should_receive(:insert_fixture).at_least(1).times.and_raise(ActiveRecord::ActiveRecordError)
          end
          
          it "#load should not raise a runtime error" do
            lambda { dumper.load }.should_not raise_error
          end
        end
      end
    end
  end
end