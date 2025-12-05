###############################################################
#
## Copyright (©) 2024-2025 David H Hoyt. All rights reserved.
##                 https://srd.cx
##
## Last Updated: 03-DEC-2025 1600Z by David Hoyt
#
## Intent: Dockerfile
#          Version 1.0.1
# 
#
#  Tag: ci-docker-latest
#
#
#
#
#
#
#
###############################################################

# =========================
# 1) BUILD STAGE
# =========================
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.description="iccDEV build and runtime environment (Ubuntu 24.04, wxWidgets, toolchain)"

LABEL \
  org.opencontainers.image.title="iccDEV" \
  org.opencontainers.image.description="iccDEV build and runtime environment (Ubuntu 24.04, wxWidgets, toolchain)" \
  org.opencontainers.image.version="2.3.1.1" \
  org.opencontainers.image.variant="ubuntu-24.04" \
  org.opencontainers.image.licenses="BSD-3-Clause" \
  org.opencontainers.image.url="https://github.com/InternationalColorConsortium/iccDEV" \
  org.opencontainers.image.documentation="https://github.com/InternationalColorConsortium/iccDEV/tree/master/docs" \
  org.opencontainers.image.source="https://github.com/InternationalColorConsortium/iccDEV" \
  org.opencontainers.image.vendor="International Color Consortium" \
  org.opencontainers.image.authors="ICC Development Team" \
  org.opencontainers.image.base.name="ubuntu:24.04"

# Build toolchain + dev dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    ca-certificates \
    pkg-config \
    ccache \
    gdb \
    clang-18 \
    clang-tools-18 \
    lldb-18 \
    llvm-18 \
    llvm-18-dev \
    libclang-18-dev \
    libxml2-dev \
    nlohmann-json3-dev \
    libtiff-dev \
    libgtk-3-dev \
    libcurl4-openssl-dev \
    libglu1-mesa-dev \
    libnotify-dev \
    libjpeg-dev \
    libpng-dev \
    libsecret-1-dev \
    libx11-dev \
    libxext-dev \
    libxtst-dev \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Build wxWidgets from source (3.2.5) — Ubuntu 24.04 compatible
# ------------------------------------------------------------
ARG WX_GIT_REF=v3.2.5

RUN git clone --depth 1 --branch ${WX_GIT_REF} https://github.com/wxWidgets/wxWidgets.git /opt/wx \
 && git -C /opt/wx submodule update --init --recursive \
 && mkdir -p /opt/wx-build && cd /opt/wx-build \
 && ../wx/configure --enable-debug --with-gtk=3 --prefix=/usr/local \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig \
 && rm -rf /opt/wx /opt/wx-build

# ------------------------------------------------------------
# Build iccDEV (binaries, tools, profiles) using Clang-18
# Basic compile: NO ASAN, NO UBSAN
# ------------------------------------------------------------
ENV CC=clang-18
ENV CXX=clang++-18

