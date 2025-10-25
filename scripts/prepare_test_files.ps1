# Script para preparar arquivos de teste

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Preparando Arquivos de Teste        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$testFilesDir = "tests\test_files"
$resultsDir = "tests\test_results"

# Criar diretórios se não existirem
New-Item -ItemType Directory -Force -Path $testFilesDir | Out-Null
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

Write-Host "📁 Diretórios criados:" -ForegroundColor Green
Write-Host "   - $testFilesDir" -ForegroundColor White
Write-Host "   - $resultsDir" -ForegroundColor White
Write-Host ""

# Criar PDF de teste simples usando PowerShell
Write-Host "📄 Criando PDF de teste..." -ForegroundColor Yellow

$pdfContent = @"
Sample PDF Test File
===================

This is a test PDF document for the File Processor gRPC Service.

Features to test:
- PDF Compression
- PDF to Text Conversion

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

Multiple paragraphs are included to ensure the PDF has sufficient content
for meaningful compression and text extraction testing.

End of test document.
"@

# Salvar como arquivo de texto (será usado para conversão)
$txtPath = Join-Path $testFilesDir "sample_document.txt"
$pdfContent | Out-File -FilePath $txtPath -Encoding utf8
Write-Host "   ✅ Arquivo de texto criado: sample_document.txt" -ForegroundColor Green

# Verificar se ImageMagick está disponível
$hasMagick = $null -ne (Get-Command "magick" -ErrorAction SilentlyContinue) -or 
             $null -ne (Get-Command "convert" -ErrorAction SilentlyContinue)

if ($hasMagick) {
    Write-Host ""
    Write-Host "🖼️  Criando imagens de teste..." -ForegroundColor Yellow
    
    $imagePath = Join-Path $testFilesDir "test_image.png"
    
    # Tentar criar uma imagem simples
    try {
        if (Get-Command "magick" -ErrorAction SilentlyContinue) {
            magick -size 800x600 xc:lightblue -gravity center `
                   -pointsize 48 -fill darkblue `
                   -annotate +0+0 "Test Image`n800x600" `
                   $imagePath 2>$null
        } else {
            convert -size 800x600 xc:lightblue -gravity center `
                    -pointsize 48 -fill darkblue `
                    -annotate +0+0 "Test Image`n800x600" `
                    $imagePath 2>$null
        }
        
        if (Test-Path $imagePath) {
            Write-Host "   ✅ Imagem PNG criada: test_image.png" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️  Não foi possível criar imagem com ImageMagick" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "⚠️  ImageMagick não encontrado - imagens de teste não criadas" -ForegroundColor Yellow
    Write-Host "   Instale ImageMagick para criar imagens de teste automaticamente" -ForegroundColor Gray
}

# Verificar se Ghostscript está disponível para criar PDF
$hasGhostscript = $null -ne (Get-Command "gswin64c" -ErrorAction SilentlyContinue) -or
                  $null -ne (Get-Command "gs" -ErrorAction SilentlyContinue)

if ($hasGhostscript) {
    Write-Host ""
    Write-Host "📄 Tentando criar PDF de teste..." -ForegroundColor Yellow
    
    # Criar PostScript simples
    $psContent = @"
%!PS-Adobe-3.0
%%Title: Test Document
%%Creator: File Processor Test Suite
%%Pages: 1
%%EndComments

%%Page: 1 1
/Times-Roman findfont 20 scalefont setfont
100 700 moveto (Sample PDF Test File) show
100 670 moveto (=====================) show
/Times-Roman findfont 12 scalefont setfont
100 640 moveto (This is a test PDF document for the File Processor gRPC Service.) show
100 610 moveto (Features to test:) show
100 590 moveto (- PDF Compression) show
100 570 moveto (- PDF to Text Conversion) show
100 540 moveto (Lorem ipsum dolor sit amet, consectetur adipiscing elit.) show
100 520 moveto (Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.) show
100 500 moveto (Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.) show
showpage
%%EOF
"@
    
    $psPath = Join-Path $testFilesDir "temp.ps"
    $pdfPath = Join-Path $testFilesDir "sample_document.pdf"
    
    $psContent | Out-File -FilePath $psPath -Encoding ascii
    
    try {
        if (Get-Command "gswin64c" -ErrorAction SilentlyContinue) {
            gswin64c -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$pdfPath $psPath 2>$null
        } else {
            gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$pdfPath $psPath 2>$null
        }
        
        Remove-Item $psPath -ErrorAction SilentlyContinue
        
        if (Test-Path $pdfPath) {
            Write-Host "   ✅ PDF criado: sample_document.pdf" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️  Não foi possível criar PDF com Ghostscript" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "⚠️  Ghostscript não encontrado - PDF de teste não criado" -ForegroundColor Yellow
    Write-Host "   Instale Ghostscript para criar PDF de teste automaticamente" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 Resumo dos arquivos de teste:" -ForegroundColor Cyan
Write-Host ""

$testFiles = Get-ChildItem -Path $testFilesDir -File
if ($testFiles.Count -eq 0) {
    Write-Host "   ⚠️  Nenhum arquivo de teste foi criado" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Para criar arquivos de teste manualmente:" -ForegroundColor Gray
    Write-Host "   1. Adicione PDFs em: $testFilesDir" -ForegroundColor Gray
    Write-Host "   2. Adicione imagens (JPG, PNG) em: $testFilesDir" -ForegroundColor Gray
} else {
    foreach ($file in $testFiles) {
        $size = if ($file.Length -lt 1KB) { "{0:N0} B" -f $file.Length }
                elseif ($file.Length -lt 1MB) { "{0:N2} KB" -f ($file.Length / 1KB) }
                else { "{0:N2} MB" -f ($file.Length / 1MB) }
        
        Write-Host "   📄 $($file.Name) - $size" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "✅ Preparação concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "  1. Inicie o servidor: .\scripts\run_server.ps1" -ForegroundColor White
Write-Host "  2. Execute os testes: .\scripts\run_tests.ps1" -ForegroundColor White
Write-Host ""
