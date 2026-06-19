FROM docker:29.6.0-cli@sha256:d14410ab6f87a2b6c14b7150de787cd7b8bb012a8e900966d6d893e9f7fc49b6

RUN apk add --no-cache bash curl jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
