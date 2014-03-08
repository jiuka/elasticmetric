require 'logger'

class ElasticMetric
  class Logging

    def self.debug(message)
      if block_given?
         _log.debug("elasticmetric/#{message}") { yield }
      else
        _log.debug('elasticmetric') { message }
      end
    end

    def self.info(message = nil, &block)
      if block_given?
         _log.info("elasticmetric/#{message}") { yield }
      else
        _log.info('elasticmetric') { message }
      end
    end

    def self.error(message)
      if block_given?
         _log.error("elasticmetric/#{message}") { yield }
      else
        _log.error('elasticmetric') { message }
      end
    end

    def self.config
      begin
        logfile = ElasticMetric::Config['logfile']

        if logfile and logfile[0..5] == 'syslog'
          unless @@log == Syslog::Logger
            log = Syslog::Logger.new 'elasticmetric'
            log.info "Logfile #{logfile} opened."
            @@log = log
          end
        elsif logfile
          unless @@log == Logger and @@log.filename == logfile
            log = Logger.new logfile
            log.progname = 'elasticmetric'
            log.info "Logfile #{logfile} opened."
            log.level = Logger::DEBUG
            @@log = log
          end
        end

      rescue => error
        _log.error(error.message)
      end
    end

    private
      def self._initLog
        log = Logger.new(STDOUT)
        log.progname = 'elasticmetric'
        log
      end

      def self._log
        @@log ||= _initLog
      end

  end
end
