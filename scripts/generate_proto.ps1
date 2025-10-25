# Script para gerar código gRPC a partir dos arquivos .proto

Write-Host "🔨 Gerando código gRPC..." -ForegroundColor Cyan

$PROTO_DIR = "proto"
$CPP_SERVER_OUT = "server_cpp/generated"
$CPP_CLIENT_OUT = "client_cpp/generated"
$PYTHON_OUT = "client_python/generated"

# Criar diretórios de saída
New-Item -ItemType Directory -Force -Path $CPP_SERVER_OUT | Out-Null
New-Item -ItemType Directory -Force -Path $CPP_CLIENT_OUT | Out-Null
New-Item -ItemType Directory -Force -Path $PYTHON_OUT | Out-Null

Write-Host "📦 Gerando código C++..." -ForegroundColor Yellow

# Gerar código C++ para servidor
protoc -I="$PROTO_DIR" `
    --cpp_out="$CPP_SERVER_OUT" `
    --grpc_out="$CPP_SERVER_OUT" `
    --plugin=protoc-gen-grpc="$(Get-Command grpc_cpp_plugin -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)" `
    "$PROTO_DIR/file_processor.proto"

# Gerar código C++ para cliente
protoc -I="$PROTO_DIR" `
    --cpp_out="$CPP_CLIENT_OUT" `
    --grpc_out="$CPP_CLIENT_OUT" `
    --plugin=protoc-gen-grpc="$(Get-Command grpc_cpp_plugin -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)" `
    "$PROTO_DIR/file_processor.proto"

Write-Host "🐍 Gerando código Python..." -ForegroundColor Yellow

# Gerar código Python
python -m grpc_tools.protoc `
    -I="$PROTO_DIR" `
    --python_out="$PYTHON_OUT" `
    --grpc_python_out="$PYTHON_OUT" `
    "$PROTO_DIR/file_processor.proto"

# Criar __init__.py no diretório Python
New-Item -ItemType File -Force -Path "$PYTHON_OUT/__init__.py" | Out-Null

Write-Host "✅ Código gRPC gerado com sucesso!" -ForegroundColor Green
