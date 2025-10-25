#!/usr/bin/env bash
################################################################################
# Script de Preparação de Arquivos de Teste
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
TEST_FILES_DIR="$PROJECT_ROOT/tests/test_files"
TEST_RESULTS_DIR="$PROJECT_ROOT/tests/test_results"

print_color "$CYAN" "📁 Preparando arquivos de teste..."
echo ""

# Criar diretórios
mkdir -p "$TEST_FILES_DIR"
mkdir -p "$TEST_RESULTS_DIR"

# Verificar ferramentas
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        print_color "$YELLOW" "⚠️  $1 não encontrado, pulando geração de $2"
        return 1
    fi
    return 0
}

# 1. Gerar PDF de teste
print_color "$BLUE" "📄 Gerando PDF de teste..."

PDF_FILE="$TEST_FILES_DIR/test_document.pdf"

if check_tool "gs" "PDF"; then
    # Criar PostScript
    PS_FILE="$TEST_FILES_DIR/test_document.ps"
    
    cat > "$PS_FILE" << 'EOF'
%!PS-Adobe-3.0
%%BoundingBox: 0 0 612 792
%%Pages: 2
%%EndComments

%%Page: 1 1
/Times-Roman findfont 24 scalefont setfont
50 700 moveto
(File Processor gRPC - Test Document) show

/Times-Roman findfont 14 scalefont setfont
50 650 moveto
(This is a test PDF document for the gRPC file processor service.) show

50 620 moveto
(It contains multiple pages with text content to test:) show

50 590 moveto
(- PDF compression functionality) show
50 570 moveto
(- PDF to text conversion) show
50 550 moveto
(- File streaming capabilities) show

/Times-Roman findfont 12 scalefont setfont
50 500 moveto
(Lorem ipsum dolor sit amet, consectetur adipiscing elit.) show
50 480 moveto
(Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.) show
50 460 moveto
(Ut enim ad minim veniam, quis nostrud exercitation ullamco.) show

50 100 moveto
(Page 1 of 2) show

showpage

%%Page: 2 2
/Times-Roman findfont 18 scalefont setfont
50 700 moveto
(Second Page) show

/Times-Roman findfont 12 scalefont setfont
50 650 moveto
(This is the second page of the test document.) show
50 630 moveto
(It helps verify multi-page PDF processing.) show

50 100 moveto
(Page 2 of 2) show

showpage

%%EOF
EOF
    
    # Converter PS para PDF
    gs -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite \
       -sOutputFile="$PDF_FILE" "$PS_FILE" 2>/dev/null
    
    rm "$PS_FILE"
    
    if [[ -f "$PDF_FILE" ]]; then
        print_color "$GREEN" "  ✅ PDF gerado: $PDF_FILE ($(stat -f%z "$PDF_FILE" 2>/dev/null || stat -c%s "$PDF_FILE") bytes)"
    else
        print_color "$RED" "  ❌ Erro ao gerar PDF"
    fi
else
    print_color "$YELLOW" "  ⚠️  Ghostscript não encontrado, pulando geração de PDF"
    print_color "$YELLOW" "     Instale com: sudo apt-get install ghostscript"
fi

# 2. Gerar imagens de teste
print_color "$BLUE" "🖼️  Gerando imagens de teste..."

if check_tool "convert" "imagens"; then
    # Imagem grande (1920x1080)
    IMG_LARGE="$TEST_FILES_DIR/test_image_large.jpg"
    convert -size 1920x1080 \
            -background white \
            -fill black \
            -gravity center \
            -pointsize 72 \
            label:"Test Image\n1920x1080\nFile Processor gRPC" \
            "$IMG_LARGE" 2>/dev/null
    
    if [[ -f "$IMG_LARGE" ]]; then
        print_color "$GREEN" "  ✅ Imagem grande gerada: $IMG_LARGE ($(stat -f%z "$IMG_LARGE" 2>/dev/null || stat -c%s "$IMG_LARGE") bytes)"
    fi
    
    # Imagem média (800x600)
    IMG_MEDIUM="$TEST_FILES_DIR/test_image_medium.png"
    convert -size 800x600 \
            -background lightblue \
            -fill darkblue \
            -gravity center \
            -pointsize 48 \
            label:"Test Image\n800x600\nFormat: PNG" \
            "$IMG_MEDIUM" 2>/dev/null
    
    if [[ -f "$IMG_MEDIUM" ]]; then
        print_color "$GREEN" "  ✅ Imagem média gerada: $IMG_MEDIUM ($(stat -f%z "$IMG_MEDIUM" 2>/dev/null || stat -c%s "$IMG_MEDIUM") bytes)"
    fi
    
    # Imagem pequena (400x300)
    IMG_SMALL="$TEST_FILES_DIR/test_image_small.jpg"
    convert -size 400x300 \
            -background lightgreen \
            -fill darkgreen \
            -gravity center \
            -pointsize 24 \
            label:"Small\nTest Image\n400x300" \
            "$IMG_SMALL" 2>/dev/null
    
    if [[ -f "$IMG_SMALL" ]]; then
        print_color "$GREEN" "  ✅ Imagem pequena gerada: $IMG_SMALL ($(stat -f%z "$IMG_SMALL" 2>/dev/null || stat -c%s "$IMG_SMALL") bytes)"
    fi
else
    print_color "$YELLOW" "  ⚠️  ImageMagick não encontrado, pulando geração de imagens"
    print_color "$YELLOW" "     Instale com: sudo apt-get install imagemagick"
fi

# 3. Criar arquivo README nos testes
README_FILE="$TEST_FILES_DIR/README.md"
cat > "$README_FILE" << 'EOF'
# Arquivos de Teste

Este diretório contém arquivos de teste para o File Processor gRPC.

## Arquivos Gerados

- `test_document.pdf` - PDF de teste com 2 páginas
- `test_image_large.jpg` - Imagem 1920x1080 (JPEG)
- `test_image_medium.png` - Imagem 800x600 (PNG)
- `test_image_small.jpg` - Imagem 400x300 (JPEG)

## Uso

Estes arquivos são usados pela suite de testes automatizados em `tests/test_suite.py`.

Você também pode usá-los manualmente para testar os clientes:

```bash
./scripts/run_client_python.sh
# Escolha a operação desejada
# Use os arquivos deste diretório como input
```

## Regenerar

Para regenerar os arquivos de teste:

```bash
./scripts/prepare_test_files.sh
```
EOF

echo ""
print_color "$CYAN" "📊 Resumo dos arquivos de teste:"
echo ""

if [[ -d "$TEST_FILES_DIR" ]]; then
    ls -lh "$TEST_FILES_DIR" | grep -v "^total" | grep -v "^d"
else
    print_color "$YELLOW" "Nenhum arquivo encontrado"
fi

echo ""
print_color "$GREEN" "✅ Preparação de arquivos de teste concluída!"
echo ""
print_color "$BLUE" "📁 Localização: $TEST_FILES_DIR"
print_color "$BLUE" "📁 Resultados:  $TEST_RESULTS_DIR"
echo ""
