require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require 'git_friendly_dumper'

describe 'GitFriendlyDumper' do
  describe "when progressbar not installed" do
    before do
      @progress_bar_class = ProgressBar
      Object.send :remove_const, 'ProgressBar'
    end
    
    it ".new :progress => true should raise error" do
      lambda { GitFriendlyDumper.new :progress => true }.should raise_error(RuntimeError)
    end
    
    after do
      ProgressBar = @progress_bar_class
    end
  end
  
  describe "re: migrations" do
    before do
      reset_db
      remove_dump
    end
  
    describe "when migrated to firsts" do
      before do
        migrate_up(1)
      end
    
      it "connection should have tables == ['firsts', 'schema_migrations']" do
        ActiveRecord::Base.connection.tables.should == ['firsts', 'schema_migrations']
      end
    end
  end
end