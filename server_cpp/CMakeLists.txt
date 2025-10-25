cmake_minimum_required(VERSION 3.15)
project(FileProcessorServer CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Encontrar dependências
find_package(Threads REQUIRED)

# Protobuf e gRPC via vcpkg (modo CONFIG)
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

# Diretórios
set(PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../proto")
set(GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generated")
set(INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Criar diretório generated se não existir
file(MAKE_DIRECTORY ${GENERATED_DIR})

# Arquivos proto
set(PROTO_FILES "${PROTO_DIR}/file_processor.proto")

# Gerar código a partir dos arquivos proto
set(PROTO_SRCS "${GENERATED_DIR}/file_processor.pb.cc")
set(PROTO_HDRS "${GENERATED_DIR}/file_processor.pb.h")
set(GRPC_SRCS "${GENERATED_DIR}/file_processor.grpc.pb.cc")
set(GRPC_HDRS "${GENERATED_DIR}/file_processor.grpc.pb.h")

# Comando personalizado para gerar código protobuf
add_custom_command(
    OUTPUT ${PROTO_SRCS} ${PROTO_HDRS} ${GRPC_SRCS} ${GRPC_HDRS}
    COMMAND protobuf::protoc
    ARGS --grpc_out=${GENERATED_DIR}
         --cpp_out=${GENERATED_DIR}
         -I=${PROTO_DIR}
         --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
         ${PROTO_FILES}
    DEPENDS ${PROTO_FILES}
    COMMENT "Generating protobuf and gRPC files"
)

# Incluir diretórios
include_directories(
    ${INCLUDE_DIR}
    ${GENERATED_DIR}
    ${PROTOBUF_INCLUDE_DIRS}
)

# Arquivos fonte
set(SERVER_SOURCES
    ${SRC_DIR}/server.cc
    ${SRC_DIR}/file_processor_service_impl.cc
    ${PROTO_SRCS}
    ${GRPC_SRCS}
)

# Executável do servidor
add_executable(file_processor_server ${SERVER_SOURCES})

# Linkar bibliotecas
target_link_libraries(file_processor_server
    gRPC::grpc++
    gRPC::grpc++_reflection
    protobuf::libprotobuf
    Threads::Threads
)

# Opções de compilação
if(MSVC)
    target_compile_options(file_processor_server PRIVATE /W4)
else()
    target_compile_options(file_processor_server PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -O2
    )
endif()

# Instalar
install(TARGETS file_processor_server
        RUNTIME DESTINATION bin)
