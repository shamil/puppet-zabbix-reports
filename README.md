puppet-zabbix-reports
---------------------

**Description**

A Puppet report processor for sending metrics to [Zabbix](http://www.zabbix.org/)
server via zabbix trapper protocol.

![zabbix items](https://raw.githubusercontent.com/shamil/puppet-zabbix-reports/master/screenshot.png)

**Installation and usage**

* Install `puppet-zabbix-reports` as a module in your puppet master's module
  path (defaults to `/etc/puppet/modules`).

* Update the `:zabbix_hosts` in `zabbix.yaml`, toy can specify multiple zabbix hosts.
  See examples in `zabbix.yaml`file.

* _[DEPRECATED]_ Update the `:zabbix_host` and `:zabbix_port` variables in `zabbix.yaml`.
  You should use `:zabbix_hosts` instead. This option will be removed in the future.

* Copy `zabbix.yaml` to puppet config directory (defaults to `/etc/puppet`).

* Configure zabbix master to use the `zabbix` report:

```ini
[master]
    reports = store, zabbix
```

* Enable `pluginsync` and `report` on your agents:

```ini
[main]
    report     = true
    pluginsync = true
```

* Unless you run puppet agent on master as well, you will need to run
  `puppet plugin download` on master, to sync the files to `lib` (e.g. `/var/lib/puppet/lib`).
  You will need to do it every time you update the module.

* Import the zabbix template from `zabbix-template.xml`.

* Link the template to hosts managed by puppet.

> It is recommended that host name in zabbix will match the puppet node name,
> if it doesn't, use `override_hosts` option in `zabbix.yaml`

**TODO**

* write some unit tests (really?)

**License**

    Copyright 2015 Alex Simenduev <shamil.si@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
