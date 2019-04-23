# -*- coding: utf-8 -*-
#
# simple zabbix_sender utility, based on gist by 'miyucy'
#   https://gist.github.com/1170577
#
require 'socket'
require 'json'

module Puppet::Util::Zabbix
  class Sender
    attr_reader :serv, :port, :items

    # static method exaple usage:
    # Puppet::Util::Zabbix::Sender.send 'host', 'zabbix_host', 10051 do
    #   add_item 'key', 'value'
    # end
    def self.send(host, serv = 'localhost', port = '10051', &blk)
      s = new serv, port
      s.instance_eval(&blk)
      s.send! host
    end

    def initialize(serv = 'localhost', port = '10051')
      @serv = serv
      @port = port
      @items = {}
    end

    def add_item(key, value)
      @items[key] = value
    end

    def send!(host)
      return if @items.empty?
      begin
        connect(@items.map) do |key, value|
          { host: host.to_s, key: key.to_s, value: value.to_s }
        end
      ensure
        @items = {}
      end
    end

    protected

    def connect(data)
      sock = nil
      begin
        sock = TCPSocket.new @serv, @port
        sock.write rawdata(data)
        JSON.parse sock.read[13..-1]
      ensure
        sock.close if sock
      end
    end

    def rawdata(data)
      data = [data] unless data.instance_of? Array
      baggage = {
        request: 'sender data',
        data: data,
      }.to_json

      "ZBXD\1" + [baggage.bytesize].pack('i') + "\0\0\0\0" + baggage
    end
  end
end
