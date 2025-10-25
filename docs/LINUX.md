# 🐧 Guia de Instalação e Uso - Linux

Este guia fornece instruções específicas para executar o File Processor gRPC em sistemas Linux.

---

## 📋 Índice

- [Requisitos](#requisitos)
- [Instalação de Dependências](#instalação-de-dependências)
- [Setup Rápido](#setup-rápido)
- [Uso Manual](#uso-manual)
- [Runner Universal](#runner-universal)
- [Docker](#docker)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Requisitos

### Sistema Base
- Ubuntu 20.04+ / Debian 11+ / Fedora 35+ / Arch Linux
- 4GB RAM mínimo
- 10GB espaço em disco
- Conexão à internet para download de dependências

### Ferramentas Necessárias
- Build essentials (gcc, g++, make)
- CMake 3.15+
- Python 3.8+
- gRPC e Protocol Buffers
- Ghostscript, Poppler, ImageMagick

---

## 📦 Instalação de Dependências

### Ubuntu / Debian

```bash
# Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Build essentials
sudo apt-get install -y build-essential cmake git pkg-config \
    autoconf automake libtool curl unzip

# Protocol Buffers
sudo apt-get install -y protobuf-compiler libprotobuf-dev

# gRPC (precisa compilar da fonte)
# Veja: https://grpc.io/docs/languages/cpp/quickstart/

# Python
sudo apt-get install -y python3 python3-pip python3-venv

# Ferramentas de processamento
sudo apt-get install -y ghostscript poppler-utils imagemagick

# Docker (opcional)
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
```

### Fedora

```bash
# Build essentials
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y cmake git pkg-config

# Protocol Buffers e gRPC
sudo dnf install -y protobuf-compiler protobuf-devel grpc-devel grpc-plugins

# Python
sudo dnf install -y python3 python3-pip python3-virtualenv

# Ferramentas de processamento
sudo dnf install -y ghostscript poppler-utils ImageMagick

# Docker (opcional)
sudo dnf install -y docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### Arch Linux

```bash
# Build essentials
sudo pacman -S base-devel cmake git

# Protocol Buffers e gRPC
sudo pacman -S protobuf grpc

# Python
sudo pacman -S python python-pip python-virtualenv

# Ferramentas de processamento
sudo pacman -S ghostscript poppler imagemagick

# Docker (opcional)
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### Instalar gRPC da Fonte (se necessário)

```bash
# Clonar repositório gRPC
git clone --recurse-submodules -b v1.60.0 --depth 1 \
    https://github.com/grpc/grpc
cd grpc

# Compilar e instalar
mkdir -p cmake/build
cd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      ../..
make -j$(nproc)
sudo make install

# Atualizar cache de bibliotecas
sudo ldconfig
```

---

## 🚀 Setup Rápido

### Opção 1: Setup Automatizado (Recomendado)

```bash
# 1. Clonar repositório
git clone https://github.com/seu-usuario/file-processor-grpc.git
cd file-processor-grpc

# 2. Tornar scripts executáveis
chmod +x setup.sh run.sh scripts/*.sh

# 3. Executar setup completo
./setup.sh
```

O script `setup.sh` irá:
1. ✅ Verificar Python e ferramentas
2. ✅ Gerar código Protocol Buffers
3. ✅ Compilar servidor e clientes C++
4. ✅ Configurar ambiente virtual Python
5. ✅ Preparar arquivos de teste
6. ✅ Validar instalação

### Opção 2: Setup Manual

```bash
# 1. Tornar scripts executáveis
chmod +x setup.sh run.sh scripts/*.sh

# 2. Gerar código protobuf
./scripts/generate_proto.sh

# 3. Compilar tudo
./scripts/build.sh --all

# 4. Preparar testes
./scripts/prepare_test_files.sh
```

---

## 💻 Uso Manual

### Iniciar Servidor

```bash
# Terminal 1
./scripts/run_server.sh

# Ou com endereço customizado
./scripts/run_server.sh --address 0.0.0.0:50052
```

### Iniciar Cliente Python

```bash
# Terminal 2
./scripts/run_client_python.sh

# Ou conectar a servidor remoto
./scripts/run_client_python.sh --server 192.168.1.100:50051
```

### Iniciar Cliente C++

```bash
# Terminal 2
./scripts/run_client_cpp.sh

# Ou conectar a servidor remoto
./scripts/run_client_cpp.sh --server 192.168.1.100:50051
```

### Executar Testes

```bash
# Com servidor rodando em outro terminal
./scripts/run_tests.sh
```

---

## 🎯 Runner Universal

O projeto inclui um **runner universal** que detecta automaticamente o sistema operacional:

```bash
# Tornar executável (apenas primeira vez)
chmod +x run.sh

# Executar com menu interativo
./run.sh

# Ou executar comandos diretamente
./run.sh setup              # Setup completo
./run.sh server             # Iniciar servidor
./run.sh client-python      # Iniciar cliente Python
./run.sh client-cpp         # Iniciar cliente C++
./run.sh tests              # Executar testes
./run.sh generate-proto     # Gerar código protobuf
./run.sh build              # Compilar projeto
./run.sh prepare-tests      # Preparar arquivos de teste
```

### Menu Interativo

```
╔════════════════════════════════════════════╗
║   File Processor gRPC - Universal Runner  ║
╠════════════════════════════════════════════╣
║  1. Setup completo                         ║
║  2. Gerar código protobuf                  ║
║  3. Compilar projeto                       ║
║  4. Iniciar servidor                       ║
║  5. Iniciar cliente C++                    ║
║  6. Iniciar cliente Python                 ║
║  7. Executar testes                        ║
║  8. Preparar arquivos de teste             ║
║  9. Sair                                   ║
╚════════════════════════════════════════════╝
```

---

## 🐳 Docker

### Usando Docker Compose

```bash
# 1. Build e iniciar servidor
docker-compose up -d server

# 2. Ver logs
docker-compose logs -f server

# 3. Executar cliente Python
docker-compose --profile client up client-python

# 4. Executar cliente C++
docker-compose --profile client up client-cpp

# 5. Parar tudo
docker-compose down
```

### Build Manual de Imagens

```bash
# Servidor
docker build -t file-processor-server -f server_cpp/Dockerfile .

# Cliente C++
docker build -t file-processor-client-cpp -f client_cpp/Dockerfile .

# Cliente Python
docker build -t file-processor-client-python -f client_python/Dockerfile .
```

---

## 🔧 Troubleshooting

### Erro: "protoc não encontrado"

```bash
# Ubuntu/Debian
sudo apt-get install -y protobuf-compiler

# Fedora
sudo dnf install -y protobuf-compiler

# Arch
sudo pacman -S protobuf

# Verificar instalação
protoc --version
```

### Erro: "grpc_cpp_plugin não encontrado"

```bash
# Precisa instalar gRPC da fonte
# Veja seção "Instalar gRPC da Fonte" acima

# Verificar instalação
which grpc_cpp_plugin
grpc_cpp_plugin --version
```

### Erro: "Permission denied" ao executar scripts

```bash
# Tornar todos os scripts executáveis
chmod +x setup.sh run.sh scripts/*.sh

# Ou individualmente
chmod +x scripts/run_server.sh
```

### Erro: "Porta já em uso"

```bash
# Verificar o que está usando a porta
sudo lsof -i :50051

# Matar processo específico
kill -9 <PID>

# Ou usar porta diferente
./scripts/run_server.sh --address 0.0.0.0:50052
```

### Erro: ImageMagick policy

```bash
# Editar policy do ImageMagick
sudo nano /etc/ImageMagick-6/policy.xml

# Comentar ou remover linha:
<!-- <policy domain="coder" rights="none" pattern="PDF" /> -->

# Ou adicionar permissão:
<policy domain="coder" rights="read|write" pattern="PDF" />
```

### Erro: "CMake version too old"

```bash
# Ubuntu 20.04+ (via snap)
sudo snap install cmake --classic

# Ou compilar da fonte
wget https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0.tar.gz
tar -xzf cmake-3.27.0.tar.gz
cd cmake-3.27.0
./bootstrap && make -j$(nproc) && sudo make install
```

### Erro: "cannot find -lgrpc++"

```bash
# Biblioteca gRPC não instalada corretamente
# Reinstale gRPC da fonte (veja seção acima)

# Atualizar cache de bibliotecas
sudo ldconfig

# Verificar se bibliotecas estão instaladas
ls /usr/local/lib/libgrpc*
```

### Servidor não aceita conexões

```bash
# Verificar se está rodando
ps aux | grep file_processor_server

# Verificar porta
sudo netstat -tulpn | grep 50051

# Verificar firewall
sudo ufw status
sudo ufw allow 50051/tcp
```

### Cliente não conecta ao servidor

```bash
# Testar conectividade
nc -zv localhost 50051

# Verificar hostname
ping localhost

# Testar com IP direto
./scripts/run_client_python.sh --server 127.0.0.1:50051
```

---

## 📊 Verificação da Instalação

### Verificar Ferramentas

```bash
# Verificar versões instaladas
protoc --version                    # Protocol Buffers
grpc_cpp_plugin --version           # gRPC
cmake --version                     # CMake
g++ --version                       # Compilador
python3 --version                   # Python
gs --version                        # Ghostscript
pdftotext -v                        # Poppler
convert --version                   # ImageMagick
```

### Verificar Compilação

```bash
# Verificar executáveis
ls -lh server_cpp/build/file_processor_server
ls -lh client_cpp/build/file_processor_client

# Verificar código gerado
ls -lh server_cpp/generated/*.pb.h
ls -lh client_python/generated/*_pb2.py
```

### Teste Rápido

```bash
# Terminal 1: Servidor
./scripts/run_server.sh

# Terminal 2: Cliente (teste rápido)
./scripts/run_client_python.sh
# Escolha opção 1 (Compress PDF)
# Use arquivo: tests/test_files/test_document.pdf
# Output: /tmp/compressed_test.pdf
```

---

## 🎓 Comandos Úteis

### Desenvolvimento

```bash
# Recompilar apenas servidor
./scripts/build.sh --server

# Recompilar apenas cliente C++
./scripts/build.sh --client-cpp

# Limpar e recompilar
rm -rf server_cpp/build client_cpp/build
./scripts/build.sh --all

# Regenerar protobuf
./scripts/generate_proto.sh
```

### Logs

```bash
# Ver logs do servidor
tail -f logs/server.log

# Ver logs com cores
cat logs/server.log

# Limpar logs
rm logs/server.log
```

### Testes

```bash
# Executar teste específico
cd tests
python3 -m unittest test_suite.FileProcessorTestCase.test_01_compress_pdf

# Ver cobertura de testes
pip install coverage
coverage run -m unittest discover tests
coverage report
```

### Docker

```bash
# Ver imagens
docker images

# Ver containers rodando
docker ps

# Ver logs de container
docker logs -f <container_id>

# Entrar em container
docker exec -it <container_id> bash

# Limpar tudo
docker system prune -a
```

---

## 📚 Recursos Adicionais

### Documentação

- **README.md** - Documentação completa do projeto
- **QUICKSTART.md** - Guia de início rápido (5 minutos)
- **RELATORIO.md** - Relatório técnico detalhado
- **STATUS.md** - Status e métricas do projeto

### Links Úteis

- gRPC Documentation: https://grpc.io/docs/
- Protocol Buffers: https://developers.google.com/protocol-buffers
- CMake Tutorial: https://cmake.org/cmake/help/latest/guide/tutorial/
- Docker Docs: https://docs.docker.com/

---

## 🤝 Suporte

Problemas não listados aqui?

1. Verifique os logs: `logs/server.log`
2. Consulte o README.md completo
3. Execute com verbose: `./scripts/run_server.sh -v`
4. Abra uma issue no GitHub

---

**Última atualização**: Outubro 2025  
**Testado em**: Ubuntu 22.04, Debian 11, Fedora 38, Arch Linux
