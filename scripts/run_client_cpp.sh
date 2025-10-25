#!/usr/bin/env bash
################################################################################
# Script de Execução do Cliente C++ gRPC
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
CLIENT_DIR="$PROJECT_ROOT/client_cpp"
CLIENT_EXEC="$CLIENT_DIR/build/file_processor_client"

# Parâmetros padrão
SERVER_ADDRESS="localhost:50051"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SERVER_ADDRESS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  -s, --server ADDR   Endereço do servidor (padrão: localhost:50051)"
            echo "  -h, --help         Mostrar esta ajuda"
            exit 0
            ;;
        *)
            print_color "$RED" "❌ Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

print_color "$CYAN" "🚀 Iniciando cliente C++ gRPC..."
echo ""

# Verificar se executável existe
if [[ ! -f "$CLIENT_EXEC" ]]; then
    print_color "$RED" "❌ Erro: Cliente não encontrado!"
    print_color "$YELLOW" "   Por favor, compile o cliente primeiro:"
    print_color "$YELLOW" "   ./scripts/build.sh --client-cpp"
    exit 1
fi

# Verificar conectividade com servidor
print_color "$BLUE" "🔍 Verificando conexão com servidor..."
HOST="${SERVER_ADDRESS%%:*}"
PORT="${SERVER_ADDRESS##*:}"

if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
    print_color "$GREEN" "   ✅ Servidor está acessível em $SERVER_ADDRESS"
else
    print_color "$YELLOW" "   ⚠️  Não foi possível conectar ao servidor em $SERVER_ADDRESS"
    print_color "$YELLOW" "   Certifique-se de que o servidor está rodando:"
    print_color "$YELLOW" "   ./scripts/run_server.sh"
    echo ""
    print_color "$YELLOW" "   Deseja continuar mesmo assim? (s/N)"
    read -r response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

echo ""
print_color "$BLUE" "📋 Configuração:"
print_color "$BLUE" "   Executável:  $CLIENT_EXEC"
print_color "$BLUE" "   Servidor:    $SERVER_ADDRESS"
echo ""

# Executar cliente
cd "$CLIENT_DIR/build"

print_color "$GREEN" "✅ Cliente iniciado!"
echo ""

./file_processor_client "$SERVER_ADDRESS"
