#!/usr/bin/env bash
################################################################################
# Script de Compilação
# Compila servidor C++, cliente C++ e configura cliente Python
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

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Função de ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -s, --server         Compilar apenas servidor C++"
    echo "  -c, --client-cpp     Compilar apenas cliente C++"
    echo "  -p, --client-python  Configurar apenas cliente Python"
    echo "  -a, --all           Compilar tudo (padrão)"
    echo "  -j, --jobs NUM      Número de jobs paralelos (padrão: $(nproc))"
    echo "  -h, --help          Mostrar esta ajuda"
    echo ""
}

# Valores padrão
BUILD_SERVER=false
BUILD_CLIENT_CPP=false
BUILD_CLIENT_PYTHON=false
BUILD_ALL=false
JOBS=$(nproc)

# Parse argumentos
if [[ $# -eq 0 ]]; then
    BUILD_ALL=true
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            BUILD_SERVER=true
            shift
            ;;
        -c|--client-cpp)
            BUILD_CLIENT_CPP=true
            shift
            ;;
        -p|--client-python)
            BUILD_CLIENT_PYTHON=true
            shift
            ;;
        -a|--all)
            BUILD_ALL=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_color "$RED" "❌ Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Se BUILD_ALL, ativar tudo
if [[ "$BUILD_ALL" == true ]]; then
    BUILD_SERVER=true
    BUILD_CLIENT_CPP=true
    BUILD_CLIENT_PYTHON=true
fi

print_color "$CYAN" "🔨 Iniciando compilação..."
echo ""

# Verificar ferramentas necessárias
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        print_color "$RED" "❌ Erro: $1 não encontrado!"
        print_color "$YELLOW" "   Por favor, instale: $2"
        exit 1
    fi
}

if [[ "$BUILD_SERVER" == true ]] || [[ "$BUILD_CLIENT_CPP" == true ]]; then
    check_tool "cmake" "sudo apt-get install cmake"
    check_tool "g++" "sudo apt-get install build-essential"
fi

if [[ "$BUILD_CLIENT_PYTHON" == true ]]; then
    check_tool "python3" "sudo apt-get install python3"
    check_tool "pip3" "sudo apt-get install python3-pip"
fi

# Compilar Servidor C++
if [[ "$BUILD_SERVER" == true ]]; then
    print_color "$BLUE" "🔧 Compilando Servidor C++..."
    
    cd "$PROJECT_ROOT/server_cpp"
    
    # Criar diretório de build
    if [[ -d "build" ]]; then
        print_color "$YELLOW" "  ⚠️  Diretório build existe, limpando..."
        rm -rf build
    fi
    
    mkdir -p build
    cd build
    
    # CMake
    print_color "$BLUE" "  📋 Executando CMake..."
    if cmake .. -DCMAKE_BUILD_TYPE=Release; then
        print_color "$GREEN" "    ✅ CMake concluído"
    else
        print_color "$RED" "    ❌ Erro no CMake"
        exit 1
    fi
    
    # Make
    print_color "$BLUE" "  🔨 Compilando (usando $JOBS jobs)..."
    if make -j"$JOBS"; then
        print_color "$GREEN" "    ✅ Servidor compilado com sucesso!"
        
        # Verificar executável
        if [[ -f "file_processor_server" ]]; then
            print_color "$GREEN" "    ✅ Executável: $(pwd)/file_processor_server"
        fi
    else
        print_color "$RED" "    ❌ Erro na compilação"
        exit 1
    fi
    
    echo ""
fi

# Compilar Cliente C++
if [[ "$BUILD_CLIENT_CPP" == true ]]; then
    print_color "$BLUE" "🔧 Compilando Cliente C++..."
    
    cd "$PROJECT_ROOT/client_cpp"
    
    # Criar diretório de build
    if [[ -d "build" ]]; then
        print_color "$YELLOW" "  ⚠️  Diretório build existe, limpando..."
        rm -rf build
    fi
    
    mkdir -p build
    cd build
    
    # CMake
    print_color "$BLUE" "  📋 Executando CMake..."
    if cmake .. -DCMAKE_BUILD_TYPE=Release; then
        print_color "$GREEN" "    ✅ CMake concluído"
    else
        print_color "$RED" "    ❌ Erro no CMake"
        exit 1
    fi
    
    # Make
    print_color "$BLUE" "  🔨 Compilando (usando $JOBS jobs)..."
    if make -j"$JOBS"; then
        print_color "$GREEN" "    ✅ Cliente C++ compilado com sucesso!"
        
        # Verificar executável
        if [[ -f "file_processor_client" ]]; then
            print_color "$GREEN" "    ✅ Executável: $(pwd)/file_processor_client"
        fi
    else
        print_color "$RED" "    ❌ Erro na compilação"
        exit 1
    fi
    
    echo ""
fi

# Configurar Cliente Python
if [[ "$BUILD_CLIENT_PYTHON" == true ]]; then
    print_color "$BLUE" "🐍 Configurando Cliente Python..."
    
    cd "$PROJECT_ROOT/client_python"
    
    # Verificar se venv existe
    if [[ ! -d "venv" ]]; then
        print_color "$BLUE" "  📦 Criando ambiente virtual..."
        python3 -m venv venv
    fi
    
    # Ativar venv
    source venv/bin/activate
    
    # Atualizar pip
    print_color "$BLUE" "  📦 Atualizando pip..."
    pip install --quiet --upgrade pip
    
    # Instalar dependências
    print_color "$BLUE" "  📦 Instalando dependências..."
    if pip install --quiet -r requirements.txt; then
        print_color "$GREEN" "    ✅ Dependências instaladas!"
    else
        print_color "$RED" "    ❌ Erro ao instalar dependências"
        exit 1
    fi
    
    # Desativar venv
    deactivate
    
    print_color "$GREEN" "  ✅ Cliente Python configurado!"
    echo ""
fi

print_color "$GREEN" "✅ Compilação concluída com sucesso!"
echo ""

# Resumo
print_color "$CYAN" "📊 Resumo:"
if [[ "$BUILD_SERVER" == true ]]; then
    print_color "$GREEN" "  ✅ Servidor C++:     $PROJECT_ROOT/server_cpp/build/file_processor_server"
fi
if [[ "$BUILD_CLIENT_CPP" == true ]]; then
    print_color "$GREEN" "  ✅ Cliente C++:      $PROJECT_ROOT/client_cpp/build/file_processor_client"
fi
if [[ "$BUILD_CLIENT_PYTHON" == true ]]; then
    print_color "$GREEN" "  ✅ Cliente Python:   $PROJECT_ROOT/client_python/client.py"
fi
echo ""
