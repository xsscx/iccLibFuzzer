###############################################################
#
# Copyright (©) 2024-2025 David H Hoyt. All rights reserved.
#                 https://srd.cx
#
# Last Updated: 11-DEC-2025 2115Z by David Hoyt
#
# Intent: Dockerfile for iccDEV Build Container v2.0.0.76
#          
# 
#  Tag: ci-docker-build
#
#       Added defult run example at login
#
# docker buildx build  --platform linux/amd64,linux/arm64 --target runtime \
#  --provenance=mode=max  --attest type=sbom,kind=image --provenance=mode=max \
#  --attest type=provenance,mode=max,version=v1 \
#  --attest type=sbom,kind=image --annotation "org.opencontainers.image.title=iccDEV Build Container v2.0.0.76" \
#  --annotation "org.opencontainers.image.description=v2.0.0.76 (Ubuntu 24.04)" \
#  --annotation "org.opencontainers.image.licenses=BSD-3-Clause" \
#  --annotation "org.opencontainers.image.vendor=International Color Consortium"  \
#  --annotation "org.opencontainers.image.source=https://github.com/InternationalColorConsortium/iccDEV"  \
#  --annotation "org.opencontainers.image.url=https://github.com/InternationalColorConsortium/iccDEV"  \
#  --annotation "org.opencontainers.image.documentation=https://github.com/InternationalColorConsortium/iccDEV/tree/master/docs"    \
#  --annotation "org.opencontainers.image.version=latest"   --attest=type=sbom --load -t test:container -f ci-docker-container.asan  .
#
# Run:
#
# docker run -it test:container
#
# Best Pratice:
#
#  docker run \
#    --rm \
#    --read-only \
#    --pids-limit=256 \
#    --cpus=1 \
#    --memory=512m \
#    --security-opt no-new-privileges \
#    --cap-drop=ALL \
#    --cap-add=CHOWN \
#    --cap-add=SETUID \
#    --cap-add=SETGID \
#    --cap-add=DAC_OVERRIDE \
#    -u 1000:1000 \
#    -it ghcr.io/internationalcolorconsortium/iccdev:latest bash
#
#
#
###############################################################

# =========================
# 1) BUILD STAGE
# =========================
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="iccDEV Build Container" \
      org.opencontainers.image.description="Container v2.0.0.76" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.vendor="International Color Consortium" \
      org.opencontainers.image.source="https://github.com/InternationalColorConsortium/iccDEV" \
      org.opencontainers.image.url="https://github.com/InternationalColorConsortium/iccDEV" \
      org.opencontainers.image.documentation="https://github.com/InternationalColorConsortium/iccDEV/tree/master/docs" \
      org.opencontainers.image.version="latest"

# ------------------------------------------------------------
# Locale (required for deterministic CLI + CI)
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------
# Runtime dependencies (no compilers, no headers)
# ------------------------------------------------------------
# Build toolchain + dev dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential wget \
    cmake \
    ninja-build \
    git \
    curl \
    ca-certificates \
    pkg-config \
    ccache \
    gdb nano \
    clang-18 \
    clang-tools-18 \
    lldb-18 \
    llvm-18 \
    llvm-18-dev \
    libclang-18-dev \
    libxml2-dev \
    nlohmann-json3-dev \
    libtiff6 \
    libgtk-3-dev \
    libgdk-pixbuf-xlib-2.0-0 \
    libcurl4-openssl-dev \
    libglu1-mesa-dev \
    libnotify-dev \
    libjpeg-dev \
    libpng-dev \
    zlib1g-dev \
    libsecret-1-dev \
    libx11-dev \
    libxext-dev \
    libxtst-dev \
    libclang-rt-18-dev \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Build iccDEV using Clang-18 with full sanitizer propagation
# ------------------------------------------------------------
ENV CC=/usr/bin/clang-18
ENV CXX=/usr/bin/clang++-18

