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
      migrate_up(2)
      @path = File.join(File.dirname(__FILE__), '../resources/dump')
      remove_dump
    end
    
    it "connection should have tables == ['firsts', 'seconds', 'schema_migrations']" do
      ActiveRecord::Base.connection.tables.to_set.should == ['firsts', 'seconds', 'schema_migrations'].to_set
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
      
      it ".new :progress => true should raise error" do
        lambda { GitFriendlyDumper.new :progress => true }.should raise_error(RuntimeError)
      end
    end
  
    describe "(when db data exists)" do
      before do
        @first1   = First.create!(:name => random_string)
        @first2   = First.create!(:name => random_string)
        @second1  = Second.create!(:name => random_string)
        @second2  = Second.create!(:name => random_string)
      end
  
      describe "dump :schema => false" do
        before do
          @dumper = GitFriendlyDumper.new :schema => false, :path => @path
        end
    
        it "should not require confirmation on dump, as dumps is empty" do
          @dumper.should_not_receive(:gets)
          @dumper.dump
        end
      
        describe "(when dump files exist)" do
          before do
            mkdir_p "#{@path}/firsts"
          end
        
          it "should require confirmation, and not proceed if not 'yes'" do
            @dumper.should_receive(:gets).and_return("\n")
            @dumper.should_not_receive(:dump_table)
            @dumper.dump
          end
        
          it "should require confirmation, and proceed if 'yes'" do
            @dumper.should_receive(:gets).and_return("yes\n")
            @dumper.should_receive(:dump_table).with('firsts')
            @dumper.should_receive(:dump_table).with('seconds')
            @dumper.dump
          end
        
          describe ", but :force => true" do
            before do
              @dumper = GitFriendlyDumper.new :schema => false, :path => @path, :force => true
            end
          
            it "should not ask for confirmation" do
              @dumper.should_not_receive(:gets)
              @dumper.dump
            end
          end
        end
      
        it "should create only dump/firsts and dump/seconds with record fixtures" do
          @dumper.dump
          dump_files_set.should == ['firsts', 'firsts/00000001.yml', 'firsts/00000002.yml', 'seconds', 'seconds/00000001.yml', 'seconds/00000002.yml'].to_set
        end
    
        it "should contain correct fixture data" do
          @dumper.dump
          File.read("#{@path}/firsts/00000001.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=1").to_yaml
          File.read("#{@path}/firsts/00000002.yml").should  == connection.select_one("SELECT * FROM firsts WHERE id=2").to_yaml
          File.read("#{@path}/seconds/00000001.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=1").to_yaml
          File.read("#{@path}/seconds/00000002.yml").should == connection.select_one("SELECT * FROM seconds WHERE id=2").to_yaml
        end
      end
    
      #describe 
      #  it "then load :schema => false, should require confirmation from user" do
      #    dumper = GitFriendlyDumper.new(:schema => false, :path => @path)
      #    dumper.should_receive(:gets).once
      #    dumper.load
      #  end
      #    
      #  #it "then, load :schema => false, should return database to original state" do
      #  #  GitFriendlyDumper.load :schema => false, :path => @path
      #  #  First.find(1).should  == @first1
      #  #  First.find(2).should  == @first2
      #  #  Second.find(1).should == @second1
      #  #  Second.find(2).should == @second2
      #  #end
      #end
    end
  end
end