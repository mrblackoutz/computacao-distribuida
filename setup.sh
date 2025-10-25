#!/usr/bin/env bash
################################################################################
# Script de Setup Automatizado - File Processor gRPC
# Configura todo o ambiente de desenvolvimento
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_step() {
    local step=$1
    local total=$2
    local title=$3
    print_color "$MAGENTA" "\n╔════════════════════════════════════════════════════════════╗"
    print_color "$MAGENTA" "║  PASSO $step/$total: $title"
    print_color "$MAGENTA" "╚════════════════════════════════════════════════════════════╝"
}

# Banner
clear
print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"
print_color "$CYAN" "║                                                            ║"
print_color "$CYAN" "║        File Processor gRPC - Setup Automatizado            ║"
print_color "$CYAN" "║                                                            ║"
print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Passo 1: Verificar Python
print_step "1" "6" "Verificando Python"
echo ""

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_color "$GREEN" "  ✅ Python encontrado: $PYTHON_VERSION"
else
    print_color "$RED" "  ❌ Python 3 não encontrado!"
    print_color "$YELLOW" "     Instale com: sudo apt-get install python3 python3-pip python3-venv"
    exit 1
fi

# Passo 2: Verificar ferramentas necessárias
print_step "2" "6" "Verificando ferramentas"
echo ""

MISSING_TOOLS=()

check_tool() {
    local tool=$1
    local name=$2
    local install_cmd=$3
    
    if command -v "$tool" &> /dev/null; then
        print_color "$GREEN" "  ✅ $name"
    else
        print_color "$YELLOW" "  ⚠️  $name não encontrado"
        MISSING_TOOLS+=("$name|$install_cmd")
    fi
}

check_tool "protoc" "Protocol Buffers Compiler" "sudo apt-get install -y protobuf-compiler"
check_tool "grpc_cpp_plugin" "gRPC C++ Plugin" "Ver: https://grpc.io/docs/languages/cpp/quickstart/"
check_tool "cmake" "CMake" "sudo apt-get install -y cmake"
check_tool "g++" "G++ Compiler" "sudo apt-get install -y build-essential"
check_tool "gs" "Ghostscript" "sudo apt-get install -y ghostscript"
check_tool "pdftotext" "Poppler Utils" "sudo apt-get install -y poppler-utils"
check_tool "convert" "ImageMagick" "sudo apt-get install -y imagemagick"

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    echo ""
    print_color "$YELLOW" "⚠️  Ferramentas faltando:"
    
    local has_ghostscript=false
    for tool_info in "${MISSING_TOOLS[@]}"; do
        IFS='|' read -r name cmd <<< "$tool_info"
        print_color "$YELLOW" "     - $name: $cmd"
        if [[ "$name" == "Ghostscript" ]]; then
            has_ghostscript=true
        fi
    done
    
    # Informações adicionais sobre Ghostscript
    if [[ "$has_ghostscript" == true ]]; then
        echo ""
        print_color "$CYAN" "   📄 Nota sobre Ghostscript:"
        print_color "$CYAN" "      O Ghostscript é necessário para compressão de PDF."
        print_color "$CYAN" "      Outras funcionalidades funcionarão normalmente sem ele."
    fi
    
    echo ""
    print_color "$YELLOW" "Deseja continuar mesmo assim? (s/N)"
    read -r response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Passo 3: Gerar código Protocol Buffers
print_step "3" "6" "Gerando código Protocol Buffers"
echo ""

if [[ -f "$PROJECT_ROOT/scripts/generate_proto.sh" ]]; then
    bash "$PROJECT_ROOT/scripts/generate_proto.sh"
else
    print_color "$RED" "  ❌ Script generate_proto.sh não encontrado!"
    exit 1
fi

# Passo 4: Compilar servidor e clientes
print_step "4" "6" "Compilando servidor e clientes"
echo ""

if [[ -f "$PROJECT_ROOT/scripts/build.sh" ]]; then
    bash "$PROJECT_ROOT/scripts/build.sh" --all
else
    print_color "$RED" "  ❌ Script build.sh não encontrado!"
    exit 1
fi

