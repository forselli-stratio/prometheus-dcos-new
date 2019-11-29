# [Prometheus](https://prometheus.io/) on [Mesosphere DC/OS](https://dcos.io/)

## Intro
This runs Prometheus on DC/OS (1.8+). `cadvisor.json` contains the service definition for [cAdvisor](https://github.com/google/cadvisor), `grafana.json` contains the service definition for [Grafana Dashboard](https://github.com/Stratio/grafana-eos) and `prometheus.json` contains the service definition for [Prometheus](https://github.com/prometheus).

We install node_exporter as service fabric technology so that all EOS instances are monitorized.

In order to expose [Grafana Dashboard](https://github.com/Stratio/grafana-eos) we assumes you're running [Marathon-LB](https://github.com/Stratio/marathon-lb-sec) on your DC/OS and exports Marathon-LB labels.

To get started just install the group as shown below.

## Usage

When working with the `prometheus.json` and `grafana.json` you'll want to adjust the following variables and labels:

| App | Variable | Value |
|----------|----------|-------|
|`prometheus` | `PAGERDUTY_HIGH_PRIORITY_KEY` | A PagerDuty API Key for High Priority Alerts|
|`prometheus` | `PAGERDUTY_LOW_PRIORITY_KEY` | A PagerDuty API Key for Low Priority Alerts|
|`prometheus` | `SMTP_FROM` | Sender Address Alert Emails are send from|
|`prometheus` | `SMTP_TO` | Recipient Address Alert Emails get send to|
|`prometheus` | `SMTP_SMARTHOST` | SMTP Server Alert Emails are send via|
|`prometheus` | `SMTP_LOGIN` | SMTP Server Login|
|`prometheus` | `SMTP_PASSWORD` | SMTP Server Password|
|`grafana` | `GF_SERVER_ROOT_URL` | The complete URL Grafana will be reachable under |
|`grafana` | `GF_SECURITY_ADMIN_USER` | Grafana Admin Login|
|`grafana` | `GF_SECURITY_ADMIN_PASSWORD` | Grafana Admin Password|

| App | Label | Value |
|----------|----------|-------|
|`grafana` | `HAPROXY_0_VHOST` | Hostname Grafana should be reachable under. This is what's contained in `GF_SERVER_ROOT_URL` |

## Connections
![Connections](https://github.com/Stratio/prometheus-dcos/blob/master/misc/prometheus-dcos.png "Connections")

## Why file_sd based discovery?
Prometheus supports DNS based service discovery. Given a Mesos-DNS SRV record like `cadvisor.metrics._tcp.marathon.slave.mesos` it will find the list of node_exporter nodes and poll them. However it'll result in instance names like
```
cadvisor.metrics._tcp.marathon.slave.mesos:14181
cadvisor.metrics._tcp.marathon.slave.mesos:12227
cadvisor.metrics._tcp.marathon.slave.mesos:31798
```
which is not very useful. Also the Mesos scheduler will assign a random port resource.

So after a [discussion on the mailing list](https://groups.google.com/forum/#!topic/prometheus-developers/ydww-vzG0IE) it turned out that Prometheus can't relabel the instance with the node's IP address since name resolution happens after relabeling. It was suggested to use the file_sd based discovery method instead. This is what the `srv2file_sd` helper is for. It performs the same SRV and A record lookup and instead of the hostname writes the node's IP addres into the targets file. Also we avoid using a random port number with cadvisor and we set host port 8484 so that when a cadvisor is restarted get the same port and all it's data is still associated with the same node.

## Environment Variables
| Variable | Function | Example |
|----------|----------|-------|
|`NODE_EXPORTER_SRV` | Mesos-DNS SRV record of the node_exporter | `NODE_EXPORTER_SRV=node-exporter.node.<consul_domain>`|
|`CADVISOR_SRV` | Mesos-DNS SRV record of cadvisor | `CADVISOR_SRV=_cadvisor.eos-monitor._tcp.marathon.slave.mesos`|
|`SRV_REFRESH_INTERVAL` (optional) | How often should we update the targets JSON | `SRV_REFRESH_INTERVAL=60`|
|`ALERTMANAGER_URL` (optional) | AlertManager URL - uses buildin AlertManager if not defined | `ALERTMANAGER_URL=prometheusalertmanager.marathon.l4lb.thisdcos.directory:9093`|
|`ALERTMANAGER_SCHEME` (optional) | AlertManager Scheme - uses http if not defined | `ALERTMANAGER_SCHEME=https`|
|`PAGERDUTY_*_KEY` (optional) | Pagerduty API Key for Alertmanager. Name in * will be made into the severity | `PAGERDUTY_HIGH_PRIORITY_KEY=93dsqkj23gfTD_nFbdwqk` |
|`RULES` (optional) | prometheus.rules, replaces the version that ships with the container image | `RULES=... Entire prometheus.rules file content`|
|`EXTERNAL_URI` (optional) | External WebUI URL | `EXTERNAL_URI=http://prometheusserver.marathon.l4lb.thisdcos.directory:9090`|
|`STORAGE_TSDB_RETENTION` (optional) | Storage TSDB Retention \ `STORAGE_TSDB_RETENTION=7d`|
|`SMTP_FROM` | How often should we update the targets JSON | `SMTP_FROM=alertmanager@example.com`|
|`SMTP_TO` | How often should we update the targets JSON | `SMTP_TO=ops@example.com`|
|`SMTP_SMARTHOST` | How often should we update the targets JSON | `SMTP_SMARTHOST=mail.example.com`|
|`SMTP_LOGIN` | How often should we update the targets JSON | `SMTP_LOGIN=prometheus`|
|`SMTP_PASSWORD` | How often should we update the targets JSON | `SMTP_PASSWORD=23iuhf23few`|

To produce the $RULES env variable it can be handy to use something like
```
$ cat prometheus.rules | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
```

## Building the SRV lookup helper
To run the `srv2file_sd` helper tool inside the minimal prom/prometheus Docker container I statically linked it. To do so yourself install [musl libc](http://www.musl-libc.org/) and compile using:
```
$ CC=/usr/local/musl/bin/musl-gcc go build --ldflags '-linkmode external -extldflags "-static"' srv2file_sd.go
```

## Building the Service Discoverry helper
To run the `service_discovery` helper tool inside the minimal prom/prometheus Docker container I statically linked it. To do so yourself install [musl libc](http://www.musl-libc.org/) and compile using:
```
$ CC=/usr/local/musl/bin/musl-gcc go build --ldflags '-linkmode external -extldflags "-static"' service_discovery.go
```

## TODO
- perform A lookups in parallel instead of looping over all hosts sequentially
