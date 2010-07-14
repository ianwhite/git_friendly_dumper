require 'logger'
require 'active_record'

log_filename = File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'test.log')
`mkdir -p #{File.dirname(log_filename)}`
log_file = File.open(log_filename, 'w')
ActiveRecord::Base.logger = Logger.new(log_file)