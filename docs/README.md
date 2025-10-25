# 📜 Scripts - File Processor gRPC

Este diretório contém scripts de automação para o projeto em **duas versões**: PowerShell (.ps1) e Bash (.sh).

---

## 📁 Estrutura

```
scripts/
├── generate_proto.ps1          # Windows
├── generate_proto.sh           # Linux/macOS
│
├── build.ps1                   # Windows
├── build.sh                    # Linux/macOS
│
├── run_server.ps1              # Windows
├── run_server.sh               # Linux/macOS
│
├── run_client_cpp.ps1          # Windows
├── run_client_cpp.sh           # Linux/macOS
│
├── run_client_python.ps1       # Windows
├── run_client_python.sh        # Linux/macOS
│
├── run_tests.ps1               # Windows
├── run_tests.sh                # Linux/macOS
│
├── prepare_test_files.ps1      # Windows
├── prepare_test_files.sh       # Linux/macOS
│
└── README.md                   # Este arquivo
```

---

## 🎯 Scripts Disponíveis

### 1. generate_proto (.ps1 / .sh)

Gera código C++ e Python a partir dos arquivos Protocol Buffers (.proto).

**Uso**:
```powershell
# Windows
.\scripts\generate_proto.ps1

# Linux/macOS
./scripts/generate_proto.sh
```

**Gera**:
- `server_cpp/generated/*.pb.h` e `*.pb.cc`
- `client_python/generated/*_pb2.py` e `*_pb2_grpc.py`

---

### 2. build (.ps1 / .sh)

Compila o servidor C++, cliente C++ e configura cliente Python.

**Uso**:
```powershell
# Windows - Compilar tudo
.\scripts\build.ps1 -All

# Windows - Apenas servidor
.\scripts\build.ps1 -Server

# Linux - Compilar tudo
./scripts/build.sh --all

# Linux - Apenas servidor
./scripts/build.sh --server
```

**Opções**:
- `-Server` / `--server`: Compila apenas servidor C++
- `-ClientCpp` / `--client-cpp`: Compila apenas cliente C++
- `-ClientPython` / `--client-python`: Configura apenas cliente Python
- `-All` / `--all`: Compila tudo (padrão)
- `-Jobs N` / `--jobs N`: Número de jobs paralelos (Linux)

---

### 3. run_server (.ps1 / .sh)

Inicia o servidor gRPC.

**Uso**:
```powershell
# Windows
.\scripts\run_server.ps1
.\scripts\run_server.ps1 -Address "0.0.0.0:50052"

# Linux/macOS
./scripts/run_server.sh
./scripts/run_server.sh --address 0.0.0.0:50052
```

**Opções**:
- `-Address` / `--address`: Endereço do servidor (padrão: 0.0.0.0:50051)

**Recursos**:
- ✅ Verifica se porta está em uso
- ✅ Permite matar processo anterior
- ✅ Captura Ctrl+C graciosamente
- ✅ Exibe logs coloridos

---

### 4. run_client_cpp (.ps1 / .sh)

Inicia o cliente C++ interativo.

**Uso**:
```powershell
# Windows
.\scripts\run_client_cpp.ps1
.\scripts\run_client_cpp.ps1 -ServerAddress "192.168.1.100:50051"

# Linux/macOS
./scripts/run_client_cpp.sh
./scripts/run_client_cpp.sh --server 192.168.1.100:50051
```

**Opções**:
- `-ServerAddress` / `--server`: Endereço do servidor (padrão: localhost:50051)

**Recursos**:
- ✅ Verifica conectividade antes de iniciar
- ✅ Menu interativo com 4 operações
- ✅ Feedback visual de progresso

---

### 5. run_client_python (.ps1 / .sh)

Inicia o cliente Python interativo.

**Uso**:
```powershell
# Windows
.\scripts\run_client_python.ps1
.\scripts\run_client_python.ps1 -ServerAddress "192.168.1.100:50051"

# Linux/macOS
./scripts/run_client_python.sh
./scripts/run_client_python.sh --server 192.168.1.100:50051
```

**Opções**:
- `-ServerAddress` / `--server`: Endereço do servidor (padrão: localhost:50051)

**Recursos**:
- ✅ Ativa ambiente virtual automaticamente
- ✅ Verifica conectividade antes de iniciar
- ✅ Menu interativo com emojis
- ✅ Feedback detalhado de operações

---

### 6. run_tests (.ps1 / .sh)

Executa a suite de testes automatizados.

**Uso**:
```powershell
# Windows
.\scripts\run_tests.ps1
.\scripts\run_tests.ps1 -ServerAddress "localhost:50051"

# Linux/macOS
./scripts/run_tests.sh
./scripts/run_tests.sh --server localhost:50051
```

**Opções**:
- `-ServerAddress` / `--server`: Endereço do servidor (padrão: localhost:50051)

**Recursos**:
- ✅ Verifica se servidor está rodando
- ✅ Prepara ambiente Python automaticamente
- ✅ Prepara arquivos de teste se necessário
- ✅ Exibe relatório detalhado

