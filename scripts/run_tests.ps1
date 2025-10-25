# Script para executar a suite de testes

param(
    [string]$Server = "localhost:50051"
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   File Processor - Test Suite          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar se o servidor está rodando
Write-Host "🔍 Verificando servidor..." -ForegroundColor Yellow

$serverRunning = $false
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $serverParts = $Server -split ':'
    $hostname = $serverParts[0]
    $port = [int]$serverParts[1]
    
    $tcpClient.Connect($hostname, $port)
    $tcpClient.Close()
    $serverRunning = $true
    Write-Host "✅ Servidor está rodando em $Server" -ForegroundColor Green
} catch {
    Write-Host "❌ Servidor não está acessível em $Server" -ForegroundColor Red
    Write-Host "   Erro: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Para iniciar o servidor:" -ForegroundColor Yellow
    Write-Host "  .\scripts\run_server.ps1" -ForegroundColor White
    Write-Host "  ou" -ForegroundColor White
    Write-Host "  docker-compose up -d server" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Verificar se cliente Python está configurado
if (-not (Test-Path "client_python\venv")) {
    Write-Host "❌ Ambiente Python não configurado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\scripts\build.ps1 -ClientPython" -ForegroundColor Yellow
    exit 1
}

# Verificar se código protobuf foi gerado
if (-not (Test-Path "client_python\generated\file_processor_pb2.py")) {
    Write-Host "❌ Código protobuf não foi gerado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\scripts\generate_proto.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "🧪 Executando testes..." -ForegroundColor Cyan
Write-Host ""

# Configurar variável de ambiente
$env:GRPC_SERVER = $Server

# Executar testes
Push-Location "tests"
..\client_python\venv\Scripts\Activate.ps1
python test_suite.py
$exitCode = $LASTEXITCODE
deactivate
Pop-Location

Write-Host ""

if ($exitCode -eq 0) {
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ Testes concluídos com sucesso!    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  ❌ Alguns testes falharam!            ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Red
}

exit $exitCode