RUN git clone https://github.com/InternationalColorConsortium/iccDEV.git /opt/iccdev \
 && cd /opt/iccdev/Build \
 && cmake -DCMAKE_INSTALL_PREFIX=/opt/iccdev/install \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_COMPILER=clang-18 \
          -DCMAKE_CXX_COMPILER=clang++-18 \
          -DENABLE_TOOLS=ON \
          -DENABLE_STATIC_LIBS=ON \
          -DENABLE_SHARED_LIBS=ON \
          ../Build/Cmake \
 && make -j"$(nproc)" \
 && echo "--- Build complete" \
 && cd ../Testing \
 && for d in ../Build/Tools/*; do \
        if [ -d "$d" ]; then \
            export PATH="$(realpath "$d"):$PATH"; \
        fi; \
    done \
 && sh CreateAllProfiles.sh \
 && echo "Profiles created:" \
 && find .. -iname "*.icc" | wc -l \
 # strip git metadata to avoid leaking history in runtime image
 && rm -rf /opt/iccdev/.git


# =========================
# 2) RUNTIME STAGE
# =========================
FROM ubuntu:24.04 AS builder2

ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.description="iccDEV build and runtime environment (Ubuntu 24.04, wxWidgets, toolchain)"

LABEL \
  org.opencontainers.image.title="iccDEV" \
  org.opencontainers.image.description="iccDEV build and runtime environment (Ubuntu 24.04, wxWidgets, toolchain)" \
  org.opencontainers.image.version="2.3.1.1" \
  org.opencontainers.image.variant="ubuntu-24.04" \
  org.opencontainers.image.licenses="BSD-3-Clause" \
  org.opencontainers.image.url="https://github.com/InternationalColorConsortium/iccDEV" \
  org.opencontainers.image.documentation="https://github.com/InternationalColorConsortium/iccDEV/tree/master/docs" \
  org.opencontainers.image.source="https://github.com/InternationalColorConsortium/iccDEV" \
  org.opencontainers.image.vendor="International Color Consortium" \
  org.opencontainers.image.authors="ICC Development Team" \
  org.opencontainers.image.base.name="ubuntu:24.04"

# Runtime-only dependencies (no compilers, no headers)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    libxml2 \
    libtiff6 \
    libgtk-3-0 \
    libcurl4 \
    libglu1-mesa \
    libnotify4 \
    libjpeg-turbo8 \
    libpng16-16 \
    libsecret-1-0 \
    libx11-6 \
    libxext6 \
    libxtst6 \
 && rm -rf /var/lib/apt/lists/*

# Copy wxWidgets (installed under /usr/local) and iccDEV tree from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/iccdev /opt/iccdev

# ------------------------------------------------------------
# Create non-root runtime user
# ------------------------------------------------------------
RUN groupadd -r iccdev && useradd -r -g iccdev -d /opt/iccdev -s /usr/sbin/nologin iccdev \
 && chown -R iccdev:iccdev /opt/iccdev

# ------------------------------------------------------------
# Add all iccDEV tool directories to PATH for ALL shells
# ------------------------------------------------------------
RUN echo '# iccDEV tools PATH setup' > /etc/profile.d/iccdev-tools.sh \
 && for d in /opt/iccdev/Build/Tools/*; do \
      if [ -d "$d" ]; then \
        echo "PATH=$d:\$PATH" >> /etc/profile.d/iccdev-tools.sh; \
      fi; \
    done \
 && echo 'export PATH' >> /etc/profile.d/iccdev-tools.sh

# Persist PATH for non-login shells (docker exec)
RUN TOOLPATHS="$(find /opt/iccdev/Build/Tools -maxdepth 1 -type d -print0 | tr '\0' ':')" \
 && echo "TOOLPATHS=$TOOLPATHS" \
 && echo "$TOOLPATHS" > /opt/iccdev/toolpaths.txt \
 && echo "PATH=$TOOLPATHS\$PATH" > /etc/environment

ENV PATH="$(cat /opt/iccdev/toolpaths.txt):$PATH"

# ------------------------------------------------------------
# Add all iccDEV tool directories to PATH for interactive shells
# Uses /opt/iccdev/toolpaths.txt generated at build time
# ------------------------------------------------------------
RUN TOOLPATHS="$(cat /opt/iccdev/toolpaths.txt)" \
 && printf 'export PATH=%s$PATH\n' "$TOOLPATHS" > /etc/profile.d/iccdev-tools.sh \
 && printf 'export PATH=%s$PATH\n' "$TOOLPATHS" >> /etc/bash.bashrc \
 && printf 'export PATH=%s$PATH\n' "$TOOLPATHS" >> /opt/iccdev/.bashrc

# must come *after* PATH is set
USER iccdev

# ------------------------------------------------------------
# Ready-to-run defaults
# ------------------------------------------------------------
WORKDIR /opt/iccdev
CMD ["bash"]


