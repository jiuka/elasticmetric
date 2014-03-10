require 'json'
require 'socket'
require 'date'
require 'daemons'
require 'elasticmetric/plugin'
require 'elasticmetric/config'
require 'elasticmetric/logging'
require 'elasticmetric/send'

class ElasticMetric

  def initialize

    # Parse Options
    @options = {}
    _optParse

    ElasticMetric::Logging::info "Initialite ElasticMetric"

    # Load Configuration
    _configReload

    # Daemonize
    pwd = Dir.pwd
    Daemons.daemonize({
      :ontop    => !ElasticMetric::Config['daemonize'],
      :app_name => 'elasticmetric'
    })
    Dir.chdir(pwd)

    # Load Plugins
    _loadPlugins

    @sender = ElasticMetric::Send.new

    # Signal Handling
    Signal.trap('TERM') do
      Thread.new do
        ElasticMetric::Logging::info "Initialise shutdown"
        @running = false
      end
    end
    Signal.trap('HUP') do
      Thread.new do
        ElasticMetric::Logging::info "Reload configuration"
        _configReload
      end
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
  def _optParse
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end

      opts.on('-c', '--config FILE', 'Use the named config file.') do |c|
        @options[:configfile] = c
      end

      opts.on('-d', '--[no-]daemonize', 'Run as a daemon.') do |d|
        @options[:daemonize] = d
      end

      opts.on('--url URL', 'URL to send the config to') do |url|
        @options[:url] = url
      end

      opts.on('--plugindir DIR', 'Directory to load plugins from') do |plugindir|
        @options[:plugindir] = plugindir
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end.parse!
  end

  def _configReload
    ElasticMetric::Config.load(@options)
    if @sender
      @sender.config
    end
    if @plugins
      @plugins.each { |n,p| p.config }
    end
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