RUN git clone https://github.com/InternationalColorConsortium/iccDEV.git /opt/iccdev \
 && cd /opt/iccdev \
 && sed -i '/find_package(wxWidgets COMPONENTS core base REQUIRED)/,/endif()/ s/^/# /' Build/Cmake/CMakeLists.txt \
 && cd Build \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/iccdev/install \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_COMPILER=/usr/bin/clang-18 \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++-18 \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_TRY_COMPILE_C_FLAGS="" \
    -DCMAKE_TRY_COMPILE_CXX_FLAGS="" \
    -DCMAKE_TRY_COMPILE_LINKER_FLAGS="" \
    -DTIFF_LIBRARY=/usr/lib/$(dpkg-architecture -q DEB_HOST_MULTIARCH)/libtiff.so \
    -DTIFF_INCLUDE_DIR=/usr/include \
    -DZLIB_LIBRARY=/usr/lib/$(dpkg-architecture -q DEB_HOST_MULTIARCH)/libz.so \
    -DZLIB_INCLUDE_DIR=/usr/include \
    -DPNG_LIBRARY=/usr/lib/$(dpkg-architecture -q DEB_HOST_MULTIARCH)/libpng.so \
    -DPNG_PNG_INCLUDE_DIR=/usr/include \
    -DJPEG_LIBRARY=/usr/lib/$(dpkg-architecture -q DEB_HOST_MULTIARCH)/libjpeg.so \
    -DJPEG_INCLUDE_DIR=/usr/include \
    -DCMAKE_C_FLAGS="-g -fsanitize=address,undefined -fno-omit-frame-pointer" \
    -DCMAKE_CXX_FLAGS="-g -fsanitize=address,undefined -fno-omit-frame-pointer -Wall" \
    -DCMAKE_EXE_LINKER_FLAGS="" \
    -DCMAKE_SHARED_LINKER_FLAGS="" \
    ../Build/Cmake \
 && make -j"$(nproc)" \
 && rm -rf /opt/iccdev/.git

