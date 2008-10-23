require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require 'git_friendly_dumper'

module GitFriendlyDumperSpec
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
  
  def remove_dump
    @path = File.join(File.dirname(__FILE__), '../resources/dump')
    `rm -rf #{@path}`
  end
  
  def dump_files_set
    Dir["#{@path}/**/*"].map{|f| f.sub("#{@path}/", '')}.to_set
  end
  
  describe 'GitFriendlyDumper' do
    include GitFriendlyDumperSpec
    
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
  
    it "Rails.env.should == 'test'" do
      Rails.env.should == 'test'
    end
  
    describe "after migrating up to 2" do
      before do
        reset_db
        migrate_up(2)
        remove_dump
      end
      
      it "connection should have tables == ['firsts', 'seconds', 'schema_migrations']" do
        ActiveRecord::Base.connection.tables.to_set.should == ['firsts', 'seconds', 'schema_migrations'].to_set
      end
    
      describe "with some data in firsts and seconds" do
        before do
          First.create!(:name => '1')
          First.create!(:name => '2')
          Second.create!(:name => '3')
          Second.create!(:name => '4')
        end
      
        describe "dump :schema => false" do
          def do_dump
            GitFriendlyDumper.dump :schema => false, :path => @path
          end
        
          it "should create only dump/firsts and dump/seconds with record fixtures" do
            do_dump
            dump_files_set.should == ['firsts', 'firsts/00000001.yml', 'firsts/00000002.yml', 'seconds', 'seconds/00000001.yml', 'seconds/00000002.yml'].to_set
          end
        end
      end
    end
  end
end