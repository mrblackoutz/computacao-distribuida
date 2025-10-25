#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import grpc
import os
import sys
import time
from pathlib import Path
from typing import Optional

# Import generated protobuf files
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'generated'))
import file_processor_pb2
import file_processor_pb2_grpc


class FileProcessorClient:
    """Cliente gRPC para processamento de arquivos"""
    
    CHUNK_SIZE = 64 * 1024  # 64KB
    
    def __init__(self, server_address: str = 'localhost:50051'):
        """
        Inicializa o cliente
        
        Args:
            server_address: Endereço do servidor gRPC
        """
        self.server_address = server_address
        self.channel = grpc.insecure_channel(
            server_address,
            options=[
                ('grpc.max_receive_message_length', 100 * 1024 * 1024),
                ('grpc.max_send_message_length', 100 * 1024 * 1024),
            ]
        )
        self.stub = file_processor_pb2_grpc.FileProcessorServiceStub(
            self.channel)
    
    def _send_file(self, file_path: str):
        """
        Gerador para enviar arquivo em chunks
        
        Args:
            file_path: Caminho do arquivo
            
        Yields:
            FileChunk: Chunks do arquivo
        """
        with open(file_path, 'rb') as f:
            while True:
                chunk_data = f.read(self.CHUNK_SIZE)
                if not chunk_data:
                    break
                yield file_processor_pb2.FileChunk(content=chunk_data)
    
    def _receive_file(self, response_iterator, output_path: str) -> int:
        """
        Recebe arquivo do servidor
        
        Args:
            response_iterator: Iterador de resposta do servidor
            output_path: Caminho para salvar arquivo
            
        Returns:
            int: Número de bytes recebidos
        """
        total_bytes = 0
        with open(output_path, 'wb') as f:
            for chunk in response_iterator:
                f.write(chunk.content)
                total_bytes += len(chunk.content)
        return total_bytes
    
    def _format_file_size(self, bytes_size: int) -> str:
        """
        Formata tamanho de arquivo
        
        Args:
            bytes_size: Tamanho em bytes
            
        Returns:
            str: Tamanho formatado
        """
        units = ['B', 'KB', 'MB', 'GB']
        unit_index = 0
        size = float(bytes_size)
        
        while size >= 1024 and unit_index < len(units) - 1:
            size /= 1024
            unit_index += 1
        
        return f"{size:.2f} {units[unit_index]}"
    
    def _process_file(self, operation_name: str, input_path: str,
                     output_path: str, rpc_method) -> bool:
        """
        Processa arquivo genérico
        
        Args:
            operation_name: Nome da operação
            input_path: Caminho do arquivo de entrada
            output_path: Caminho do arquivo de saída
            rpc_method: Método RPC a ser chamado
            
        Returns:
            bool: True se sucesso, False caso contrário
        """
        print(f"\n┌─────────────────────────────────────┐")
        print(f"│ {operation_name:35} │")
        print(f"└─────────────────────────────────────┘\n")
        
        # Verificar arquivo de entrada
        if not os.path.exists(input_path):
            print(f"❌ Error: Input file not found: {input_path}")
            return False
        
        input_size = os.path.getsize(input_path)
        print(f"📄 Input file: {input_path}")
        print(f"📊 File size: {self._format_file_size(input_size)}")
        
        try:
            # Enviar arquivo
            print("⬆️  Uploading file...")
            start_upload = time.time()
            
            response_iterator = rpc_method(self._send_file(input_path))
            
            end_upload = time.time()
            upload_duration = (end_upload - start_upload) * 1000
            print(f"✅ Upload completed in {upload_duration:.0f}ms")
            
            # Receber arquivo
            print("⬇️  Downloading result...")
            start_download = time.time()
            
            total_received = self._receive_file(response_iterator, output_path)
            
            end_download = time.time()
            download_duration = (end_download - start_download) * 1000
            
            print(f"✅ Download completed in {download_duration:.0f}ms")
            print(f"💾 Output file: {output_path}")
            print(f"📊 Output size: {self._format_file_size(total_received)}")
            
            total_duration = upload_duration + download_duration
            print(f"\n⏱️  Total time: {total_duration:.0f}ms")
            print("✅ Operation completed successfully!\n")
            
            return True
            
        except grpc.RpcError as e:
            print(f"❌ RPC error: {e.code()}: {e.details()}")
            return False
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return False
    
    def compress_pdf(self, input_path: str, output_path: str) -> bool:
        """
        Comprime PDF
        
        Args:
            input_path: Caminho do PDF de entrada
            output_path: Caminho do PDF comprimido
            
        Returns:
            bool: True se sucesso
        """
        return self._process_file(
            "Compress PDF",
            input_path,
            output_path,
            self.stub.CompressPDF
        )
    
    def convert_to_txt(self, input_path: str, output_path: str) -> bool:
        """
        Converte PDF para TXT
        
        Args:
            input_path: Caminho do PDF de entrada
            output_path: Caminho do TXT de saída
            
        Returns:
            bool: True se sucesso
        """
        return self._process_file(
            "Convert PDF to TXT",
            input_path,
            output_path,
            self.stub.ConvertToTXT
        )
    
    def convert_image_format(self, input_path: str, output_path: str,
                            output_format: str) -> bool:
        """
        Converte formato de imagem
        
        Args:
            input_path: Caminho da imagem de entrada
            output_path: Caminho da imagem de saída
            output_format: Formato de saída (ex: "png", "jpg")
            
        Returns:
            bool: True se sucesso
        """
        return self._process_file(
            f"Convert Image to {output_format.upper()}",
            input_path,
            output_path,
            self.stub.ConvertImageFormat
        )
    
    def resize_image(self, input_path: str, output_path: str,
                    width: int, height: int) -> bool:
        """
        Redimensiona imagem
        
        Args:
            input_path: Caminho da imagem de entrada
            output_path: Caminho da imagem de saída
            width: Largura desejada
            height: Altura desejada
            
        Returns:
            bool: True se sucesso
        """
        return self._process_file(
            f"Resize Image to {width}x{height}",
            input_path,
            output_path,
            self.stub.ResizeImage
        )
    
    def close(self):
        """Fecha conexão com servidor"""
        self.channel.close()


