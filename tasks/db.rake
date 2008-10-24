namespace :db do
  desc "dump structure and data to db/dump (DUMP_PATH)"
  task :dump => :environment do
    GitFriendlyDumper.dump gfd_options.merge(:include_schema => true)
  end
  
  desc "replace database with data and stucture in db/dump (DUMP_PATH)"
  task :load => :environment do
    GitFriendlyDumper.load gfd_options.merge(:include_schema => true)
  end

  namespace :data do
    desc "dump table data to db/dump (DUMP_PATH)"
    task :dump => :environment do
      GitFriendlyDumper.dump gfd_options.merge(:include_schema => false)
    end
    
    desc "load table data from db/dump (DUMP_PATH)"
    task :load => :environment do
      GitFriendlyDumper.load gfd_options.merge(:include_schema => false)
    end
  end
  
  def gfd_options
    { :tables         => ENV['TABLES'],
      :path           => ENV['DUMP_PATH'] || 'db/dump',
      :force          => ENV['FORCE'] || false,
      :include_schema => ENV['SCHEMA'] || false,
      :show_progress  => ENV['PROGRESS'] || true }
  end
end
