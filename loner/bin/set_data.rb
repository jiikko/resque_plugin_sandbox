# File.write 'f', 1.upto(19).map { |x| 10.times.map { "NormalLifting.perform_async(#{x})" } }.flatten.join("\n")
Bundler.require
require './lib/base'

10.times do
  BlockingWorker.perform_async(1)
  BlockingWorker.perform_async(2)
end

puts Resque.sample_queues
