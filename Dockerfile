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

COPY ./docker/entrypoint.sh /entrypoint.sh
COPY ./docker/nrgh-sync-wrapper.sh /usr/local/bin/nrgh-sync-wrapper.sh
COPY ./github.sh /usr/local/bin/github.sh
COPY ./nrgh-sync.sh /usr/local/bin/nrgh-sync

ENV GH_TOKEN=
ENV NR_TOKEN=
ENV SLEEP_INTERVAL=5m

ENTRYPOINT ["/entrypoint.sh"]
