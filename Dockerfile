ARG BASE_IMAGE=ghcr.io/loong64/anolis:23
FROM ${BASE_IMAGE} AS builder
ARG TARGETARCH

RUN set -ex \
    && dnf -y install dnf-plugins-core \
    && \
    case "${TARGETARCH}" in \
        loong64|riscv64) \
            dnf install -y python3; \
            ;; \
        *) \
            dnf config-manager --set-enabled powertools; \
            dnf install -y python3.9; \
            ;; \
    esac \
    && dnf install -y clang git unzip wget libstdc++-static \
    && dnf clean all

RUN set -ex \
    && cd /tmp \
    && wget --no-check-certificate --quiet -O ninja.zip https://github.com/loong64/ninja/releases/download/v1.12.1/ninja-linux-$(uname -m).zip \
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
    && out/gn_unittests

FROM ${BASE_IMAGE}
ARG TARGETARCH

COPY --from=builder /opt/gn/out/gn /opt/dist/gn

VOLUME /dist

CMD cp -rf /opt/dist/gn /dist/