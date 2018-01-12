FROM alpine:3.7 as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

ENV GRPC_VERSION=1.8.3 \
    GRPC_JAVA_VERSION=1.8.0 \
    PROTOBUF_VERSION=3.5.1 \
    PROTOBUF_C_VERSION=1.3.0 \
    PROTOC_GEN_DOC_VERSION=1.0.0-rc \
    OUTDIR=/out
RUN mkdir -p /protobuf && \
    curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz | tar xvz --strip-components=1 -C /protobuf
RUN git clone --depth 1 --recursive -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    rm -rf grpc/third_party/protobuf && \
    ln -s /protobuf /grpc/third_party/protobuf

RUN cd /protobuf && \
    autoreconf -f -i -Wall,no-obsolete && \
    ./configure --prefix=/usr --enable-static=no && \
    make -j2 && make install
# compile objective_c plugin
RUN cd /grpc && make grpc_objective_c_plugin
RUN ln -s `pwd`/bins/opt/grpc_objective_c_plugin /usr/local/bin/protoc-gen-objcgrpc


#ENTRYPOINT ["/usr/bin/protoc", "-I/protobuf"]
