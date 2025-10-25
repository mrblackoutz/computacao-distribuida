# Script para executar o cliente C++

param(
    [string]$Server = "localhost:50051"
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   File Processor Client (C++)         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$clientPath = "client_cpp\build\Release\file_processor_client.exe"

if (-not (Test-Path $clientPath)) {
    $clientPath = "client_cpp\build\file_processor_client.exe"
}

if (-not (Test-Path $clientPath)) {
    Write-Host "❌ Cliente não encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\scripts\build.ps1 -ClientCpp" -ForegroundColor Yellow
    exit 1
}

Write-Host "▶️  Conectando ao servidor $Server..." -ForegroundColor Green
Write-Host ""

& $clientPath $Server
