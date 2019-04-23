require 'puppet'
require 'puppet/util/zabbix_sender'

Puppet::Reports.register_report(:zabbix) do
  desc 'Send reports to a Zabbix server via zabbix trapper.'

  def process
    configfile = File.join([File.dirname(Puppet.settings[:config]), 'zabbix.yaml'])
    raise Puppet::ParseError, "zabbix report config file #{configfile} not readable" unless File.exist?(configfile)

    config = YAML.load_file(configfile)
    default_zabbix_port = config.fetch(:zabbix_port, '10051')
    host_overrides = config.fetch(:host_overrides, {})

    zabbix_hosts = [] # instantiate an empty array
    zabbix_hosts << { 'address' => config[:zabbix_host] } if config[:zabbix_host] # for backward cimpatibility
    zabbix_hosts += config[:zabbix_hosts] if config[:zabbix_hosts]
    raise Puppet::ParseError, 'zabbix host(s) must be specified in config file' unless zabbix_hosts.!empty?

    raise_error = false
    zabbix_hosts.each do |zhost|
      port = zhost['port'] || default_zabbix_port
      zabbix_sender = Puppet::Util::Zabbix::Sender.new zhost['address'], port

      # simple info
      zabbix_sender.add_item 'puppet.version', puppet_version
      zabbix_sender.add_item 'puppet.run.timestamp', time.to_i

      # collect metrics
      metrics.each do |metric, data|
        next if metric == 'events' # do not process events at all

        data.values.each do |item|
          next if metric == 'time' && item.first != 'total' # get only total time
          zabbix_sender.add_item "puppet.#{metric}.#{item.first}", item.last
        end
      end

      # send metrics to zabbix
      Puppet.debug "sending zabbix report for host #{host}, at #{zabbix_sender.serv}:#{zabbix_sender.port}"
      begin
        result = zabbix_sender.send! host_overrides.fetch(host, host)
      rescue => e
        result = { 'info' => e }
      end

      # validate the response. if it fails, keep on sending to all
      # zabbix servers before reporting the error.
      if result['response'] != 'success'
        Puppet.err "couldn't send to zabbix server (#{zabbix_sender.serv}:#{zabbix_sender.port}) - #{result['info']}"
        raise_error = true
      end
    end

    raise Puppet::Error, 'zabbix report had failures' if raise_error
  end
end
