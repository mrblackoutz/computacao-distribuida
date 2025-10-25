#!/usr/bin/env bash
################################################################################
# Script de Execução do Cliente Python gRPC
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
CLIENT_DIR="$PROJECT_ROOT/client_python"
CLIENT_SCRIPT="$CLIENT_DIR/client.py"

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

print_color "$CYAN" "🚀 Iniciando cliente Python gRPC..."
echo ""

# Verificar se script existe
if [[ ! -f "$CLIENT_SCRIPT" ]]; then
    print_color "$RED" "❌ Erro: Cliente não encontrado em $CLIENT_SCRIPT"
    exit 1
fi

# Verificar Python
if ! command -v python3 &> /dev/null; then
    print_color "$RED" "❌ Erro: Python 3 não encontrado!"
    exit 1
fi

# Verificar ambiente virtual
if [[ ! -d "$CLIENT_DIR/venv" ]]; then
    print_color "$YELLOW" "⚠️  Ambiente virtual não encontrado!"
    print_color "$YELLOW" "   Criando ambiente virtual..."
    cd "$CLIENT_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install --quiet --upgrade pip
    pip install --quiet -r requirements.txt
    deactivate
    print_color "$GREEN" "   ✅ Ambiente virtual criado!"
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
print_color "$BLUE" "   Script:      $CLIENT_SCRIPT"
print_color "$BLUE" "   Servidor:    $SERVER_ADDRESS"
print_color "$BLUE" "   Python:      $(python3 --version)"
echo ""

# Executar cliente
cd "$CLIENT_DIR"
source venv/bin/activate

print_color "$GREEN" "✅ Cliente iniciado!"
echo ""

python3 client.py --server="$SERVER_ADDRESS"

deactivate
