garlic do
  # this plugin
  repo "git_friendly_dumper", :path => '.'
  
  # other repos
  repo "rails", :url => "git://github.com/rails/rails"
  repo "rspec", :url => "git://github.com/dchelimsky/rspec"
  repo "rspec-rails", :url => "git://github.com/dchelimsky/rspec-rails"
  
  # target railses
  ['master', '2-2-stable'].each do |rails|
    
    # declare how to prepare, and run each CI target
    target rails, :tree_ish => "origin/#{rails}" do
      prepare do
        plugin "git_friendly_dumper", :clone => true # so we can work in targets
        plugin "rspec"
        plugin "rspec-rails" do
          `script/generate rspec -f`
        end
      end
    
      run do
        cd "vendor/plugins/git_friendly_dumper" do
          sh "rake rcov:verify"
        end
      end
    end
  end
end
