require 'json'
require 'socket'
require 'date'
require 'elasticmetric/config'
require 'elasticmetric/logging'
require 'elasticmetric/send'

class ElasticMetric

  def initialize
    ElasticMetric::Logging::info "Initialite ElasticMetric"

    # Load Configuration
    _configReload
    _loadPlugins

    @sender = ElasticMetric::Send.new

    # Signal Handling
    Signal.trap('TERM') do
      ElasticMetric::Logging::info "Initialise shutdown"
      @running = false
    end
    Signal.trap('HUP') do
      ElasticMetric::Logging::info "Reload configuration"
      ElasticMetric::Config.load
    end
  end

  def run
    @running = true
    loop do
      ElasticMetric::Logging::info "Loop..."

      # Collect Stats
      metrics = {
        :meta => {
           :timestamp => DateTime.now.iso8601,
            :hostname => Socket.gethostbyname(Socket.gethostname).first,
        }
      }
      @plugins.each { |n,p| p.start }
      sleep 10
      @plugins.each do |name,plugin|
        output = plugin.read
        if output
          metrics[name] = output
        end
      end

      @sender.send(metrics)

      unless @running
        break
      end
    end
  end

  private
  def _configReload
    ElasticMetric::Config.load
  end

  def _loadPlugins
    ElasticMetric::Logging::info "Load Plugins"
    @plugins ||= {}

    plugin_path = File.absolute_path(ElasticMetric::Config['plugindir'])
    Dir.new(plugin_path).each do |file|
      unless file[-3..-1] == ".rb"
        next
      end
      plugin_file = File.join(plugin_path, file)
      ElasticMetric::Logging::info " => #{plugin_file}"
      begin
        require plugin_file
      rescue SyntaxError => se
        ElasticMetric::Logging::error se.message
      end
    end
    ElasticMetric::Plugin.constants.each do |plugin_name|
      begin
        plugin = ElasticMetric::Plugin.const_get(plugin_name)
        if plugin.enable?
          ElasticMetric::Logging::info "Enable Plugin #{plugin_name}"
          @plugins[plugin_name.downcase] ||= plugin.new
        else
          ElasticMetric::Logging::info "Disable Plugin #{plugin_name}"
          @plugins.delete(plugin_name.downcase)
        end
      rescue => error
        ElasticMetric::Logging::error error.message
      end
    end
  end

end