# Passo 5: Preparar arquivos de teste
print_step "5" "6" "Preparando arquivos de teste"
echo ""

if [[ -f "$PROJECT_ROOT/scripts/prepare_test_files.sh" ]]; then
    bash "$PROJECT_ROOT/scripts/prepare_test_files.sh"
else
    print_color "$YELLOW" "  ⚠️  Script prepare_test_files.sh não encontrado, pulando..."
fi

# Passo 6: Verificação final
print_step "6" "6" "Verificação final"
echo ""

print_color "$BLUE" "Verificando componentes instalados:"
echo ""

verify_file() {
    local file=$1
    local name=$2
    
    if [[ -f "$file" ]]; then
        print_color "$GREEN" "  ✅ $name"
        return 0
    else
        print_color "$RED" "  ❌ $name não encontrado"
        return 1
    fi
}

VERIFICATION_PASSED=true

# Verificar servidor
if ! verify_file "$PROJECT_ROOT/server_cpp/build/file_processor_server" "Servidor C++"; then
    VERIFICATION_PASSED=false
fi

# Verificar cliente C++
if ! verify_file "$PROJECT_ROOT/client_cpp/build/file_processor_client" "Cliente C++"; then
    VERIFICATION_PASSED=false
fi

# Verificar cliente Python
if ! verify_file "$PROJECT_ROOT/client_python/client.py" "Cliente Python"; then
    VERIFICATION_PASSED=false
fi

if [[ -d "$PROJECT_ROOT/client_python/venv" ]]; then
    print_color "$GREEN" "  ✅ Ambiente virtual Python"
else
    print_color "$RED" "  ❌ Ambiente virtual Python não encontrado"
    VERIFICATION_PASSED=false
fi

# Verificar código gerado
if [[ -d "$PROJECT_ROOT/server_cpp/generated" ]] && \
   [[ -n "$(ls -A "$PROJECT_ROOT/server_cpp/generated"/*.pb.h 2>/dev/null)" ]]; then
    print_color "$GREEN" "  ✅ Código protobuf C++ gerado"
else
    print_color "$RED" "  ❌ Código protobuf C++ não gerado"
    VERIFICATION_PASSED=false
fi

if [[ -d "$PROJECT_ROOT/client_python/generated" ]] && \
   [[ -n "$(ls -A "$PROJECT_ROOT/client_python/generated"/*_pb2.py 2>/dev/null)" ]]; then
    print_color "$GREEN" "  ✅ Código protobuf Python gerado"
else
    print_color "$RED" "  ❌ Código protobuf Python não gerado"
    VERIFICATION_PASSED=false
fi

# Resultado final
echo ""
print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"

if [[ "$VERIFICATION_PASSED" == true ]]; then
    print_color "$GREEN" "║                                                            ║"
    print_color "$GREEN" "║              ✅ Setup concluído com sucesso!              ║"
    print_color "$GREEN" "║                                                            ║"
    print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    
    echo ""
    print_color "$CYAN" "🚀 Próximos passos:"
    echo ""
    print_color "$BLUE" "1. Iniciar o servidor (em um terminal):"
    print_color "$YELLOW" "   ./scripts/run_server.sh"
    echo ""
    print_color "$BLUE" "2. Iniciar um cliente (em outro terminal):"
    print_color "$YELLOW" "   ./scripts/run_client_python.sh"
    print_color "$YELLOW" "   # ou"
    print_color "$YELLOW" "   ./scripts/run_client_cpp.sh"
    echo ""
    print_color "$BLUE" "3. Executar testes (com servidor rodando):"
    print_color "$YELLOW" "   ./scripts/run_tests.sh"
    echo ""
    print_color "$BLUE" "4. Ou use o runner universal:"
    print_color "$YELLOW" "   ./run.sh"
    echo ""
else
    print_color "$RED" "║                                                            ║"
    print_color "$RED" "║           ❌ Setup concluído com erros!                   ║"
    print_color "$RED" "║                                                            ║"
    print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    
    echo ""
    print_color "$YELLOW" "⚠️  Algumas verificações falharam. Revise os erros acima."
    echo ""
    exit 1
fi
