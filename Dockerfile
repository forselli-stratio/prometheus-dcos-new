FROM alpine:3.6
MAINTAINER Stratio EOS <eos@stratio.com>

ARG VERSION

ARG ALERTMANAGER_VERSION=to-be-automatically-changed-in-package
ARG CONFD_VERSION=to-be-automatically-changed-in-package
ARG SEC_UTILS_VERSION=to-be-automatically-changed-in-package
ARG PROMETHEUS_VERSION=to-be-automatically-changed-in-package

EXPOSE 9093
EXPOSE 9090

ADD http://sodio.stratio.com/repository/paas/ansible/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz /tmp/alertmanager.tar.gz
ADD /confd-templates/alarms.toml /confd-templates/alarms.conf.tmpl /confd-templates/alertmanager.toml /confd-templates/alertmanager.conf.tmpl /tmp/
ADD http://sodio.stratio.com/repository/paas/ansible/confd-${CONFD_VERSION}-linux-amd64 /tmp/confd
ADD http://sodio.stratio.com/repository/paas/kms_utils/${SEC_UTILS_VERSION}/kms_utils-${SEC_UTILS_VERSION}.sh /usr/sbin/kms_utils.sh
ADD http://sodio.stratio.com/repository/paas/log_utils/${SEC_UTILS_VERSION}/b-log-${SEC_UTILS_VERSION}.sh /usr/sbin/b-log.sh
ADD prometheus.yml /tmp/prometheus.yml
ADD http://sodio.stratio.com/repository/paas/ansible/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz /tmp/prometheus.tar.gz
ADD startup /
ADD http://sodio.stratio.com/repository/paas/ansible/dumb-init_1.2.0_amd64 /bin/dumb-init
ADD http://sodio.stratio.com/repository/paas/ansible/srv2file_sd /bin/srv2file_sd
ADD http://sodio.stratio.com/repository/paas/ansible/jq-linux64 /usr/sbin/jq

ADD service_discovery /bin/service_discovery

USER root

RUN apk update && \
    apk --no-cache add bash curl openssl && \
    mkdir -p /tmp/alertmanager && \
    tar -xzf /tmp/alertmanager.tar.gz -C /tmp/alertmanager/ --strip-components=1 && \
    mv /tmp/alertmanager/alertmanager /bin/ && \
    rm -rf /tmp/alertmanager /tmp/alertmanager.tar.gz && \
    mkdir -p /opt/confd/bin /etc/confd/conf.d /etc/confd/templates && \
    mv /tmp/confd /opt/confd/bin/confd && \
    mv /tmp/alarms.toml /etc/confd/conf.d && \
    mv /tmp/alertmanager.toml /etc/confd/conf.d && \
    mv /tmp/alarms.conf.tmpl /etc/confd/templates && \
    mv /tmp/alertmanager.conf.tmpl /etc/confd/templates && \
    rm -rf /tmp/confd /tmp/alarms.toml /tmp/alarms.conf.tmpl /tmp/alertmanager.toml /tmp/alertmanager.conf.tmpl && \
    mkdir -p /tmp/prometheus /etc/prometheus /usr/share/prometheus /prometheus && \
    tar -xzf /tmp/prometheus.tar.gz -C /tmp/prometheus/ --strip-components=1 && \
    mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml && \
    mv /tmp/prometheus/promtool /bin/promtool && \
    mv /tmp/prometheus/prometheus /bin/prometheus && \
    mv /tmp/prometheus/console_libraries/ /usr/share/prometheus/console_libraries/ && \
    mv /tmp/prometheus/consoles/ /usr/share/prometheus/consoles/ && \
    ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    chown -R nobody:nogroup etc/prometheus /prometheus && \
    rm -rf /tmp/prometheus /tmp/prometheus.tar.gz /tmp/prometheus.yml && \
    chmod +x /startup /bin/dumb-init /bin/srv2file_sd /bin/alertmanager && \
    chmod +x /opt/confd/bin/confd && \
    chmod +x /usr/sbin/jq && \
    chmod +x /usr/sbin/kms_utils.sh

WORKDIR /prometheus

ENTRYPOINT [ "/bin/dumb-init", "--" ]
CMD ["/bin/bash", "/startup"]
