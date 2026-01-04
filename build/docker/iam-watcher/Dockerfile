FROM BASE_IMAGE
LABEL maintainer="<colin404@foxmail.com>"

WORKDIR /opt/iam

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
      echo "Asia/Shanghai" > /etc/timezone && \
      mkdir -p /var/log/iam

COPY iam-watcher /opt/iam/bin/

ENTRYPOINT ["/opt/iam/bin/iam-watcher"]
CMD ["-c", "/etc/iam/iam-watcher.yaml"]
