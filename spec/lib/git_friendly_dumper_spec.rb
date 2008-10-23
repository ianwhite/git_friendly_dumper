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
end