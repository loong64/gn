FROM ghcr.io/loong64/anolis:23 AS builder

ARG DEPENDENCIES=" \
        git \
        clang \
        wget \
        unzip \
        libstdc++-static"

RUN set -ex \
    && dnf install -y $DEPENDENCIES \
    && dnf clean all

RUN set -ex \
    && cd /tmp \
    && wget --no-check-certificate --quiet -O ninja.zip https://github.com/loong64/ninja/releases/download/v1.12.1/ninja-linux-loongarch64.zip \
    && unzip ninja.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/ninja \
    && rm -f ninja.zip

ARG VERSION

RUN set -ex \
    && git clone -b ${VERSION} https://github.com/timniederhausen/gn.git /opt/gn

WORKDIR /opt/gn

RUN set -ex \
    && python3 build/gen.py \
    && ninja -C out \
    && out/gn_unittests \
    && tar -C out -czf "out/gn-linux-loong64.tar.gz" gn \
    && cp -f out/gn-linux-loong64.tar.gz out/gn-linux-loongarch64.tar.gz

FROM ghcr.io/loong64/anolis:23

WORKDIR /opt/gn

COPY --from=builder /opt/gn/out/gn-*.tar.gz /opt/gn/dist/

VOLUME /dist

CMD cp -rf dist/* /dist/