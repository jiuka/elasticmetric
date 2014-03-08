require 'json'
require 'uri'
require 'net/http'
require 'elasticmetric/config'

class ElasticMetric
  class Send

    def initialize
      ElasticMetric::Logging::info('send') { "Initialize" }
      @mutex = Mutex.new
      @queue = []
      config
      @thread = Thread.new do
        run
      end
    end

    def config
      @uri = URI(ElasticMetric::Config['url'])
    end

    def send(metrics)
      ElasticMetric::Logging::info('send') { "Add metrics to queue" }
      @mutex.synchronize do
        @queue << metrics
      end
      if @thread.status == 'sleep'
        @thread.run
      end
    end

    private
    def run
      # Stop the Thread initialy
      Thread.stop
      loop do
        begin
          ElasticMetric::Logging::info('send') { "Queue length #{@queue.length}" }
          if @queue.length > 0
            # Send Metrics one by one
            sendnum = [@queue.length, 5].min
            Net::HTTP.start(@uri.host, @uri.port) do |http|
              sendnum.times do
                metric = @queue[0]
                ret = http.post(@uri.path, metric.to_json, initheader = {'Content-Type' =>'application/json'})
                if ret.code.to_i >= 200 and ret.code.to_i <=300
                  ElasticMetric::Logging::info('send') { "Metric Sent. #{ret.code} #{ret.message}" }
                  @mutex.synchronize do
                    @queue.delete(metric)
                  end
                else
                  ElasticMetric::Logging::info('send') { "Error. #{ret.code} #{ret.message}" }
                  break
                end
              end
            end
            Thread.stop
          else
            # Stop if no metricy remind in queue
            Thread.stop
          end
        rescue => error
          ElasticMetric::Logging::error('send') { error.message }
          Thread.stop
        end

      end
    end

  end
end
