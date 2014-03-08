require 'elasticmetric/plugin'

class ElasticMetric
  class Plugin
    class DiskUsage < ElasticMetric::Plugin

      def self.enable?
        File.exists?("/usr/bin/df")
      end

      def collect
        fsinfo = {}
        du = %x{/usr/bin/df --local --output=source,fstype,itotal,iused,size,used,target}
        du.scan(/^(\/\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\n/).collect do |dev,type,itot,iuse,btot,bused,target|
          fsinfo[dev] = {
            :inodes => itot,
            :iused  => iuse,
            :blocks => btot,
            :used   => bused,
            :type   => type,
            :target => target,
          }
        end
        fsinfo
      end

    end
  end
end
