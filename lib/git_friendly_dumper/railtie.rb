class GitFriendlyDumper
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'git_friendly_dumper/tasks'
    end
  end
end