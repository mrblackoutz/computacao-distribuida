# Script de Setup Inicial do Projeto

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  File Processor gRPC - Setup Inicial               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Verificar e configurar vcpkg
$vcpkgPath = Join-Path $PSScriptRoot "temp\vcpkg"
if (Test-Path $vcpkgPath) {
    $env:VCPKG_ROOT = $vcpkgPath
    Write-Host "✅ VCPKG_ROOT configurado: $vcpkgPath" -ForegroundColor Green
    
    # Adicionar protoc e grpc_cpp_plugin ao PATH
    $protobufTools = Join-Path $vcpkgPath "installed\x64-windows\tools\protobuf"
    $grpcTools = Join-Path $vcpkgPath "installed\x64-windows\tools\grpc"
    
    if (Test-Path $protobufTools) {
        $env:PATH = "$protobufTools;$env:PATH"
    }
    if (Test-Path $grpcTools) {
        $env:PATH = "$grpcTools;$env:PATH"
    }
} else {
    Write-Host "⚠️  vcpkg não encontrado em temp\vcpkg" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   O vcpkg é necessário para compilar o servidor e cliente C++." -ForegroundColor Gray
    Write-Host "   Você tem duas opções:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   📦 Opção 1: Usar Docker (RECOMENDADO - mais fácil)" -ForegroundColor Cyan
    Write-Host "      docker-compose build server" -ForegroundColor White
    Write-Host "      docker-compose up -d server" -ForegroundColor White
    Write-Host ""
    Write-Host "   🔧 Opção 2: Instalar vcpkg localmente (demorado ~30min)" -ForegroundColor Cyan
    Write-Host "      git clone https://github.com/Microsoft/vcpkg.git temp\vcpkg" -ForegroundColor White
    Write-Host "      .\temp\vcpkg\bootstrap-vcpkg.bat" -ForegroundColor White
    Write-Host "      .\temp\vcpkg\vcpkg install protobuf:x64-windows grpc:x64-windows" -ForegroundColor White
    Write-Host ""
    Write-Host "   ⚡ Para continuar apenas com Python (sem C++):" -ForegroundColor Cyan
    Write-Host "      Este script vai configurar o cliente Python e você pode usar o servidor via Docker." -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Deseja continuar sem vcpkg? (s/N)"
    if ($response -notmatch '^[sS]') {
        Write-Host "`n❌ Setup cancelado. Instale o vcpkg ou use Docker." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n📝 Continuando sem compilação C++..." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host ""

$steps = @(
    @{ Name = "Verificar Python"; Step = 1; Total = 7 }
    @{ Name = "Verificar Ferramentas"; Step = 2; Total = 7 }
    @{ Name = "Instalar Dependências Python"; Step = 3; Total = 7 }
    @{ Name = "Gerar Código Protobuf"; Step = 4; Total = 7 }
    @{ Name = "Compilar Projeto"; Step = 5; Total = 7 }
    @{ Name = "Preparar Arquivos de Teste"; Step = 6; Total = 7 }
    @{ Name = "Verificar Instalação"; Step = 7; Total = 7 }
)

function Write-Step {
    param($StepInfo)
    Write-Host "`n[$($StepInfo.Step)/$($StepInfo.Total)] $($StepInfo.Name)..." -ForegroundColor Yellow
    Write-Host ("─" * 60) -ForegroundColor Gray
}

# Passo 1: Verificar Python
Write-Step $steps[0]

$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Python encontrado: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Python não encontrado!" -ForegroundColor Red
    Write-Host "   Instale Python 3.8+ de: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Passo 2: Verificar Ferramentas
Write-Step $steps[1]

$tools = @{
    "CMake" = "cmake"
    "Protoc" = "protoc"
    "Ghostscript" = @("gswin64c", "gs")
    "ImageMagick" = @("magick", "convert")
    "Poppler (pdftotext)" = "pdftotext"
}

$missingTools = @()

foreach ($tool in $tools.GetEnumerator()) {
    $found = $false
    $commands = if ($tool.Value -is [Array]) { $tool.Value } else { @($tool.Value) }
    
    foreach ($cmd in $commands) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Host "✅ $($tool.Key) encontrado" -ForegroundColor Green
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "⚠️  $($tool.Key) não encontrado" -ForegroundColor Yellow
        $missingTools += $tool.Key
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "`n⚠️  Ferramentas ausentes: $($missingTools -join ', ')" -ForegroundColor Yellow
    Write-Host "   O projeto pode ter funcionalidades limitadas." -ForegroundColor Yellow
    Write-Host ""
    
    # Instruções específicas para Ghostscript
    if ($missingTools -contains "Ghostscript") {
        Write-Host "   📄 Para instalar Ghostscript:" -ForegroundColor Cyan
        Write-Host "      • Download manual: https://ghostscript.com/releases/gsdnld.html" -ForegroundColor Gray
        Write-Host "      • Via Chocolatey: choco install ghostscript -y" -ForegroundColor Gray
        Write-Host "      • Após instalar, adicione ao PATH: C:\Program Files\gs\gs10.xx.x\bin" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "   Para mais informações, consulte README.md seção 3.1" -ForegroundColor Yellow
}

# Passo 3: Instalar Dependências Python
Write-Step $steps[2]

$venvPath = "client_python\venv"
$requirementsFile = "client_python\requirements.txt"

# Criar venv se não existir
if (-not (Test-Path $venvPath)) {
    Write-Host "📦 Criando ambiente virtual Python..." -ForegroundColor Yellow
    python -m venv $venvPath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao criar ambiente virtual" -ForegroundColor Red
        Write-Host "   Instalando no Python global..." -ForegroundColor Yellow
        $useVenv = $false
    } else {
        Write-Host "✅ Ambiente virtual criado" -ForegroundColor Green
        $useVenv = $true
    }
} else {
    Write-Host "✅ Ambiente virtual já existe" -ForegroundColor Green
    $useVenv = $true
}

# Ativar venv e instalar dependências
if ($useVenv) {
    Write-Host "🔧 Ativando ambiente virtual..." -ForegroundColor Cyan
    $activateScript = "$venvPath\Scripts\Activate.ps1"
    
    if (Test-Path $activateScript) {
        & $activateScript
        Write-Host "✅ Ambiente virtual ativado" -ForegroundColor Green
    }
}

# Atualizar pip
Write-Host "📦 Atualizando pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip --quiet

# Instalar dependências com wheels pré-compilados
if (Test-Path $requirementsFile) {
    Write-Host "📦 Instalando dependências do requirements.txt..." -ForegroundColor Yellow
    Write-Host "   (usando wheels pré-compilados, sem compilar código-fonte)" -ForegroundColor Gray
    
    # Forçar uso de wheels (binários pré-compilados)
    python -m pip install --only-binary :all: -r $requirementsFile 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Versões binárias não disponíveis, tentando compilar..." -ForegroundColor Yellow
        python -m pip install -r $requirementsFile
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Erro na instalação completa" -ForegroundColor Yellow
            Write-Host "   Tentando versão mais recente com binários..." -ForegroundColor Yellow
            
            # Tentar versão mais recente que tem wheels para Python 3.13
            python -m pip install --upgrade grpcio grpcio-tools protobuf
        }
    }
    
    # Verificar se instalação funcionou
    python -c "import grpc_tools" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependências Python instaladas com sucesso" -ForegroundColor Green
    } else {
        Write-Host "⚠️  grpc_tools pode não estar instalado corretamente" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Arquivo requirements.txt não encontrado" -ForegroundColor Yellow
    Write-Host "   Instalando versões mais recentes..." -ForegroundColor Yellow
    python -m pip install --upgrade grpcio grpcio-tools protobuf
}

