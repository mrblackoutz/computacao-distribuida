#!/usr/bin/env bash
################################################################################
# Script de Geração de Código Protocol Buffers
# Gera código C++ e Python a partir dos arquivos .proto
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_color "$CYAN" "🔨 Gerando código Protocol Buffers..."
echo ""

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROTO_DIR="$PROJECT_ROOT/proto"
CPP_OUT_DIR="$PROJECT_ROOT/server_cpp/generated"
PYTHON_OUT_DIR="$PROJECT_ROOT/client_python/generated"

# Verificar se protoc está instalado
if ! command -v protoc &> /dev/null; then
    print_color "$RED" "❌ Erro: protoc não encontrado!"
    echo ""
    print_color "$YELLOW" "Por favor, instale o Protocol Buffers compiler:"
    print_color "$YELLOW" "  Ubuntu/Debian: sudo apt-get install -y protobuf-compiler"
    print_color "$YELLOW" "  Fedora:        sudo dnf install protobuf-compiler"
    print_color "$YELLOW" "  Arch:          sudo pacman -S protobuf"
    print_color "$YELLOW" "  macOS:         brew install protobuf"
    exit 1
fi

# Verificar se grpc_cpp_plugin está instalado
if ! command -v grpc_cpp_plugin &> /dev/null; then
    print_color "$RED" "❌ Erro: grpc_cpp_plugin não encontrado!"
    echo ""
    print_color "$YELLOW" "Por favor, instale o gRPC:"
    print_color "$YELLOW" "  Veja: https://grpc.io/docs/languages/cpp/quickstart/"
    exit 1
fi

# Verificar se arquivo proto existe
if [[ ! -f "$PROTO_DIR/file_processor.proto" ]]; then
    print_color "$RED" "❌ Erro: arquivo proto não encontrado em $PROTO_DIR/file_processor.proto"
    exit 1
fi

# Criar diretórios de saída
print_color "$BLUE" "📁 Criando diretórios de saída..."
mkdir -p "$CPP_OUT_DIR"
mkdir -p "$PYTHON_OUT_DIR"

# Gerar código C++
print_color "$BLUE" "📦 Gerando código C++..."
protoc -I="$PROTO_DIR" \
    --cpp_out="$CPP_OUT_DIR" \
    --grpc_out="$CPP_OUT_DIR" \
    --plugin=protoc-gen-grpc="$(which grpc_cpp_plugin)" \
    "$PROTO_DIR/file_processor.proto"

if [[ $? -eq 0 ]]; then
    print_color "$GREEN" "  ✅ Código C++ gerado com sucesso!"
else
    print_color "$RED" "  ❌ Erro ao gerar código C++!"
    exit 1
fi

# Gerar código Python
print_color "$BLUE" "🐍 Gerando código Python..."

# Verificar se grpcio-tools está instalado
if ! python3 -c "import grpc_tools.protoc" 2>/dev/null; then
    print_color "$YELLOW" "⚠️  grpcio-tools não encontrado, instalando..."
    pip3 install grpcio-tools
fi

python3 -m grpc_tools.protoc \
    -I="$PROTO_DIR" \
    --python_out="$PYTHON_OUT_DIR" \
    --grpc_python_out="$PYTHON_OUT_DIR" \
    "$PROTO_DIR/file_processor.proto"

if [[ $? -eq 0 ]]; then
    print_color "$GREEN" "  ✅ Código Python gerado com sucesso!"
else
    print_color "$RED" "  ❌ Erro ao gerar código Python!"
    exit 1
fi

# Criar __init__.py no diretório Python
touch "$PYTHON_OUT_DIR/__init__.py"

# Listar arquivos gerados
echo ""
print_color "$CYAN" "📄 Arquivos gerados:"
echo ""
print_color "$BLUE" "C++:"
ls -lh "$CPP_OUT_DIR"/*.pb.h "$CPP_OUT_DIR"/*.pb.cc 2>/dev/null || print_color "$YELLOW" "  (nenhum arquivo encontrado)"
echo ""
print_color "$BLUE" "Python:"
ls -lh "$PYTHON_OUT_DIR"/*_pb2*.py 2>/dev/null || print_color "$YELLOW" "  (nenhum arquivo encontrado)"

echo ""
print_color "$GREEN" "✅ Código Protocol Buffers gerado com sucesso!"
echo ""
