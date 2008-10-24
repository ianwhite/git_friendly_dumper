require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require 'git_friendly_dumper'

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
      ActiveRecord::Migrator.migrate(File.join(File.dirname(__FILE__), '../resources/migrate'), version)
    end
  end
  
  def remove_dump(path = @path)
    rm_rf @path
  end
  
  def dump_files_set(path = @path)
    Dir["#{path}/**/*"].map{|f| f.sub("#{path}/", '')}.to_set
  end
  
  def random_string
    (10..rand(100)+20).inject(''){|s,i| s << (rand(26) + 'a'[0]).chr }
  end
  
  def connection
    ActiveRecord::Base.connection
  end
  
  describe 'GitFriendlyDumper' do
    include GitFriendlyDumperSpec

    before do
      reset_db
      @path = File.join(File.dirname(__FILE__), '../resources/dump')
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
        @first1   = First.create!(:name => random_string)
        @first2   = First.create!(:name => random_string)
        @second1  = Second.create!(:name => random_string)
        @second2  = Second.create!(:name => random_string)
      end
  
      it "connection should have tables == ['firsts', 'seconds', 'schema_migrations']" do
        ActiveRecord::Base.connection.tables.to_set.should == ['firsts', 'seconds', 'schema_migrations'].to_set
      end

      describe "when dump files do not exist", :shared => true do
        it "should not require confirmation on dump" do
          $stdin.should_not_receive(:gets)
          @dumper.dump
        end
      end

      describe "when dump files exist", :shared => true do
        it "should require confirmation, and not proceed if not 'yes'" do
          $stdin.should_receive(:gets).and_return("\n")
          @dumper.should_not_receive(:dump_table)
          @dumper.dump
        end

        it "should require confirmation, and proceed if 'yes'" do
          $stdin.should_receive(:gets).and_return("yes\n")
          @dumper.should_receive(:dump_table).any_number_of_times
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
      
        it "should create only dump/firsts and dump/seconds with record fixtures" do
          @dumper.dump
          dump_files_set.should == [
            'firsts', 'firsts/00000001.yml', 'firsts/00000002.yml',
            'seconds', 'seconds/00000001.yml', 'seconds/00000002.yml'
          ].to_set
        end
    
        it "should contain correct fixture data" do
          @dumper.dump
          File.read("#{@path}/firsts/00000001.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=1").to_yaml
          File.read("#{@path}/firsts/00000002.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=2").to_yaml
          File.read("#{@path}/seconds/00000001.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=1").to_yaml
          File.read("#{@path}/seconds/00000002.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=2").to_yaml
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
      
        it "should create only dump/firsts, dump/seconds dump/schema_migrations, with record fixtures, and table schemas" do
          @dumper.dump
          dump_files_set.should == [
            'firsts', 'firsts/00000001.yml', 'firsts/00000002.yml', 'firsts/schema.rb',
            'seconds', 'seconds/00000001.yml', 'seconds/00000002.yml', 'seconds/schema.rb',
            'schema_migrations', 'schema_migrations/00000001.yml', 'schema_migrations/00000002.yml', 'schema_migrations/schema.rb'
          ].to_set
        end
    
        it "should contain correct fixture data" do
          @dumper.dump
          File.read("#{@path}/firsts/00000001.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=1").to_yaml
          File.read("#{@path}/firsts/00000002.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=2").to_yaml
          File.read("#{@path}/seconds/00000001.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=1").to_yaml
          File.read("#{@path}/seconds/00000002.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=2").to_yaml
        end
      end
    end
  
    describe "when fixtures exist" do
      before do
        migrate_up(20070101010000)
        @first1   = First.create!(:name => random_string)
        @first2   = First.create!(:name => random_string)
        @second1  = Second.create!(:name => random_string)
        @second2  = Second.create!(:name => random_string)
        GitFriendlyDumper.dump :include_schema => true, :force => true, :path => @path
        reset_db
      end
      
      describe "when db data does not exist", :shared => true do
        it "should not require confirmation on load" do
          $stdin.should_not_receive(:gets)
          @dumper.load
        end
      end

      describe "when db data exists", :shared => true do
        it "should require confirmation, and not proceed if not 'yes'" do
          $stdin.should_receive(:gets).and_return("\n")
          @dumper.should_not_receive(:load_table)
          @dumper.load
        end

        it "should require confirmation, and proceed if 'yes'" do
          $stdin.should_receive(:gets).and_return("yes\n")
          @dumper.should_receive(:load_table).any_number_of_times
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
    end
  end
end