# Passo 4: Gerar Código Protobuf
Write-Step $steps[3]

Write-Host "Executando generate_proto.ps1..." -ForegroundColor Cyan
& .\scripts\generate_proto.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao gerar código protobuf!" -ForegroundColor Red
    Write-Host "   Verifique se protoc e grpc_cpp_plugin estão no PATH" -ForegroundColor Yellow
    exit 1
}

# Passo 5: Compilar Projeto
Write-Step $steps[4]

if (Test-Path $vcpkgPath) {
    Write-Host "Compilando servidor e clientes..." -ForegroundColor Cyan
    & .\scripts\build.ps1 -All

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro durante compilação!" -ForegroundColor Red
        Write-Host "   Verifique os logs acima para detalhes" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "⏭️  Pulando compilação C++ (vcpkg não disponível)" -ForegroundColor Yellow
    Write-Host "   Use Docker para rodar o servidor:" -ForegroundColor Gray
    Write-Host "   docker-compose up -d server" -ForegroundColor White
    Write-Host ""
}

# Passo 6: Preparar Arquivos de Teste
Write-Step $steps[5]

Write-Host "Preparando arquivos de teste..." -ForegroundColor Cyan
& .\scripts\prepare_test_files.ps1

# Passo 7: Verificação Final
Write-Step $steps[6]

