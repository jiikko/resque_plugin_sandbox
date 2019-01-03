Bundler.require
require "open3"
require 'benchmark'
require './lib/base'

WORKERS_COUNT = 5
DATA_SIZE = 10
@will_do_jobs_count = nil

def init
  Resque::Stat.clear(:processed)
end

def set_data
  jobs = []
  DATA_SIZE.times do
    jobs.push(->{ BlockingWorker.perform_async(1) })
    jobs.push(->{ BlockingWorker.perform_async(2) })
    jobs.push(->{ BlockingWorker.perform_async(3) })
    jobs.push(->{ ParallelableWorker })
  end
  jobs.shuffle.each { |j| j.call }
  raise('not set data!!!') if Resque.info[:pending].zero?
  @will_do_jobs_count = Resque.info[:pending]
end

def run
  worker_pids = []
  1.upto(WORKERS_COUNT) do |i|
    worker_pids << spawn("DYNO='worker.#{i}' QUEUE=normal INTERVAL=0.1 bundle exec rake resque:work")
  end

  loop do
    break if Resque::Stat.get(:processed) > 0
    sleep(1)
  end
  loop do
    if Resque.workers.any?(&:working?)
      sleep(1)
      next
    else
      break
    end
  end
  worker_pids.each { |pid| Process.kill('TERM', pid) }
end

# 各ジョブの引数毎に
#   かかった時間を表示したい
#   実行した個数

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
