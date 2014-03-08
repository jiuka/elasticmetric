class ElasticMetric
  class Plugin

    # Test if the plugin is able to run and deliver metrics on the
    # Systems its running.
    def self.enable?
      false
    end

    def initialize
      @ready = false
      @data = nil
      @name = self.class.name
      @name.slice! 'ElasticMetric::Plugin::'
      ElasticMetric::Logging::info(@name) { "Plugin initialize" }
      @thread = Thread.new do
        run
      end
    end

    # This function must be provided by plugin to collect the actual data
    def collect
      nil
    end

    # Start the data collection
    def start
      if @thread.status == 'sleep'
        @ready = false
        @thread.run
      end
    end

    # Read the collected values from the plugin
    def read
      if @ready == true and
        return @data
      else
        return nil
      end
    end

    # The main loop of the plugin
    def run
      loop do
        Thread.stop
        begin
          @data = collect
          @ready = true
        rescue => error
          ElasticMetric::Logging::error(@name) { error.message }
        end
      end
    end

  end
end
