FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential cmake git pkg-config \
    libssl-dev libz-dev libre2-dev \
    libcares-dev libabsl-dev && \
    rm -rf /var/lib/apt/lists/*

# Instalar gRPC
WORKDIR /tmp
RUN git clone --recurse-submodules -b v1.60.0 \
    --depth 1 --shallow-submodules \
    https://github.com/grpc/grpc && \
    cd grpc && mkdir -p cmake/build && cd cmake/build && \
    cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF \
          -DCMAKE_INSTALL_PREFIX=/usr/local ../.. && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf grpc

WORKDIR /app
COPY proto/ ../proto/
COPY client_cpp/ .

RUN mkdir -p generated && \
    protoc -I=../proto --cpp_out=generated \
           --grpc_out=generated \
           --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) \
           ../proto/file_processor.proto && \
    mkdir -p build && cd build && \
    cmake .. && make -j$(nproc)

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libssl3 libz3-4 libre2-9 libcares2 libprotobuf23 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib /usr/local/lib
RUN ldconfig

COPY --from=builder /app/build/file_processor_client /usr/local/bin/

WORKDIR /app

ENTRYPOINT ["file_processor_client"]
CMD ["server:50051"]
