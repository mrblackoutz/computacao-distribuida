# Script para compilar o servidor e clientes

param(
    [switch]$Server,
    [switch]$ClientCpp,
    [switch]$ClientPython,
    [switch]$All
)

function Build-Component {
    param(
        [string]$Name,
        [string]$Path
    )
    
    Write-Host "`n🔨 Compilando $Name..." -ForegroundColor Cyan
    
    Push-Location $Path
    
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }
    
    Push-Location "build"
    
    Write-Host "▶️  Executando CMake..." -ForegroundColor Yellow
    
    # Configurar variáveis de ambiente para vcpkg se disponível
    $vcpkgRoot = $env:VCPKG_ROOT
    
    # Se não estiver definido, tentar path local
    if (-not $vcpkgRoot) {
        $localVcpkg = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "temp\vcpkg"
        if (Test-Path "$localVcpkg\scripts\buildsystems\vcpkg.cmake") {
            $vcpkgRoot = $localVcpkg
            $env:VCPKG_ROOT = $vcpkgRoot
        }
    }
    
    $cmakeArgs = @("..", "-DCMAKE_BUILD_TYPE=Release")
    
    if ($vcpkgRoot -and (Test-Path "$vcpkgRoot\scripts\buildsystems\vcpkg.cmake")) {
        Write-Host "   📦 Usando vcpkg: $vcpkgRoot" -ForegroundColor Gray
        $toolchainPath = "$vcpkgRoot\scripts\buildsystems\vcpkg.cmake"
        $cmakeArgs += "-DCMAKE_TOOLCHAIN_FILE=$toolchainPath"
        $cmakeArgs += "-DVCPKG_TARGET_TRIPLET=x64-windows"
    }
    
    # Adicionar paths do protoc e grpc_cpp_plugin
    if ($env:PATH -like "*vcpkg*") {
        Write-Host "   🔧 Protobuf/gRPC paths configurados via PATH" -ForegroundColor Gray
    }
    
    cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CMake falhou!" -ForegroundColor Red
        Pop-Location
        Pop-Location
        return $false
    }
    
    Write-Host "▶️  Compilando..." -ForegroundColor Yellow
    cmake --build . --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Compilação falhou!" -ForegroundColor Red
        Pop-Location
        Pop-Location
        return $false
    }
    
    Write-Host "✅ $Name compilado com sucesso!" -ForegroundColor Green
    
    Pop-Location
    Pop-Location
    return $true
}

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   File Processor - Build Script      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

if ($All -or (-not $Server -and -not $ClientCpp -and -not $ClientPython)) {
    $Server = $true
    $ClientCpp = $true
    $ClientPython = $true
}

if ($Server) {
    Build-Component "Servidor C++" "server_cpp"
}

if ($ClientCpp) {
    Build-Component "Cliente C++" "client_cpp"
}

if ($ClientPython) {
    Write-Host "`n🐍 Configurando Cliente Python..." -ForegroundColor Cyan
    Push-Location "client_python"
    
    if (-not (Test-Path "venv")) {
        Write-Host "▶️  Criando ambiente virtual..." -ForegroundColor Yellow
        python -m venv venv
    }
    
    Write-Host "▶️  Instalando dependências..." -ForegroundColor Yellow
    .\venv\Scripts\Activate.ps1
    pip install -r requirements.txt -q
    deactivate
    
    Write-Host "✅ Cliente Python configurado!" -ForegroundColor Green
    
    Pop-Location
}

Write-Host "`n✅ Build completo!" -ForegroundColor Green
