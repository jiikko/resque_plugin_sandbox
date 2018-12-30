$stdout.sync = true

Bundler.require
Resque.redis = 'localhost:6379'
Resque.redis.namespace = "resque:resque_plugin_sandbox"
#Resque.logger = Logger.new(STDOUT)

class Base
  def self.perform_async(*args)
    @queue = self.job_queue(*args)
    Resque.enqueue(self, *args)
  end
end

class NormalLifting < Base
  def self.job_queue(primary_id)
    @queue = "serial#{primary_id}"
  end

  def self.perform(primary_id)
    puts "#{ENV['DYNO']} primary_id: #{primary_id}"
  end
end
