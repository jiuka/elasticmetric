require 'elasticmetric/plugin'

class ElasticMetric
  class Plugin
    class Memory < ElasticMetric::Plugin

      def self.enable?
        File.exists?("/proc/meminfo")
      end

      def collect
        file = File.new("/proc/meminfo", "r")
        meminfo = {}
        file.read.scan(/(\w+): *(\d*)(?: (\w+))?\n/).collect do |key, val, unit|
          if unit == 'kB'
            val = val.to_i * 1024
          end
          meminfo[key] = val.to_i
        end
        file.close

        {
          :total => meminfo['MemTotal'],
          :slab => meminfo['Slab'],
          :swapcached => meminfo['SwapCached'],
          :pagetables => meminfo['PageTables'],
          :apps => meminfo['MemTotal'] - meminfo['MemFree'] - meminfo['Buffers'] - meminfo['Cached'] - meminfo['Slab'] - meminfo['PageTables'],
          :free => meminfo['MemFree'],
          :buffers => meminfo['Buffers'],
          :cached => meminfo['Cached'],
          :swap => meminfo['SwapTotal'] - meminfo['SwapFree'],
        }
      end

    end
  end
end
