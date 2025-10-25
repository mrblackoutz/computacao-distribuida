#!/usr/bin/env bash
################################################################################
# Script de Execução do Servidor gRPC
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
SERVER_DIR="$PROJECT_ROOT/server_cpp"
SERVER_EXEC="$SERVER_DIR/build/file_processor_server"
LOGS_DIR="$PROJECT_ROOT/logs"

# Parâmetros padrão
SERVER_ADDRESS="0.0.0.0:50051"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--address)
            SERVER_ADDRESS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  -a, --address ADDR   Endereço do servidor (padrão: 0.0.0.0:50051)"
            echo "  -h, --help          Mostrar esta ajuda"
            exit 0
            ;;
        *)
            print_color "$RED" "❌ Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

print_color "$CYAN" "🚀 Iniciando servidor gRPC..."
echo ""

# Verificar se executável existe
if [[ ! -f "$SERVER_EXEC" ]]; then
    print_color "$RED" "❌ Erro: Servidor não encontrado!"
    print_color "$YELLOW" "   Por favor, compile o servidor primeiro:"
    print_color "$YELLOW" "   ./scripts/build.sh --server"
    exit 1
fi

# Criar diretório de logs
mkdir -p "$LOGS_DIR"

# Verificar se porta está em uso
PORT="${SERVER_ADDRESS##*:}"
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_color "$YELLOW" "⚠️  Porta $PORT já está em uso!"
    print_color "$YELLOW" "   Deseja matar o processo existente? (s/N)"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
        PID=$(lsof -ti:$PORT)
        kill -9 $PID 2>/dev/null || true
        print_color "$GREEN" "   ✅ Processo anterior encerrado"
        sleep 1
    else
        print_color "$RED" "   ❌ Abortando..."
        exit 1
    fi
fi

# Informações
print_color "$BLUE" "📋 Configuração:"
print_color "$BLUE" "   Executável:  $SERVER_EXEC"
print_color "$BLUE" "   Endereço:    $SERVER_ADDRESS"
print_color "$BLUE" "   Logs:        $LOGS_DIR/server.log"
echo ""

# Executar servidor
cd "$SERVER_DIR/build"

print_color "$GREEN" "✅ Servidor iniciado!"
print_color "$YELLOW" "   Pressione Ctrl+C para parar"
echo ""

# Executar e capturar Ctrl+C
trap 'print_color "$YELLOW" "\n⚠️  Encerrando servidor..."; exit 0' INT

./file_processor_server "$SERVER_ADDRESS"
