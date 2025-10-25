# 🌍 Compatibilidade Cross-Platform

O File Processor gRPC foi projetado para funcionar perfeitamente em **Windows** e **Linux**.

---

## 📊 Tabela de Compatibilidade

| Componente | Windows | Linux | macOS | Docker |
|------------|---------|-------|-------|--------|
| **Servidor C++** | ✅ | ✅ | ✅ | ✅ |
| **Cliente C++** | ✅ | ✅ | ✅ | ✅ |
| **Cliente Python** | ✅ | ✅ | ✅ | ✅ |
| **Scripts PowerShell** | ✅ | ❌ | ❌ | N/A |
| **Scripts Bash** | ⚠️ | ✅ | ✅ | N/A |
| **Runner Universal** | ✅ | ✅ | ✅ | N/A |
| **Docker Compose** | ✅ | ✅ | ✅ | ✅ |

**Legenda**:
- ✅ Totalmente suportado
- ⚠️ Suportado via WSL/Git Bash
- ❌ Não suportado

---

## 🖥️ Scripts Disponíveis

### Estrutura Dual

Todos os scripts estão disponíveis em **duas versões**:

```
scripts/
├── generate_proto.ps1         # Windows PowerShell
├── generate_proto.sh          # Linux/macOS Bash
├── build.ps1                  # Windows PowerShell
├── build.sh                   # Linux/macOS Bash
├── run_server.ps1             # Windows PowerShell
├── run_server.sh              # Linux/macOS Bash
├── run_client_cpp.ps1         # Windows PowerShell
├── run_client_cpp.sh          # Linux/macOS Bash
├── run_client_python.ps1      # Windows PowerShell
├── run_client_python.sh       # Linux/macOS Bash
├── run_tests.ps1              # Windows PowerShell
├── run_tests.sh               # Linux/macOS Bash
├── prepare_test_files.ps1     # Windows PowerShell
└── prepare_test_files.sh      # Linux/macOS Bash
```

### Runner Universal

O **`run.sh`** detecta automaticamente o sistema operacional e executa o script apropriado:

```bash
# Funciona em Windows, Linux e macOS
./run.sh setup
./run.sh server
./run.sh client-python
```

**Detecção automática**:
- **Windows**: Executa scripts `.ps1` via PowerShell
- **Linux/macOS**: Executa scripts `.sh` via Bash

---

## 🚀 Como Usar em Cada Plataforma

### Windows

#### Opção 1: PowerShell (Nativo)

```powershell
# Setup
.\setup.ps1

# Servidor
.\scripts\run_server.ps1

# Cliente
.\scripts\run_client_python.ps1
```

#### Opção 2: Runner Universal

```powershell
# Tornar executável (apenas primeira vez)
# No PowerShell, não é necessário chmod

# Executar
bash run.sh setup
bash run.sh server
bash run.sh client-python
```

#### Opção 3: WSL (Windows Subsystem for Linux)

```bash
# Dentro do WSL
chmod +x run.sh setup.sh scripts/*.sh
./setup.sh
./run.sh server
```

### Linux

#### Opção 1: Scripts Bash Diretos

```bash
# Tornar executáveis (primeira vez)
chmod +x setup.sh run.sh scripts/*.sh

# Setup
./setup.sh

# Servidor
./scripts/run_server.sh

# Cliente
./scripts/run_client_python.sh
```

#### Opção 2: Runner Universal

```bash
# Setup e uso
./run.sh setup
./run.sh server
./run.sh client-python
```

### macOS

Mesmas instruções do Linux (sistema baseado em Unix).

---

## 🐳 Docker (Universal)

Docker funciona **identicamente** em todas as plataformas:

```bash
# Windows PowerShell
docker-compose up -d server

# Linux/macOS Bash
docker-compose up -d server

# Idêntico em ambos!
```

---

## 🔧 Dependências por Plataforma

### Windows

**Essenciais**:
- Visual Studio 2019+ com C++ (ou Build Tools)
- CMake 3.15+
- Python 3.8+
- vcpkg (para gRPC)

