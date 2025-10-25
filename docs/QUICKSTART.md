# 🚀 Guia Rápido - File Processor gRPC

Este guia vai te ajudar a ter o projeto rodando em poucos minutos!

## ⚡ Início Rápido (5 minutos)

### 1️⃣ Pré-requisitos Mínimos

**Windows:**
- Visual Studio 2019+ (com C++ tools)
- CMake 3.15+
- Python 3.8+
- vcpkg (gerenciador de pacotes C++)

**Ferramentas de Processamento:**
- [Ghostscript](https://ghostscript.com/releases/gsdnld.html) - Para PDF **(OBRIGATÓRIO)**
- [Poppler](https://blog.alivate.com.au/poppler-windows/) - Para conversão PDF→TXT
- [ImageMagick](https://imagemagick.org/script/download.php#windows) - Para imagens **(⚠️ Requer configuração especial no Windows)**

> ⚠️ **ATENÇÃO IMAGEMAGICK NO WINDOWS**: O Windows tem um comando `convert.exe` nativo que **conflita** com o ImageMagick. Você DEVE garantir que o ImageMagick esteja **antes** do `System32` no PATH, ou use o comando `magick convert` ao invés de `convert`. Veja instruções detalhadas no README.md.

#### ⚠️ Instalação Detalhada do Ghostscript

O Ghostscript é **necessário** para compressão de PDF. Sem ele, você receberá erro ao tentar comprimir PDFs (mas outras funcionalidades funcionarão).

**Opção 1: Download Manual (Recomendado)**

1. Acesse: https://ghostscript.com/releases/gsdnld.html
2. Baixe: **Ghostscript 10.04.0 for Windows (64 bit)**
3. Execute o instalador (arquivo `.exe`)
4. **Adicione ao PATH**:
   - Painel de Controle → Sistema → Configurações avançadas do sistema
   - Variáveis de Ambiente → PATH do Sistema → Editar → Novo
   - Adicione: `C:\Program Files\gs\gs10.04.0\bin`
   - (Ajuste a versão conforme instalada)
5. **Reinicie o terminal** (ou VS Code)
6. Verifique: `gs --version`

**Opção 2: Via Chocolatey** (se você tem Chocolatey instalado)
```powershell
choco install ghostscript -y
gs --version
```

**Opção 3: Via Scoop** (se você tem Scoop instalado)
```powershell
scoop install ghostscript
gs --version
```

### 2️⃣ Instalar gRPC (vcpkg)

```powershell
# Instalar vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install

# Instalar gRPC e Protobuf
.\vcpkg install grpc protobuf

# Anotar o caminho do vcpkg para usar no CMake
$env:VCPKG_ROOT = (Get-Location).Path
```

### 3️⃣ Clonar e Configurar

```powershell
# Clonar repositório
git clone https://github.com/mrblackoutz/computacao-distribuida.git
cd computacao-distribuida

# Gerar código protobuf
.\scripts\generate_proto.ps1

# Compilar tudo
.\scripts\build.ps1 -All
```

### 4️⃣ Preparar Arquivos de Teste

```powershell
.\scripts\prepare_test_files.ps1
```

Ou adicione seus próprios arquivos em `tests\test_files\`:
- PDFs para testar compressão e conversão
- Imagens (JPG, PNG) para testar conversão e redimensionamento

### 5️⃣ Executar!

**Terminal 1 - Servidor:**
```powershell
.\scripts\run_server.ps1
```

**Terminal 2 - Cliente Python:**
```powershell
.\scripts\run_client_python.ps1
```

**Ou Cliente C++:**
```powershell
.\scripts\run_client_cpp.ps1
```

## 🧪 Executar Testes

```powershell
# Com servidor rodando
.\scripts\run_tests.ps1
```

## 🐳 Usando Docker (Alternativa)

Se você tem Docker instalado, é ainda mais fácil:

```powershell
# Construir e iniciar servidor
docker-compose up -d server

# Ver logs
docker-compose logs -f server

# Executar cliente Python
docker-compose --profile client up client-python

# Parar tudo
docker-compose down
```

## 📋 Comandos Úteis

### Build

```powershell
# Compilar apenas servidor
.\scripts\build.ps1 -Server

# Compilar apenas cliente C++
.\scripts\build.ps1 -ClientCpp

# Configurar apenas cliente Python
.\scripts\build.ps1 -ClientPython

# Limpar e recompilar tudo
.\scripts\build.ps1 -All -Clean
```

### Execução

```powershell
# Servidor em porta customizada
.\scripts\run_server.ps1 -Address "0.0.0.0:50052"

# Cliente conectando a servidor remoto
.\scripts\run_client_python.ps1 -Server "192.168.1.100:50051"
```

### Testes

```powershell
# Testes contra servidor remoto
.\scripts\run_tests.ps1 -Server "192.168.1.100:50051"
```

## 🔧 Solução de Problemas

### Erro: "protoc not found"

```powershell
# Adicionar vcpkg ao PATH
$env:PATH += ";$env:VCPKG_ROOT\installed\x64-windows\tools\protobuf"
```

### Erro: "grpc_cpp_plugin not found"

```powershell
# Adicionar vcpkg ao PATH
$env:PATH += ";$env:VCPKG_ROOT\installed\x64-windows\tools\grpc"
```

### Erro: CMake não encontra gRPC

```powershell
# Usar toolchain do vcpkg
cd server_cpp\build
cmake .. -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
```

### Servidor não inicia - Porta em uso

```powershell
# Verificar o que está usando a porta
netstat -ano | findstr :50051

# Matar processo (substitua PID)
taskkill /PID <PID> /F

# Ou use outra porta
.\scripts\run_server.ps1 -Address "0.0.0.0:50052"
```

### ImageMagick: "not authorized"

Edite o arquivo de política do ImageMagick:
- Localize: `C:\Program Files\ImageMagick-X.X.X\policy.xml`
- Comente as linhas que bloqueiam PDF:
  ```xml
  <!-- <policy domain="coder" rights="none" pattern="PDF" /> -->
  ```

## 📚 Próximos Passos

1. **Leia o README.md** para documentação completa
2. **Veja RELATORIO.md** para detalhes técnicos
3. **Explore o código** em `server_cpp/` e `client_python/`
4. **Adicione novos serviços** editando `proto/file_processor.proto`

## 🎯 Estrutura Rápida

```
.
├── proto/                      # Definições protobuf
├── server_cpp/                 # Servidor C++
├── client_cpp/                 # Cliente C++
├── client_python/              # Cliente Python
├── scripts/                    # Scripts de automação
├── tests/                      # Testes e arquivos de teste
└── docker-compose.yml          # Orquestração Docker
```

## ✅ Checklist de Verificação

- [ ] vcpkg instalado e integrado
- [ ] gRPC e protobuf instalados via vcpkg
- [ ] Ghostscript instalado
- [ ] ImageMagick instalado  
- [ ] Poppler instalado
- [ ] Python 3.8+ instalado
- [ ] Código protobuf gerado
- [ ] Projeto compilado
- [ ] Arquivos de teste preparados
- [ ] Servidor iniciado
- [ ] Cliente conectado com sucesso

## 💡 Dicas

1. **Use PowerShell ISE ou VS Code** para melhor experiência com scripts
2. **Mantenha terminais separados** para servidor e cliente
3. **Verifique logs** em `logs/server.log` para debugging
4. **Use Docker** para ambiente mais consistente
5. **Consulte README.md** para documentação detalhada

## 🤝 Precisa de Ajuda?

- Verifique [Troubleshooting no README](README.md#troubleshooting)
- Veja os logs do servidor em `logs/server.log`
- Revise a documentação do gRPC: https://grpc.io/docs/

---

**Boa sorte e bom desenvolvimento! 🚀**
