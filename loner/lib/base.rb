$stdout.sync = true

Bundler.require
Resque.redis = 'localhost:6379'
Resque.redis.namespace = "resque:resque_plugin_sandbox"
Resque.logger = Logger.new('./log/resque.log')

class Base
  def self.job_queue(*args)
    @queue = :normal
  end

  def self.perform_async(*args)
    @queue = self.job_queue(*args)
    Resque.enqueue(self, *args)
  end

  def self.log!(txt)
    puts("[#{ENV['DYNO']}]: #{txt}")
  end
end

class NormalLifting < Base
  def self.job_queue(primary_id)
    @queue = "serial#{primary_id}"
  end

  def self.perform(primary_id)
    log!("primary_id: #{primary_id}")
  end
end

class ParallelableWorker < Base
  def self.perform
    log!('ParallelableWorker: ok!')
    sleep(2)
  end
end

class BlockingWorker < Base
  def self.perform(primary_id)
    log!('starting BlockingWorker')
    loop do
      result = Resque.redis.sadd("blocked_queues", primary_id)
      if result
        log!('BlockingWorker: ok!')
        sleep(2)
        Resque.redis.srem("blocked_queues", primary_id)
        return
      else
        #log!('waiting...')
      end
    end
  ensure
    Resque.redis.srem("blocked_queues", primary_id)
  end
end
