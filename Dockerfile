FROM alpine:latest

ENV HELM_DATA_HOME=/usr/local/share/helm

RUN apk add --no-cache --virtual --virtual bash openssl ca-certificates curl tar gzip git

RUN curl -sL -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/bin/kubectl

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh

RUN helm plugin install https://github.com/databus23/helm-diff

RUN apk del --no-cache bash openssl ca-certificates curl tar gzip git

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