**Ferramentas de Processamento**:
- Ghostscript (https://www.ghostscript.com/download/gsdnld.html)
- Poppler (via scoop: `scoop install poppler`)
- ImageMagick (https://imagemagick.org/script/download.php)

**Opcional**:
- Docker Desktop
- WSL2

### Linux (Ubuntu/Debian)

```bash
# Essenciais
sudo apt-get install -y build-essential cmake git \
    python3 python3-pip python3-venv

# gRPC e Protobuf
sudo apt-get install -y protobuf-compiler
# gRPC precisa ser compilado da fonte

# Ferramentas de processamento
sudo apt-get install -y ghostscript poppler-utils imagemagick

# Opcional
sudo apt-get install -y docker.io docker-compose
```

### Linux (Fedora)

```bash
# Essenciais
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y cmake git python3 python3-pip

# gRPC e Protobuf
sudo dnf install -y protobuf-compiler grpc-devel grpc-plugins

# Ferramentas de processamento
sudo dnf install -y ghostscript poppler-utils ImageMagick

# Opcional
sudo dnf install -y docker docker-compose
```

### macOS

```bash
# Instalar Homebrew primeiro (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Essenciais
brew install cmake python@3

# gRPC e Protobuf
brew install protobuf grpc

# Ferramentas de processamento
brew install ghostscript poppler imagemagick

# Opcional
brew install --cask docker
```

---

## 📁 Estrutura de Código Cross-Platform

### Código C++ Portável

```cpp
// Usa std::filesystem (C++17) - portável
#include <filesystem>
namespace fs = std::filesystem;

// Usa std::chrono - portável
#include <chrono>

// Comandos do sistema são abstraídos
FileProcessorUtils::executeCommand("gs ...");  // Funciona em ambos
```

### Detecção de Plataforma

```cpp
// Em file_processor_utils.h
#ifdef _WIN32
    // Código específico Windows
#else
    // Código específico Linux/Unix
#endif
```

### Scripts Python Portáveis

```python
# Python é naturalmente cross-platform
import os
import sys
import pathlib

# Path handling portável
from pathlib import Path
config_path = Path.home() / ".config" / "app"
```

---

## 🎯 Recomendações por Caso de Uso

### Desenvolvimento Diário

| Situação | Recomendação |
|----------|--------------|
| Desenvolvedor Windows | PowerShell nativo |
| Desenvolvedor Linux | Bash nativo |
| Equipe mista | Runner universal (`run.sh`) |
| CI/CD | Docker |

### Produção

| Situação | Recomendação |
|----------|--------------|
| Deploy Windows | Docker ou executáveis nativos |
| Deploy Linux | Docker (recomendado) ou nativos |
| Cloud | Kubernetes com imagens Docker |
| Edge devices | Executáveis nativos otimizados |

---

## 🐛 Troubleshooting Cross-Platform

### Windows: "Script execution disabled"

```powershell
# Habilitar execução de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Linux: "Permission denied"

```bash
# Tornar scripts executáveis
chmod +x setup.sh run.sh scripts/*.sh
```

### Windows: "protoc not found"

```powershell
# Adicionar ao PATH (vcpkg)
$env:PATH += ";C:\vcpkg\installed\x64-windows\tools\protobuf"
```

### Linux: "grpc_cpp_plugin not found"

```bash
# Compilar gRPC da fonte
# Veja LINUX.md para instruções completas
```

### Ambos: Line endings (CRLF vs LF)

```bash
# Git configuração (recomendado)
git config --global core.autocrlf input   # Linux/Mac
git config --global core.autocrlf true    # Windows

# Converter manualmente se necessário
dos2unix scripts/*.sh        # Linux
unix2dos scripts/*.ps1       # Windows
```

---

## 📚 Documentação Específica

Para instruções detalhadas de cada plataforma:

- **Windows**: Veja [QUICKSTART.md](QUICKSTART.md)
- **Linux**: Veja [LINUX.md](LINUX.md)
- **Docker**: Veja [README.md](README.md) seção Docker

---

## ✅ Checklist de Compatibilidade

### Para Windows

- [ ] Visual Studio Build Tools instalado
- [ ] vcpkg configurado com gRPC
- [ ] Python 3.8+ instalado
- [ ] Ghostscript instalado
- [ ] ImageMagick instalado
- [ ] PowerShell 5.1+ disponível

### Para Linux

- [ ] Build essentials instalado
- [ ] gRPC compilado da fonte
- [ ] Python 3.8+ instalado
- [ ] Ghostscript instalado
- [ ] ImageMagick instalado
- [ ] Scripts com permissão de execução

### Para Ambos

- [ ] CMake 3.15+ instalado
- [ ] Git instalado e configurado
- [ ] Porta 50051 disponível
- [ ] 4GB RAM disponível
- [ ] 10GB espaço em disco

---

## 🤝 Contribuindo

Ao adicionar novo código:

1. **Mantenha compatibilidade**: Use APIs portáveis
2. **Teste em ambos**: Windows E Linux
3. **Documente diferenças**: Se inevitáveis
4. **Scripts duplicados**: Atualize .ps1 e .sh
5. **CI/CD**: Adicione testes para ambas plataformas

---

**Testado em**:
- ✅ Windows 10/11 (PowerShell 5.1 e 7+)
- ✅ Ubuntu 20.04, 22.04
- ✅ Debian 11, 12
- ✅ Fedora 38
- ✅ Arch Linux (rolling)
- ✅ macOS 12+ (Monterey e posteriores)
- ✅ WSL2 (Ubuntu 22.04)

**Última atualização**: Outubro 2025