Write-Host "`nVerificando instalação..." -ForegroundColor Cyan

$checks = @{
    "Cliente Python configurado" = "client_python\venv\Scripts\python.exe"
    "Código protobuf gerado (Python)" = "client_python\generated\file_processor_pb2.py"
}

# Adicionar verificações C++ apenas se vcpkg existe
if (Test-Path $vcpkgPath) {
    $checks["Servidor compilado"] = @("server_cpp\build\*\file_processor_server.exe", "server_cpp\build\file_processor_server.exe")
    $checks["Cliente C++ compilado"] = @("client_cpp\build\*\file_processor_client.exe", "client_cpp\build\file_processor_client.exe")
    $checks["Código protobuf gerado (C++)"] = "server_cpp\generated\file_processor.pb.h"
}

$allOk = $true

foreach ($check in $checks.GetEnumerator()) {
    $found = $false
    $paths = if ($check.Value -is [Array]) { $check.Value } else { @($check.Value) }
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "✅ $($check.Key)" -ForegroundColor Green
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "❌ $($check.Key)" -ForegroundColor Red
        $allOk = $false
    }
}

# Resumo Final
Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    RESUMO                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "`n✅ Setup concluído com sucesso!" -ForegroundColor Green
    Write-Host "`nPróximos passos:" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $vcpkgPath) {
        Write-Host "1️⃣  Iniciar o servidor:" -ForegroundColor White
        Write-Host "   .\scripts\run_server.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2️⃣  Em outro terminal, executar cliente:" -ForegroundColor White
        Write-Host "   .\scripts\run_client_python.ps1" -ForegroundColor Gray
        Write-Host "   ou" -ForegroundColor Gray
        Write-Host "   .\scripts\run_client_cpp.ps1" -ForegroundColor Gray
    } else {
        Write-Host "1️⃣  Iniciar o servidor via Docker:" -ForegroundColor White
        Write-Host "   docker-compose up -d server" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2️⃣  Em outro terminal, executar cliente Python:" -ForegroundColor White
        Write-Host "   .\scripts\run_client_python.ps1" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "3️⃣  Executar testes (com servidor rodando):" -ForegroundColor White
    Write-Host "   .\scripts\run_tests.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📚 Consulte QUICKSTART.md para mais informações" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "`n⚠️  Setup completado com avisos" -ForegroundColor Yellow
    
    if (-not (Test-Path $vcpkgPath)) {
        Write-Host "`nCompilação C++ não realizada (vcpkg não disponível)." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "✅ Cliente Python configurado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Para usar o projeto:" -ForegroundColor Cyan
        Write-Host "  1. Inicie o servidor via Docker:" -ForegroundColor White
        Write-Host "     docker-compose up -d server" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. Use o cliente Python:" -ForegroundColor White
        Write-Host "     .\scripts\run_client_python.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  3. Execute os testes:" -ForegroundColor White
        Write-Host "     .\scripts\run_tests.ps1" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "`nAlguns componentes não foram compilados corretamente." -ForegroundColor Yellow
        Write-Host "Revise os erros acima e consulte QUICKSTART.md" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}
