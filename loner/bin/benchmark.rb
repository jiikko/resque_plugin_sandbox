Bundler.require
require "open3"
require 'benchmark'
require './lib/base'

WORKERS_COUNT = 5
DATA_SIZE = 10
@will_do_jobs_count = nil

def init
  Resque::Stat.clear(:processed)
  #Resque.logger = Logger.new('./benchmark.log')
  Resque.logger = Logger.new(STDOUT)
end

def set_data
  DATA_SIZE.times do
    BlockingWorker.perform_async(1)
    BlockingWorker.perform_async(2)
  end
  raise('not set data!!!') if Resque.info[:pending].zero?
  @will_do_jobs_count = Resque.info[:pending]
end

def run
  worker_pids = []
  WORKERS_COUNT.times do
    Thread.new do
      worker_pids << spawn("QUEUE=normal INTERVAL=0.1 rake resque:work")
    end
  end

  loop do
    if Resque.info[:processed] == @will_do_jobs_count
      break
    else
      sleep(1)
      next
    end
  end
  worker_pids.each { |pid| Process.kill('TERM', pid) }
end

def show_report(realtime)
jps = (realtime / Resque::Stat.get(:processed))
puts <<~EOH
-----------------
worker count: #{WORKERS_COUNT}
jobs count: #{@will_do_jobs_count}
#{jps} job/s
-----------------
EOH
end


init
set_data
realtime = Benchmark.realtime { run }
show_report(realtime)
