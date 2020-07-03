FROM alpine:latest

RUN apk add --no-cache bash curl jq && \
    nr_arch=amd64; \
    case "$(uname -m)" in \
      x86_64)  nr_arch=amd64 ;; \
      i386)    nr_arch=386   ;; \
      aarch64) nr_arch=arm64 ;; \
      arm*)    nr_arch=armv6 ;; \
    esac; \
    wget https://github.com/newreleasesio/cli-go/releases/latest/download/newreleases-linux-${nr_arch} \
      -O /usr/local/bin/newreleases && \
    chmod +x /usr/local/bin/newreleases

COPY ./nrgh-sync.sh /usr/local/bin/nrgh-sync
COPY ./github.sh /usr/local/bin/github.sh
COPY ./entrypoint.sh /entrypoint.sh

ENV GH_TOKEN=
ENV NR_TOKEN=

ENTRYPOINT ["/entrypoint.sh"]
