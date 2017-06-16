FROM goption/golang

RUN yum -y -q install epel-release && \
    yum -y -q install rpm-build redhat-rpm-config rpmdevtools rpmlint mock rpm-sign && \
    rpmdev-setuptree && \
    mkdir -p ~/.config

ADD ./mock.cfg /root/.config/mock.cfg
RUN sed -nr "s|# ?(.*PATH.+bin)'|\1:$GOROOT/bin:/go/bin'|p" /etc/mock/site-defaults.cfg >> ~/.config/mock.cfg && \
    sed -i -r "s/(KEEP_ENV_VARS.+)/\1,VERSION,BUILD_TIME,SHA,SHORT_SHA,GOROOT,PATH/" /etc/security/console.apps/mock

ADD ./script.sh /

ENTRYPOINT ["/bin/bash", "/script.sh"]
