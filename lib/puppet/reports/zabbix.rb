require 'puppet'
require 'puppet/util/zabbix_sender'

Puppet::Reports.register_report(:zabbix) do
  desc "Send reports to a Zabbix server via zabbix trapper."

  def process
    configfile = File.join([File.dirname(Puppet.settings[:config]), "zabbix.yaml"])
    raise Puppet::ParseError, "zabbix report config file #{configfile} not readable" unless File.exist?(configfile)

    config = YAML.load_file(configfile)
    raise Puppet::ParseError, "zabbix host was not specified in config file" unless defined? config[:zabbix_host]

    raise_error = false

    global_port = config.fetch(:zabbix_port, 10051)

    zabbix_hosts = config[:zabbix_host].kind_of?(Array) ?
      config[:zabbix_host] : [{ 'address' => config[:zabbix_host] }]

    host_overrides = config[:host_overrides] || {}

    zabbix_hosts.each do |zhost|
      port = zhost['port'] || global_port
      zabbix_sender = Puppet::Util::Zabbix::Sender.new zhost['address'], port

      # simple info
      zabbix_sender.add_item "puppet.version", self.puppet_version
      zabbix_sender.add_item "puppet.run.timestamp", self.time.to_i

      # collect metrics
      self.metrics.each do |metric, data|
        next if metric == 'events' # do not process events at all

        data.values.each do |item|
          next if metric == 'time' and item.first != 'total' # get only total time
          zabbix_sender.add_item "puppet.#{metric}.#{item.first}", item.last
        end
      end

      # send metrics to zabbix
      Puppet.debug "sending zabbix report for host #{self.host}, at #{zabbix_sender.serv}:#{zabbix_sender.port}"
      result = zabbix_sender.send! host_overrides.fetch(self.host, self.host)

      # validate the response. if it fails, keep on sending to all
      # zabbix servers before reporting the error.
      if result['response'] != 'success'
        Puppet.error "zabbix send failed - #{result['info']}"
        raise_error = true
      end
    end

    raise Puppet::Error, "zabbix report had failures" if raise_error
  end
end
