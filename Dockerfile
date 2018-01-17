FROM alpine:3.7 as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

ENV GRPC_VERSION=1.8.3 \
    GRPC_JAVA_VERSION=1.8.0 \
    PROTOBUF_VERSION=3.5.1 \
    PROTOBUF_C_VERSION=1.3.0 \
    PROTOC_GEN_DOC_VERSION=1.0.0-rc \
    JAVALITE_VERSION=3.0.1 \
    OUTDIR=/out \
    WORKSPACE=/ws

RUN mkdir -p $OUTDIR

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


# java sux
RUN mkdir -p /grpc-java && \
    curl -L https://github.com/grpc/grpc-java/archive/v${GRPC_JAVA_VERSION}.tar.gz | tar xvz --strip-components=1 -C /grpc-java
RUN cd /grpc-java/compiler/src/java_plugin/cpp && \
    g++ \
        -I. -I/protobuf/src \
        *.cpp \
        -L/protobuf/src/.libs \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java
RUN cd /grpc-java/compiler/src/java_plugin/cpp && \
    install -c protoc-gen-grpc-java /usr/local/bin/

#javascript sux
RUN apk add --update nodejs nodejs-npm
RUN mkdir -p /ts-protoc && cd /ts-protoc && npm install ts-protoc-gen


#RUN mkdir /javalite &&  wget -qO /tmp/javalite.zip https://github.com/google/protobuf/releases/download/v3.0.0/protoc-gen-javalite-3.0.0-linux-x86_64.zip && \
#    unzip -d /javalite /tmp/javalite.zip
#RUN ln -s /javalite/bin/protoc-gen-javalite /usr/local/bin/protoc-gen-javalite
#ENTRYPOINT ["/usr/bin/protoc", "-I/protobuf"]