---

### 7. prepare_test_files (.ps1 / .sh)

Gera arquivos de teste (PDFs e imagens) para validação.

**Uso**:
```powershell
# Windows
.\scripts\prepare_test_files.ps1

# Linux/macOS
./scripts/prepare_test_files.sh
```

**Gera**:
- `tests/test_files/test_document.pdf` (2 páginas)
- `tests/test_files/test_image_large.jpg` (1920x1080)
- `tests/test_files/test_image_medium.png` (800x600)
- `tests/test_files/test_image_small.jpg` (400x300)

**Recursos**:
- ✅ Verifica se ferramentas estão instaladas
- ✅ Gera PDFs com Ghostscript
- ✅ Gera imagens com ImageMagick
- ✅ Cria README.md em test_files

---

## 🚀 Fluxo de Trabalho Típico

### Setup Inicial

```powershell
# Windows
.\scripts\generate_proto.ps1
.\scripts\build.ps1 -All
.\scripts\prepare_test_files.ps1

# Linux
./scripts/generate_proto.sh
./scripts/build.sh --all
./scripts/prepare_test_files.sh
```

### Desenvolvimento

```powershell
# Terminal 1: Servidor
.\scripts\run_server.ps1           # Windows
./scripts/run_server.sh            # Linux

# Terminal 2: Cliente
.\scripts\run_client_python.ps1    # Windows
./scripts/run_client_python.sh     # Linux

# Terminal 3: Testes (opcional)
.\scripts\run_tests.ps1            # Windows
./scripts/run_tests.sh             # Linux
```

---

## 🎨 Características

### Todos os Scripts

- ✅ **Cores no output**: Verde (sucesso), Azul (info), Amarelo (aviso), Vermelho (erro)
- ✅ **Validação de dependências**: Verifica ferramentas necessárias
- ✅ **Mensagens claras**: Feedback detalhado de cada operação
- ✅ **Tratamento de erros**: Encerramento gracioso em falhas
- ✅ **Help integrado**: `-h` / `--help` / `-Help` em todos

### Scripts PowerShell (.ps1)

- ✅ **Parâmetros nomeados**: `-Server`, `-ClientCpp`, etc.
- ✅ **Validação de tipos**: PSCustomObject para configuração
- ✅ **Comentários baseados em ajuda**: Get-Help funciona

### Scripts Bash (.sh)

- ✅ **Flags POSIX**: `--server`, `--all`, etc.
- ✅ **Set -e**: Para na primeira falha
- ✅ **Funções auxiliares**: print_color, check_tool, etc.
- ✅ **Compatibilidade**: Testado em Ubuntu, Debian, Fedora, Arch

---

## 🔧 Requisitos

### Windows

- PowerShell 5.1+ ou PowerShell Core 7+
- Visual Studio Build Tools ou Visual Studio 2019+
- CMake 3.15+
- Python 3.8+
- vcpkg (para gRPC)
- Ghostscript, Poppler, ImageMagick

### Linux

- Bash 4.0+
- Build essentials (gcc, g++, make)
- CMake 3.15+
- Python 3.8+
- gRPC (compilado da fonte)
- Ghostscript, Poppler, ImageMagick

### Ambos

- Git
- Protocol Buffers compiler (protoc)
- Porta 50051 disponível

---

## 🐛 Troubleshooting

### Windows: "Script execution is disabled"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Linux: "Permission denied"

```bash
chmod +x scripts/*.sh
```

### Ambos: "protoc not found"

**Windows**:
```powershell
# Adicionar ao PATH (vcpkg)
$env:PATH += ";C:\vcpkg\installed\x64-windows\tools\protobuf"
```

**Linux**:
```bash
sudo apt-get install protobuf-compiler
# ou
which protoc  # verificar se está no PATH
```

### Ambos: "Server not running"

```bash
# Iniciar servidor primeiro
.\scripts\run_server.ps1    # Windows
./scripts/run_server.sh     # Linux
```

---

## 📚 Documentação Relacionada

- **[README.md](../README.md)** - Documentação completa do projeto
- **[QUICKSTART.md](../QUICKSTART.md)** - Guia de início rápido (Windows)
- **[LINUX.md](../LINUX.md)** - Guia completo para Linux
- **[CROSSPLATFORM.md](../CROSSPLATFORM.md)** - Compatibilidade entre plataformas

---

## 🎯 Runner Universal

Na raiz do projeto há um **runner universal** (`run.sh`) que detecta automaticamente o SO e executa o script apropriado:

```bash
./run.sh setup              # Executa setup completo
./run.sh server             # Inicia servidor
./run.sh client-python      # Inicia cliente Python
./run.sh tests              # Executa testes
```

Veja [../run.sh](../run.sh) para mais detalhes.

---

**Mantido por**: Equipe File Processor gRPC  
**Última atualização**: Outubro 2025  
**Testado em**: Windows 10/11, Ubuntu 22.04, Debian 11, Fedora 38, Arch Linux
