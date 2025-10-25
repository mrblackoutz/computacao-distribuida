# Script para executar o cliente Python

param(
    [string]$Server = "localhost:50051"
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   File Processor Client (Python)      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "client_python\venv")) {
    Write-Host "❌ Ambiente virtual não encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\scripts\build.ps1 -ClientPython" -ForegroundColor Yellow
    exit 1
}

Write-Host "▶️  Conectando ao servidor $Server..." -ForegroundColor Green
Write-Host ""

Push-Location "client_python"
.\venv\Scripts\Activate.ps1
python client.py --server=$Server
deactivate
Pop-Location
