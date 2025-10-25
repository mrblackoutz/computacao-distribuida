FROM python:3.11-slim

WORKDIR /app

# Instalar dependências
COPY client_python/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY proto/ ../proto/
COPY client_python/client.py .

# Gerar código protobuf Python
RUN mkdir -p generated && \
    python -m grpc_tools.protoc \
    -I=../proto \
    --python_out=generated \
    --grpc_python_out=generated \
    ../proto/file_processor.proto && \
    touch generated/__init__.py

# Criar diretórios para arquivos
RUN mkdir -p /app/input /app/output

ENTRYPOINT ["python", "client.py"]
CMD ["--server=server:50051"]
