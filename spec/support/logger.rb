require 'logger'

logFile = File.open(File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'test.log'), 'w')

ActiveRecord::Base.logger = Logger.new(logFile)