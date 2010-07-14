# All of these tasks can be modified with these environment vars:
#
#  DUMP_PATH=some/path    where the dump is         (default db/dump)
#  TABLES=comma,sep,list  tables to dump/load       (default all)
#  FORCE=true|1           answer 'yes'              (default false)
#  PROGRESS=false|0       show progress             (default true)
#  CLOBBER=false|0        clobber fixtures on dump  (default true)
#
require 'git_friendly_dumper'

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
    { 
      :tables           => ENV['TABLES'].present? && ENV['TABLES'].split(',').map(&:squish),
      :path             => ENV['DUMP_PATH'] || 'db/dump',
      :force            => ['1', 'true'].include?(ENV['FORCE']) ? true : false,
      :include_schema   => ['1', 'true'].include?(ENV['SCHEMA']) ? true : false,
      :show_progress    => ['0', 'false'].include?(ENV['PROGRESS']) ? false : true,
      :clobber_fixtures => ['1', 'true'].include?(ENV['CLOBBER']) ? true : false,
      :limit            => ENV['LIMIT'] || 2500,
      :raise_error      => ['0', 'false'].include?(ENV['RAISE_ERROR']) ? false : true,
      :fixtures         => ENV['FIXTURES'] && ENV['FIXTURES'].split(',').map()
    }
  end
end
