namespace :db do
  desc "dump structure and data to db/dump (DUMP_PATH)"
  task :dump => :environment do
    GitFriendlyDumper.dump gfd_options.merge(:schema => true)
  end
  
  desc "replace database with data and stucture in db/dump (DUMP_PATH)"
  task :load => :environment do
    GitFriendlyDumper.load gfd_options.merge(:schema => true)
  end

  namespace :data do
    desc "dump table data to db/dump (DUMP_PATH)"
    task :dump do
      GitFriendlyDumper.dump gfd_options.merge(:schema => false)
    end
    
    desc "load table data from db/dump (DUMP_PATH)"
    task :load do
      GitFriendlyDumper.load gfd_options.merge(:schema => false)
    end
  end
  
  def gfd_options
    { :tables   => ENV['TABLES'],
      :path     => ENV['DUMP_PATH'] || 'db/dump',
      :force    => ENV['FORCE'] || false,
      :schema   => ENV['SCHEMA'] || false,
      :progress => ENV['PROGRESS'] || true }
  end
end
