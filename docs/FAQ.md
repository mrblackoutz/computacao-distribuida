# ❓ FAQ - Perguntas Frequentes

## Suporte Linux e Cross-Platform

### P: Como executo o projeto no Linux?

**R:** Muito simples! Três passos:

```bash
# 1. Tornar scripts executáveis
chmod +x run.sh setup.sh scripts/*.sh

# 2. Setup automático
./setup.sh

# 3. Usar normalmente
./run.sh server
```

Veja [LINUX.md](LINUX.md) para detalhes completos.

---

### P: O runner universal detecta automaticamente o sistema operacional?

**R:** Sim! O arquivo `run.sh` detecta automaticamente se você está em:
- **Windows** → Executa scripts `.ps1` via PowerShell
- **Linux** → Executa scripts `.sh` via Bash
- **macOS** → Executa scripts `.sh` via Bash

Basta usar:
```bash
./run.sh setup
./run.sh server
./run.sh client-python
```

---

### P: Posso continuar usando PowerShell no Windows?

**R:** Sim! Absolutamente nada mudou para Windows. Continue usando:
```powershell
.\setup.ps1
.\scripts\run_server.ps1
.\scripts\run_client_python.ps1
```

Os scripts Bash são **adicionais**, não substituições.

---

### P: Qual a diferença entre os scripts .ps1 e .sh?

**R:** Funcionalmente, **são idênticos**. Ambos fazem exatamente a mesma coisa:
- Mesmas validações
- Mesmo output colorido
- Mesmas features
- Mesmos argumentos (adaptados para cada shell)

A única diferença é a sintaxe (PowerShell vs Bash).

---

### P: Preciso instalar algo extra no Linux?

**R:** Sim, algumas dependências:

**Ubuntu/Debian:**
```bash
sudo apt-get install -y \
    build-essential cmake git \
    protobuf-compiler \
    python3 python3-pip python3-venv \
    ghostscript poppler-utils imagemagick
```

**gRPC precisa ser compilado da fonte.** Veja [LINUX.md](LINUX.md) seção "Instalar gRPC da Fonte".

---

### P: Docker funciona em ambas plataformas?

**R:** Sim! Docker funciona **identicamente** em Windows e Linux:

```bash
docker-compose up -d server
docker-compose --profile client up client-python
```

Mesmos comandos, mesmo resultado! 🐳

---

### P: Os scripts Bash funcionam no macOS?

**R:** Sim! macOS usa Bash/Zsh (ambos compatíveis), então todos os scripts `.sh` funcionam perfeitamente.

---

### P: Como sei se minhas dependências estão corretas?

**R:** Execute o setup! Ele valida tudo:

```bash
./setup.sh  # Linux
.\setup.ps1 # Windows
```

O script verifica:
- ✅ Python
- ✅ CMake
- ✅ Compilador (g++/MSVC)
- ✅ protoc
- ✅ gRPC
- ✅ Ghostscript
- ✅ Poppler
- ✅ ImageMagick

---

## Execução e Desenvolvimento

### P: Como inicio o servidor?

**R:** Depende da plataforma:

```bash
# Windows
.\scripts\run_server.ps1

# Linux
./scripts/run_server.sh

# Universal (detecta SO)
./run.sh server
```

---

### P: Como executo testes?

**R:** Certifique-se que o servidor está rodando em outro terminal, depois:

```bash
# Windows
.\scripts\run_tests.ps1

# Linux
./scripts/run_tests.sh

# Universal
./run.sh tests
```

---

### P: Posso usar porta diferente da 50051?

**R:** Sim! Use argumentos:

```bash
# Servidor em porta customizada
./scripts/run_server.sh --address 0.0.0.0:50052

# Cliente conectando a porta customizada
./scripts/run_client_python.sh --server localhost:50052
```

---

### P: Como recompilo apenas o servidor?

**R:** Use flags específicas:

```bash
# Windows
.\scripts\build.ps1 -Server

# Linux
./scripts/build.sh --server
```

---

### P: Como limpo e recompilo tudo?

**R:**
```bash
# Linux
rm -rf server_cpp/build client_cpp/build
./scripts/build.sh --all

# Windows
Remove-Item -Recurse -Force server_cpp\build,client_cpp\build
.\scripts\build.ps1 -All
```

---