# Install runtime script
RUN cat >/opt/iccdev/run-tests.sh <<'EOF'
#!/bin/sh
set -eu
set -o pipefail
cd Testing
echo "=== Updating PATH ==="
for d in ../Build/Tools/*; do
  [ -d "$d" ] && export PATH="$(realpath "$d"):$PATH"
done
          sh CreateAllProfiles.sh
          sh RunTests.sh
          cd HDR
          sh mkprofiles.sh
          cd ..
          pwd
          cd CalcTest
          sh checkInvalidProfiles.sh
          cd ..
          pwd
          cd mcs
          pwd
          sh updateprev.sh
          sh updateprevWithBkgd.sh
          cd ..
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/cve-2023-46602.icc
          iccDumpProfile cve-2023-46602.icc
          iccRoundTrip cve-2023-46602.icc
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/icPlatformSignature-ubsan-poc.icc
          iccDumpProfile icPlatformSignature-ubsan-poc.icc
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/icSigMatrixElemType-Read-poc.icc
          iccRoundTrip icSigMatrixElemType-Read-poc.icc
          iccDumpProfile icSigMatrixElemType-Read-poc.icc
          iccToXml icSigMatrixElemType-Read-poc.icc icSigMatrixElemType-Read-poc.xml
          iccToXml icPlatformSignature-ubsan-poc.icc icPlatformSignature-ubsan-poc.xml
          iccToXml cve-2023-46602.icc cve-2023-46602.xml
          iccFromXml icSigMatrixElemType-Read-poc.xml icSigMatrixElemType-Read-rt.icc
          iccFromXml icPlatformSignature-ubsan-poc.xml icPlatformSignature-ubsan-rt.icc
          iccFromXml cve-2023-46602.xml cve-2023-46602-rt.icc    
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_94578.xml
          icctoXml sRGB_D65_colorimetric_94578.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_8590.xml
          iccFromXml sRGB_D65_colorimetric_8590.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_80278.xml
          iccFromXml sRGB_D65_colorimetric_80278.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_72115.xml
          iccFromXml sRGB_D65_colorimetric_72115.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_61477.xml
          iccFromXml sRGB_D65_colorimetric_61477.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_448.xml
          iccFromXml sRGB_D65_colorimetric_448.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_42752.xml
          iccFromXml sRGB_D65_colorimetric_42752.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_21981.xml
          iccFromXml sRGB_D65_colorimetric_21981.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_20483.xml
          iccFromXml sRGB_D65_colorimetric_20483.xml out.icc
          wget https://github.com/xsscx/Commodity-Injection-Signatures/raw/refs/heads/master/graphics/icc/Cat8Lab-D65_2degMeta.icc
          iccToXml Cat8Lab-D65_2degMeta.icc Cat8Lab-D65_2degMeta.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_20483.xml
          iccFromXml sRGB_D65_colorimetric_20483.xml out.icc
          iccRoundTrip PCC/Lab_float-D50_2deg.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_61477.xml
          iccFromXml sRGB_D65_colorimetric_61477.xml sRGB_D65_colorimetric_61477.icc
          cd CMYK-3DLUTs
          iccFromXml CMYK-3DLUTs.xml CMYK-3DLUTs.icc
          cd ..
          find . -iname "*.icc" | wc -l
echo "========= INSIDE STUB EXIT ========="
EOF

RUN chmod +x /opt/iccdev/run-tests.sh

# ------------------------------------------------------------
# Build-time security scrub: remove possible secrets/tokens/keys
# ------------------------------------------------------------
RUN rm -rf /root/.ssh || true \
 && rm -rf /root/.gnupg || true \
 && rm -rf /root/.git || true \
 && rm -rf /root/.config || true \
 && find /opt/iccdev -type f -name "*.asc" -delete || true \
 && find /opt/iccdev -type f -name "*id_rsa*" -delete || true \
 && find /opt/iccdev -type f -name "*.pem" -delete || true \
 && find /opt/iccdev -type f -name "*.key" -delete || true \
 && find /opt/iccdev -type f -name "*token*" -delete || true

# ------------------------------------------------------------
# Default python alias
# ------------------------------------------------------------
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

RUN rm -rf /root/.ssh /root/.gnupg /root/.config /root/.gitconfig || true \
 && rm -rf /opt/iccdev/.git || true \
 && find /opt/iccdev -type f \( \
      -name "*.asc" -o \
      -name "*id_rsa*" -o \
      -name "*.pem" -o \
      -name "*.key" -o \
      -name "*token*" \
    \) -delete || true

RUN git config --system user.email "" \
 && git config --system user.name "" \
 && git config --system credential.helper ""

###############################################################
# 2) RUNTIME STAGE
###############################################################
FROM ubuntu:24.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Locale (match builder deterministically)
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------
# Install CA certificates (needed for git HTTPS)
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Pull artifacts from builder
# ------------------------------------------------------------
COPY --from=builder /usr /usr
COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/iccdev /opt/iccdev

# ------------------------------------------------------------
# Runtime user
# ------------------------------------------------------------
RUN groupadd -r iccdev \
 && useradd -r -g iccdev -d /opt/iccdev -s /bin/bash iccdev \
 && chown -R iccdev:iccdev /opt/iccdev

# ------------------------------------------------------------
# Collect iccdev executable directories
# ------------------------------------------------------------
RUN find /opt/iccdev/Build/Tools -type f -perm -111 -printf '%h\n' \
    | sort -u | paste -sd: - \
    > /opt/iccdev/toolpaths.txt

# ------------------------------------------------------------
# Collect ONLY llvm-21 binary paths
# (avoid llvm-18 or llvm-19 directories if image contains them)
# ------------------------------------------------------------
RUN if [ -d /usr/lib/llvm-21 ]; then \
        echo "/usr/lib/llvm-21/bin" > /opt/iccdev/llvm-paths.txt; \
    else \
        find /usr/lib -maxdepth 1 -type d -name 'llvm-21' -printf '%p/bin\n' \
            > /opt/iccdev/llvm-paths.txt; \
    fi

# ------------------------------------------------------------
# Deterministic PATH script for login shells
# ------------------------------------------------------------
RUN TOOLPATHS="$(cat /opt/iccdev/toolpaths.txt)" \
 && LLVMPATHS="$(cat /opt/iccdev/llvm-paths.txt)" \
 && printf 'export PATH=%s:%s:$PATH\n' "$TOOLPATHS" "$LLVMPATHS" \
      > /etc/profile.d/00-iccdev-path.sh \
 && chmod 644 /etc/profile.d/00-iccdev-path.sh

# ------------------------------------------------------------
# Make ALL bash shells load /etc/profile.d scripts
# ------------------------------------------------------------
RUN echo 'for f in /etc/profile.d/*.sh; do [ -r "$f" ] && . "$f"; done' \
    >> /etc/bash.bashrc

# ------------------------------------------------------------
# Default PATH for non-login shells
# ------------------------------------------------------------
RUN TOOLPATHS="$(cat /opt/iccdev/toolpaths.txt)" \
 && LLVMPATHS="$(cat /opt/iccdev/llvm-paths.txt)" \
 && printf 'PATH=%s:%s:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n' \
        "$TOOLPATHS" "$LLVMPATHS" \
      > /etc/environment

# ------------------------------------------------------------
# Build-time verification that iccToXml is operational
# ------------------------------------------------------------
RUN iccToXml || true

# ------------------------------------------------------------
# Deterministic banner (corrected to v2.0.0.76)
# ------------------------------------------------------------
RUN { \
  echo "echo \"\""; \
  echo "echo \"============================================================\""; \
  echo "echo \"==== International Color Consortium | https://color.org ====\""; \
  echo "echo \"==== iccDEV Build Container v2.0.0.76 Built for Docker  ====\""; \
  echo "echo \"============================================================\""; \
  echo "echo \"\""; \
  echo "echo \"The Libraries & Tools are on PATH located in:\""; \
  echo "echo \"\""; \
  echo "find /opt/iccdev -type f \\( -perm -111 -o -name \"*.a\" -o -name \"*.so\" -o -name \"*.dylib\" \\) -mmin -1440 ! -path \"*/.git/*\" ! -path \"*/CMakeFiles/*\" ! -name \"*.sh\" -print"; \
  echo "echo \"\""; \ 
  echo "echo \"=====================================================\""; \
  echo "echo \"Example Use:\""; \
  echo "echo \"iccToXml Testing/sRGB_v4_ICC_preference.icc Testing/sRGB_v4_ICC_preference.xml\""; \
  echo "iccToXml Testing/sRGB_v4_ICC_preference.icc Testing/sRGB_v4_ICC_preference.xml; [ \$? -ne 0 ] && echo \"\""; \
  echo "echo \"\""; \
  echo "echo \"The Testing directory contains ICC profiles.\""; \
  echo "echo \"\""; \
  echo "echo \"To create all the profiles run these 2 commands:\""; \
  echo "echo \"-----\""; \
  echo "echo \"cd Testing\""; \
  echo "echo \"bash CreateAllProfiles.sh\""; \
  echo "echo \"-----\""; \
  echo "echo \"The Expected Output:\""; \
  echo "echo \"ICC files: 204\""; \
  echo "echo \"\""; \
  echo "echo \"=== Thank you for using iccDEV Build Container v2.0.0.76 ====\""; \
  echo "echo \"\""; \
} > /etc/profile.d/iccdev-banner.sh \
 && chmod 644 /etc/profile.d/iccdev-banner.sh

# ------------------------------------------------------------
# Deterministic prompt for all shells
# ------------------------------------------------------------
RUN printf 'export PS1="iccdev@build:\$(pwd)$ "\n' \
      > /etc/profile.d/10-iccdev-prompt.sh \
 && chmod 644 /etc/profile.d/10-iccdev-prompt.sh

USER iccdev
WORKDIR /opt/iccdev

RUN printf 'export PS1="iccdev@build:\$(pwd)$ "\n' >> ~/.bashrc

###############################################################
# 3) DEBUG-ASAN FINAL IMAGE (public runtime)
###############################################################
FROM runtime AS debug-asan

LABEL org.opencontainers.image.title="iccDEV Build Container" \
      org.opencontainers.image.description="iccDEV Build Container v2.0.0.76" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.vendor="International Color Consortium" \
      org.opencontainers.image.source="https://github.com/InternationalColorConsortium/iccDEV"

# Default command runs test suite
CMD ["/opt/iccdev/run-tests.sh"]

