# Script para executar o servidor

param(
    [string]$Address = "0.0.0.0:50051"
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Iniciando File Processor Server     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$serverPath = "server_cpp\build\Release\file_processor_server.exe"

if (-not (Test-Path $serverPath)) {
    $serverPath = "server_cpp\build\file_processor_server.exe"
}

if (-not (Test-Path $serverPath)) {
    Write-Host "❌ Servidor não encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\scripts\build.ps1 -Server" -ForegroundColor Yellow
    exit 1
}

Write-Host "▶️  Executando servidor em $Address..." -ForegroundColor Green
Write-Host ""

& $serverPath $Address