## Troubleshooting

### P: "protoc not found" no Linux

**R:**
```bash
sudo apt-get install protobuf-compiler
protoc --version  # Verificar
```

---

### P: "grpc_cpp_plugin not found" no Linux

**R:** gRPC precisa ser compilado da fonte. Veja [LINUX.md](LINUX.md) seção "Instalar gRPC da Fonte". É o passo mais demorado (~30 min), mas necessário.

---

### P: "Permission denied" ao executar scripts no Linux

**R:**
```bash
chmod +x run.sh setup.sh scripts/*.sh
```

Isso torna os scripts executáveis.

---

### P: "Script execution disabled" no Windows

**R:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### P: "Porta 50051 já está em uso"

**R:** Mate o processo anterior:

**Linux:**
```bash
lsof -i :50051  # Ver processo
kill -9 <PID>   # Matar
```

**Windows:**
```powershell
netstat -ano | findstr :50051  # Ver processo
taskkill /F /PID <PID>         # Matar
```

Ou use porta diferente: `--address 0.0.0.0:50052`

---

### P: ImageMagick não converte PDFs no Linux

**R:** É uma policy de segurança. Edite:

```bash
sudo nano /etc/ImageMagick-6/policy.xml

# Comente ou remova:
<!-- <policy domain="coder" rights="none" pattern="PDF" /> -->

# Ou adicione:
<policy domain="coder" rights="read|write" pattern="PDF" />
```

---

### P: Cliente não conecta ao servidor

**R:** Verifique:

1. **Servidor está rodando?**
   ```bash
   ps aux | grep file_processor_server  # Linux
   Get-Process | Where-Object {$_.ProcessName -like "*file_processor*"}  # Windows
   ```

2. **Porta correta?**
   ```bash
   netstat -tulpn | grep 50051  # Linux
   netstat -ano | findstr :50051  # Windows
   ```

3. **Firewall bloqueando?**
   ```bash
   sudo ufw allow 50051/tcp  # Linux
   ```

---

## Docker

### P: Como buildo as imagens Docker?

**R:**
```bash
docker-compose build
```

Ou individual:
```bash
docker build -t file-processor-server -f server_cpp/Dockerfile .
```

---

### P: Como vejo logs do container?

**R:**
```bash
docker-compose logs -f server
```

Ou com Docker direto:
```bash
docker logs -f <container_id>
```

---

### P: Como entro no container rodando?

**R:**
```bash
docker-compose exec server bash
```

---

### P: Como limpo tudo do Docker?

**R:**
```bash
docker-compose down
docker system prune -a  # Cuidado: remove TUDO
```

---

## Desenvolvimento

### P: Como adiciono um novo serviço gRPC?

**R:**
1. Edite `proto/file_processor.proto` - adicione novo RPC
2. Regenere código: `./scripts/generate_proto.sh`
3. Implemente no servidor: `server_cpp/src/file_processor_service_impl.cc`
4. Implemente nos clientes: `client_cpp/src/client.cc` e `client_python/client.py`
5. Adicione testes: `tests/test_suite.py`

---

### P: Como contribuo com o projeto?

**R:**
1. Fork o repositório
2. Crie branch: `git checkout -b feature/minha-feature`
3. **Implemente em ambas plataformas** (Windows e Linux)
4. Teste em ambas plataformas
5. Commit: `git commit -m "feat: minha feature"`
6. Push: `git push origin feature/minha-feature`
7. Abra Pull Request

**Importante:** Manter compatibilidade cross-platform!

---

### P: Como atualizo apenas o protobuf?

**R:**
```bash
# Edite proto/file_processor.proto

# Regenere código
./scripts/generate_proto.sh  # Linux
.\scripts\generate_proto.ps1 # Windows

# Recompile
./scripts/build.sh --all  # Linux
.\scripts\build.ps1 -All  # Windows
```

---

## Documentação

### P: Qual documento devo ler primeiro?

**R:** Depende do seu objetivo:

| Objetivo | Documento |
|----------|-----------|
| **Usar no Windows** | [QUICKSTART.md](QUICKSTART.md) |
| **Usar no Linux** | [LINUX.md](LINUX.md) |
| **Entender compatibilidade** | [CROSSPLATFORM.md](CROSSPLATFORM.md) |
| **Documentação completa** | [README.md](README.md) |
| **Avaliar projeto** | [AVALIACAO.md](AVALIACAO.md) |
| **Entender scripts** | [scripts/README.md](scripts/README.md) |
| **Ver resumo Linux** | [RESUMO_LINUX.md](RESUMO_LINUX.md) |

