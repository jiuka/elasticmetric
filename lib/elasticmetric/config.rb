require 'yaml'

class ElasticMetric
  class Config

    @@config_files = [
      '.elasticmetric.yaml',
      '/etc/elasticmetric.yaml',
    ]
    @@config_file = nil
    @@defaultconfig = {
      'daemonize' => true,
      'url'       => 'http://localhost:9200/elasticmetric/post',
      'plugindir' => 'plugins',
      'plugin'    => {}
    }

    def self.[](key)
      value = _config
      key.split('.').each do |k|
        value = value[k]
      end
      value
    end

    def self.load(options={})
      if options[:configfile]
        @@config_file = File.absolute_path options[:configfile]
      else
        @@config_files.each do |f|
          if File.exist?(f)
            @@config_file = File.absolute_path f
            break
          end
        end
      end

      unless @@config_file
        ElasticMetric::Logging.error "No config file found"
        return
      end
      unless File.exist? @@config_file
        ElasticMetric::Logging.error("Config file #{@@config_file} not found")
        return
      end

      ElasticMetric::Logging.info "Load config file #{@@config_file}"

      @@config = @@defaultconfig.merge YAML::load(File.open(@@config_file))

      # Override config with the command line options
      options.each do |key,value|
        @@config[key.to_s] = value
      end
    end

    private
      def self._config
        @@config || @@defaultconfig
      end

  end
end
