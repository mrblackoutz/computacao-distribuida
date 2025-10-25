#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Suite de testes para o File Processor gRPC Service
"""

import os
import sys
import time
import unittest
from pathlib import Path

# Adicionar diretório do cliente ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'client_python'))

# Verificar se os módulos gerados existem
generated_path = os.path.join(os.path.dirname(__file__), '..', 'client_python', 'generated')
if not os.path.exists(generated_path):
    print("❌ Arquivos protobuf não foram gerados!")
    print("Execute primeiro: .\\scripts\\generate_proto.ps1")
    sys.exit(1)

try:
    from client import FileProcessorClient
except ImportError as e:
    print(f"❌ Erro ao importar cliente: {e}")
    print("Certifique-se de que o código protobuf foi gerado corretamente.")
    sys.exit(1)


class FileProcessorTestCase(unittest.TestCase):
    """Testes do serviço de processamento de arquivos"""
    
    @classmethod
    def setUpClass(cls):
        """Setup executado uma vez antes de todos os testes"""
        cls.server_address = os.environ.get('GRPC_SERVER', 'localhost:50051')
        cls.client = FileProcessorClient(cls.server_address)
        cls.test_files_dir = Path(__file__).parent / 'test_files'
        cls.results_dir = Path(__file__).parent / 'test_results'
        cls.results_dir.mkdir(exist_ok=True)
        
        print("\n" + "="*60)
        print("File Processor gRPC - Test Suite")
        print(f"Server: {cls.server_address}")
        print("="*60 + "\n")
    
    @classmethod
    def tearDownClass(cls):
        """Cleanup executado uma vez após todos os testes"""
        cls.client.close()
        print("\n" + "="*60)
        print("Test Suite Completed")
        print("="*60 + "\n")
    
    def test_01_server_connectivity(self):
        """Teste de conectividade com o servidor"""
        print("\n[TEST] Server Connectivity")
        print("-" * 60)
        
        try:
            # Tentar criar conexão
            import grpc
            channel = grpc.insecure_channel(
                self.server_address,
                options=[('grpc.enable_http_proxy', 0)]
            )
            
            # Verificar se canal está pronto (timeout de 5 segundos)
            grpc.channel_ready_future(channel).result(timeout=5)
            
            channel.close()
            print("✅ Servidor está acessível")
            self.assertTrue(True)
            
        except grpc.FutureTimeoutError:
            print("❌ Timeout ao conectar ao servidor")
            self.fail(f"Não foi possível conectar ao servidor em {self.server_address}")
        except Exception as e:
            print(f"❌ Erro: {e}")
            self.fail(f"Erro ao verificar conectividade: {e}")
    
    def test_02_test_files_exist(self):
        """Verificar se arquivos de teste existem"""
        print("\n[TEST] Test Files Availability")
        print("-" * 60)
        
        # Verificar diretório de teste
        self.assertTrue(self.test_files_dir.exists(), 
                       f"Diretório de testes não existe: {self.test_files_dir}")
        
        # Listar arquivos disponíveis
        test_files = list(self.test_files_dir.glob("*"))
        print(f"Arquivos de teste encontrados: {len(test_files)}")
        
        for f in test_files:
            print(f"  - {f.name} ({f.stat().st_size} bytes)")
        
        if len(test_files) == 0:
            print("⚠️  Nenhum arquivo de teste encontrado")
            print("   Execute: .\\scripts\\prepare_test_files.ps1")
    
    def test_03_compress_pdf_if_available(self):
        """Teste de compressão de PDF (se disponível)"""
        print("\n[TEST] Compress PDF (Optional)")
        print("-" * 60)
        
        # Procurar arquivo PDF
        pdf_files = list(self.test_files_dir.glob("*.pdf"))
        
        if not pdf_files:
            print("⚠️  Nenhum arquivo PDF encontrado - teste pulado")
            self.skipTest("Nenhum arquivo PDF disponível para teste")
        
        input_file = pdf_files[0]
        output_file = self.results_dir / f"compressed_{input_file.name}"
        
        print(f"Input: {input_file.name}")
        
        start_time = time.time()
        success = self.client.compress_pdf(str(input_file), str(output_file))
        duration = time.time() - start_time
        
        if success:
            input_size = input_file.stat().st_size
            output_size = output_file.stat().st_size
            compression = (1 - output_size/input_size) * 100
            
            print(f"✅ Compressão bem-sucedida!")
            print(f"   Input:  {input_size:,} bytes")
            print(f"   Output: {output_size:,} bytes")
            print(f"   Redução: {compression:.1f}%")
            print(f"   Tempo: {duration:.2f}s")
            
            self.assertTrue(output_file.exists())
            self.assertLess(output_size, input_size)
        else:
            print("❌ Compressão falhou")
            self.fail("Compressão de PDF falhou")
    
    def test_04_convert_pdf_to_txt_if_available(self):
        """Teste de conversão PDF para TXT (se disponível)"""
        print("\n[TEST] Convert PDF to TXT (Optional)")
        print("-" * 60)
        
        # Procurar arquivo PDF
        pdf_files = list(self.test_files_dir.glob("*.pdf"))
        
        if not pdf_files:
            print("⚠️  Nenhum arquivo PDF encontrado - teste pulado")
            self.skipTest("Nenhum arquivo PDF disponível para teste")
        
        input_file = pdf_files[0]
        output_file = self.results_dir / f"{input_file.stem}.txt"
        
        print(f"Input: {input_file.name}")
        
        start_time = time.time()
        success = self.client.convert_to_txt(str(input_file), str(output_file))
        duration = time.time() - start_time
        
        if success:
            output_size = output_file.stat().st_size
            
            print(f"✅ Conversão bem-sucedida!")
            print(f"   Output: {output_size:,} bytes")
            print(f"   Tempo: {duration:.2f}s")
            
            self.assertTrue(output_file.exists())
            self.assertGreater(output_size, 0)
        else:
            print("❌ Conversão falhou")
            self.fail("Conversão PDF to TXT falhou")
    
    def test_05_convert_image_if_available(self):
        """Teste de conversão de imagem (se disponível)"""
        print("\n[TEST] Convert Image Format (Optional)")
        print("-" * 60)
        
        # Procurar arquivos de imagem
        image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp']
        image_files = []
        for ext in image_extensions:
            image_files.extend(self.test_files_dir.glob(ext))
        
        if not image_files:
            print("⚠️  Nenhuma imagem encontrada - teste pulado")
            self.skipTest("Nenhuma imagem disponível para teste")
        
        input_file = image_files[0]
        output_file = self.results_dir / f"{input_file.stem}_converted.png"
        
        print(f"Input: {input_file.name}")
        
        start_time = time.time()
        success = self.client.convert_image_format(
            str(input_file), str(output_file), 'png')
        duration = time.time() - start_time
        
        if success:
            output_size = output_file.stat().st_size
            
            print(f"✅ Conversão bem-sucedida!")
            print(f"   Output: {output_size:,} bytes")
            print(f"   Tempo: {duration:.2f}s")
            
            self.assertTrue(output_file.exists())
            self.assertGreater(output_size, 0)
        else:
            print("❌ Conversão falhou")
            self.fail("Conversão de imagem falhou")
    
    def test_06_resize_image_if_available(self):
        """Teste de redimensionamento de imagem (se disponível)"""
        print("\n[TEST] Resize Image (Optional)")
        print("-" * 60)
        
        # Procurar arquivos de imagem
        image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp']
        image_files = []
        for ext in image_extensions:
            image_files.extend(self.test_files_dir.glob(ext))
        
        if not image_files:
            print("⚠️  Nenhuma imagem encontrada - teste pulado")
            self.skipTest("Nenhuma imagem disponível para teste")
        
        input_file = image_files[0]
        output_file = self.results_dir / f"{input_file.stem}_resized.jpg"
        
        width, height = 400, 300
        print(f"Input: {input_file.name}")
        print(f"Target size: {width}x{height}")
        
        start_time = time.time()
        success = self.client.resize_image(
            str(input_file), str(output_file), width, height)
        duration = time.time() - start_time
        
        if success:
            input_size = input_file.stat().st_size
            output_size = output_file.stat().st_size
            
            print(f"✅ Redimensionamento bem-sucedido!")
            print(f"   Input:  {input_size:,} bytes")
            print(f"   Output: {output_size:,} bytes")
            print(f"   Tempo: {duration:.2f}s")
            
            self.assertTrue(output_file.exists())
        else:
            print("❌ Redimensionamento falhou")
            self.fail("Redimensionamento de imagem falhou")


def run_tests():
    """Executa suite de testes"""
    # Criar test suite
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(FileProcessorTestCase)
    
    # Executar testes com verbosity
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Resumo
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"Tests run:     {result.testsRun}")
    print(f"Successes:     {result.testsRun - len(result.failures) - len(result.errors) - len(result.skipped)}")
    print(f"Failures:      {len(result.failures)}")
    print(f"Errors:        {len(result.errors)}")
    print(f"Skipped:       {len(result.skipped)}")
    print("="*60 + "\n")
    
    return result.wasSuccessful()


if __name__ == '__main__':
    # Verificar se servidor está acessível antes de executar testes
    print("🔍 Verificando disponibilidade do servidor...")
    
    try:
        import grpc
        server_address = os.environ.get('GRPC_SERVER', 'localhost:50051')
        channel = grpc.insecure_channel(server_address)
        
        try:
            grpc.channel_ready_future(channel).result(timeout=3)
            print(f"✅ Servidor acessível em {server_address}\n")
        except grpc.FutureTimeoutError:
            print(f"❌ Servidor não está rodando em {server_address}")
            print("\nPara iniciar o servidor:")
            print("  .\\scripts\\run_server.ps1")
            print("  ou")
            print("  docker-compose up -d server")
            sys.exit(1)
        finally:
            channel.close()
            
    except Exception as e:
        print(f"⚠️  Aviso: Não foi possível verificar o servidor: {e}")
    
    # Executar testes
    success = run_tests()
    sys.exit(0 if success else 1)