def print_menu():
    """Imprime menu interativo"""
    print("\n╔════════════════════════════════════════╗")
    print("║   File Processor gRPC Client (Python) ║")
    print("╠════════════════════════════════════════╣")
    print("║  1. Compress PDF                       ║")
    print("║  2. Convert PDF to TXT                 ║")
    print("║  3. Convert Image Format               ║")
    print("║  4. Resize Image                       ║")
    print("║  5. Exit                               ║")
    print("╚════════════════════════════════════════╝")
    print("\nChoose an option: ", end='')


def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='File Processor gRPC Client')
    parser.add_argument(
        '--server',
        default='localhost:50051',
        help='Server address (default: localhost:50051)'
    )
    
    args = parser.parse_args()
    
    client = FileProcessorClient(args.server)
    
    try:
        while True:
            print_menu()
            
            try:
                choice = int(input())
            except ValueError:
                print("❌ Invalid input!")
                continue
            
            if choice == 5:
                print("\n👋 Goodbye!\n")
                break
            
            input_file = input("\nInput file path: ").strip()
            output_file = input("Output file path: ").strip()
            
            success = False
            
            if choice == 1:
                success = client.compress_pdf(input_file, output_file)
            elif choice == 2:
                success = client.convert_to_txt(input_file, output_file)
            elif choice == 3:
                output_format = input("Output format (png, jpg, etc.): ").strip()
                success = client.convert_image_format(
                    input_file, output_file, output_format)
            elif choice == 4:
                try:
                    width = int(input("Width: "))
                    height = int(input("Height: "))
                    success = client.resize_image(
                        input_file, output_file, width, height)
                except ValueError:
                    print("❌ Invalid dimensions!")
            else:
                print("❌ Invalid option!")
            
            if not success:
                print("\n❌ Operation failed!\n")
    
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user\n")
    finally:
        client.close()


if __name__ == '__main__':
    main()
