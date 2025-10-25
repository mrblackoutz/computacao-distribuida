#!/usr/bin/env bash
################################################################################
# Script de Execução de Testes
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
TESTS_DIR="$PROJECT_ROOT/tests"
TEST_SCRIPT="$TESTS_DIR/test_suite.py"

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

print_color "$CYAN" "🧪 Executando testes automatizados..."
echo ""

# Verificar se script de testes existe
if [[ ! -f "$TEST_SCRIPT" ]]; then
    print_color "$RED" "❌ Erro: Script de testes não encontrado em $TEST_SCRIPT"
    exit 1
fi

# Verificar Python
if ! command -v python3 &> /dev/null; then
    print_color "$RED" "❌ Erro: Python 3 não encontrado!"
    exit 1
fi

# Verificar conectividade com servidor
print_color "$BLUE" "🔍 Verificando conexão com servidor..."
HOST="${SERVER_ADDRESS%%:*}"
PORT="${SERVER_ADDRESS##*:}"

if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
    print_color "$GREEN" "   ✅ Servidor está acessível em $SERVER_ADDRESS"
else
    print_color "$RED" "   ❌ Servidor não está acessível em $SERVER_ADDRESS"
    print_color "$YELLOW" "   Por favor, inicie o servidor primeiro:"
    print_color "$YELLOW" "   ./scripts/run_server.sh"
    exit 1
fi

# Verificar ambiente Python para cliente
CLIENT_DIR="$PROJECT_ROOT/client_python"
if [[ ! -d "$CLIENT_DIR/venv" ]]; then
    print_color "$YELLOW" "⚠️  Ambiente virtual Python não encontrado!"
    print_color "$YELLOW" "   Configurando cliente Python..."
    "$SCRIPT_DIR/build.sh" --client-python
fi

# Verificar arquivos de teste
TEST_FILES_DIR="$TESTS_DIR/test_files"
if [[ ! -d "$TEST_FILES_DIR" ]] || [[ -z "$(ls -A "$TEST_FILES_DIR" 2>/dev/null)" ]]; then
    print_color "$YELLOW" "⚠️  Arquivos de teste não encontrados!"
    print_color "$YELLOW" "   Preparando arquivos de teste..."
    "$SCRIPT_DIR/prepare_test_files.sh"
fi

echo ""
print_color "$BLUE" "📋 Configuração:"
print_color "$BLUE" "   Testes:      $TEST_SCRIPT"
print_color "$BLUE" "   Servidor:    $SERVER_ADDRESS"
print_color "$BLUE" "   Python:      $(python3 --version)"
echo ""

# Ativar ambiente virtual do cliente Python (tem as dependências)
cd "$CLIENT_DIR"
source venv/bin/activate

# Executar testes
cd "$TESTS_DIR"

print_color "$GREEN" "🚀 Iniciando testes..."
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Executar com unittest
if python3 -m unittest test_suite.FileProcessorTestCase -v; then
    EXIT_CODE=0
    echo ""
    echo "════════════════════════════════════════════════════════════"
    print_color "$GREEN" "✅ Todos os testes passaram!"
else
    EXIT_CODE=1
    echo ""
    echo "════════════════════════════════════════════════════════════"
    print_color "$RED" "❌ Alguns testes falharam!"
fi

deactivate

exit $EXIT_CODE