---

### P: Como gero documentação do código?

**R:** O projeto usa comentários inline. Para gerar docs:

**C++ (Doxygen):**
```bash
doxygen Doxyfile  # Se tiver configurado
```

**Python (Sphinx):**
```bash
cd client_python
sphinx-apidoc -o docs .
cd docs && make html
```

---

## Performance

### P: Como otimizo a compilação?

**R:**
```bash
# Use todos os cores
./scripts/build.sh --jobs $(nproc)  # Linux
.\scripts\build.ps1 -Jobs $env:NUMBER_OF_PROCESSORS  # Windows
```

---

### P: Posso processar arquivos maiores?

**R:** Sim! O streaming suporta arquivos de qualquer tamanho. Os limites atuais são:
- Mensagem máxima: 100MB
- Chunk size: 64KB

Para arquivos maiores, ajuste em `server.cc`:
```cpp
builder.SetMaxReceiveMessageSize(500 * 1024 * 1024); // 500MB
```

---

### P: Quantos clientes simultâneos suporta?

**R:** Testado até 50 clientes simultâneos. Para produção:
- Use load balancer (nginx/envoy)
- Replique servidor
- Configure fila de processamento (RabbitMQ/Redis)

---

## Deployment

### P: Como faço deploy em produção?

**R:** **Recomendado:** Use Docker + Kubernetes:

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-processor-server
spec:
  replicas: 3
  ...
```

**Alternativa:** Executáveis nativos com systemd (Linux) ou Windows Service.

---

### P: Como monitoro o servidor em produção?

**R:**
- **Logs:** `logs/server.log`
- **Healthcheck:** gRPC health check implementado
- **Métricas:** Adicione Prometheus + Grafana
- **Tracing:** Adicione Jaeger

---

### P: Como escalo horizontalmente?

**R:**
1. Load balancer (nginx com upstream)
2. Múltiplas instâncias do servidor
3. Shared storage para arquivos temporários (NFS/S3)
4. Fila de processamento (opcional)

---

## Outros

### P: O projeto é open source?

**R:** Depende de como você configurou o repositório. O código foi desenvolvido para fins acadêmicos.

---

### P: Posso usar em produção comercial?

**R:** Depende da licença que você escolher. Considere:
- MIT License (permissiva)
- Apache 2.0 (permissiva com patentes)
- GPL (copyleft)

---

### P: Onde reporto bugs?

**R:**
1. Abra issue no GitHub
2. Inclua:
   - Sistema operacional
   - Versões das dependências
   - Logs relevantes
   - Steps to reproduce

---

### P: Como contribuo com documentação?

**R:**
1. Identifique gaps na documentação
2. Edite arquivos .md relevantes
3. Abra Pull Request
4. Mantenha formatação consistente

---

### P: Há suporte profissional disponível?

**R:** Este é um projeto acadêmico. Para produção, considere:
- Contratar desenvolvedor gRPC
- Consultoria de arquitetura distribuída
- Suporte de ferramentas (gRPC, Docker, etc.)

---

## 🎓 Recursos Adicionais

- **gRPC Docs**: https://grpc.io/docs/
- **Protocol Buffers**: https://developers.google.com/protocol-buffers
- **CMake Tutorial**: https://cmake.org/cmake/help/latest/guide/tutorial/
- **Docker Docs**: https://docs.docker.com/
- **Bash Scripting**: https://www.gnu.org/software/bash/manual/

---

## 📞 Não Encontrou Resposta?

1. Verifique documentação específica da plataforma:
   - [QUICKSTART.md](QUICKSTART.md) - Windows
   - [LINUX.md](LINUX.md) - Linux
   - [CROSSPLATFORM.md](CROSSPLATFORM.md) - Ambos

2. Verifique logs:
   ```bash
   tail -f logs/server.log
   ```

3. Execute com modo verbose (se disponível)

4. Abra issue no GitHub com detalhes completos

---

**Última atualização**: Outubro 2025  
**Mantido por**: Equipe File Processor gRPC
