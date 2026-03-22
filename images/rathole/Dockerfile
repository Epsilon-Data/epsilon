FROM alpine:3.20 AS downloader
ARG TARGETARCH
ARG RATHOLE_VERSION=0.5.0

RUN apk add --no-cache curl unzip \
 && case "${TARGETARCH}" in \
      amd64)  ARCH="x86_64-unknown-linux-musl" ;; \
      arm64)  ARCH="aarch64-unknown-linux-musl" ;; \
      *)      echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/rapiz1/rathole/releases/download/v${RATHOLE_VERSION}/rathole-${ARCH}.zip" -o /tmp/rathole.zip \
 && unzip /tmp/rathole.zip -d /tmp \
 && chmod +x /tmp/rathole

FROM alpine:3.20
COPY --from=downloader /tmp/rathole /usr/bin/rathole
USER 1000:1000
ENTRYPOINT ["/usr/bin/rathole"]
