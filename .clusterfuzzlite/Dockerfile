FROM gcr.io/oss-fuzz-base/base-builder
RUN apt-get update && apt-get install -y \
  cmake \
  libxml2-dev \
  libpng-dev \
  libjpeg-turbo8-dev \
  libtiff-dev \
  nlohmann-json3-dev
COPY . $SRC/iccLibFuzzer
WORKDIR $SRC/iccLibFuzzer
COPY .clusterfuzzlite/build.sh $SRC/
