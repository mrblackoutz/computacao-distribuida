# Estágio 1: Build
FROM ubuntu:22.04 AS builder

# Evitar prompts interativos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências de build
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    autoconf \
    automake \
    libtool \
    curl \
    make \
    g++ \
    unzip \
    libssl-dev \
    libz-dev \
    libre2-dev \
    libc-ares-dev \
    libabsl-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar gRPC
WORKDIR /tmp
RUN git clone --recurse-submodules -b v1.60.0 \
    --depth 1 --shallow-submodules \
    https://github.com/grpc/grpc && \
    cd grpc && \
    mkdir -p cmake/build && \
    cd cmake/build && \
    cmake -DgRPC_INSTALL=ON \
          -DgRPC_BUILD_TESTS=OFF \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          ../.. && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf grpc

# Copiar código fonte
WORKDIR /app
COPY proto/ ../proto/
COPY server_cpp/ .

# Gerar código protobuf
RUN mkdir -p generated && \
    protoc -I=../proto \
           --cpp_out=generated \
           --grpc_out=generated \
           --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) \
           ../proto/file_processor.proto

# Compilar servidor
RUN mkdir -p build && \
    cd build && \
    cmake .. && \
    make -j$(nproc)

# Estágio 2: Runtime
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar apenas dependências de runtime
RUN apt-get update && apt-get install -y \
    ghostscript \
    poppler-utils \
    imagemagick \
    libssl3 \
    libc-ares2 \
    libprotobuf23 \
    && rm -rf /var/lib/apt/lists/*

# Configurar ImageMagick para permitir processamento de PDFs
RUN sed -i '/disable ghostscript format types/,+6d' \
    /etc/ImageMagick-6/policy.xml 2>/dev/null || true

# Copiar bibliotecas gRPC do estágio de build
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/include /usr/local/include

# Atualizar cache de bibliotecas
RUN ldconfig

# Copiar executável
COPY --from=builder /app/build/file_processor_server /usr/local/bin/

# Criar diretórios com permissões corretas
RUN mkdir -p /app/logs /tmp && \
    chmod 777 /app/logs && \
    touch /app/logs/server.log && \
    chmod 666 /app/logs/server.log

WORKDIR /app

# Expor porta
EXPOSE 50051

# Executar servidor
CMD ["file_processor_server", "0.0.0.0:50051"]
