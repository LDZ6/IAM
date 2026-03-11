FROM BASE_IMAGE
LABEL maintainer="<admin@example.com>"

WORKDIR /opt/iam/scripts/install

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
      echo "Asia/Shanghai" > /etc/timezone

COPY iamctl /usr/bin/
COPY scripts /opt/iam/scripts

ENTRYPOINT ["sleep", "3600"]
