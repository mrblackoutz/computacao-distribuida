#include <iostream>
#include <fstream>
#include <memory>
#include <string>
#include <iomanip>
#include <chrono>
#include <vector>

#include <grpcpp/grpcpp.h>
#include "file_processor.grpc.pb.h"

#ifdef _WIN32
#include <sys/stat.h>
#define stat _stat
#else
#include <sys/stat.h>
#endif

class FileProcessorClient {
public:
    FileProcessorClient(std::shared_ptr<grpc::Channel> channel)
        : stub_(file_processor::FileProcessorService::NewStub(channel)) {}

    bool CompressPDF(const std::string& input_path,
                     const std::string& output_path) {
        return processFile("CompressPDF", input_path, output_path,
                          [this](grpc::ClientContext* context) {
                              return stub_->CompressPDF(context);
                          });
    }

    bool ConvertToTXT(const std::string& input_path,
                      const std::string& output_path) {
        return processFile("ConvertToTXT", input_path, output_path,
                          [this](grpc::ClientContext* context) {
                              return stub_->ConvertToTXT(context);
                          });
    }

    bool ConvertImageFormat(const std::string& input_path,
                           const std::string& output_path,
                           const std::string& format) {
        return processFile("ConvertImageFormat", input_path, output_path,
                          [this](grpc::ClientContext* context) {
                              return stub_->ConvertImageFormat(context);
                          });
    }

    bool ResizeImage(const std::string& input_path,
                    const std::string& output_path,
                    int width, int height) {
        return processFile("ResizeImage", input_path, output_path,
                          [this](grpc::ClientContext* context) {
                              return stub_->ResizeImage(context);
                          });
    }

private:
    template<typename Func>
    bool processFile(const std::string& operation,
                    const std::string& input_path,
                    const std::string& output_path,
                    Func rpc_call) {
        
        std::cout << "\n┌─────────────────────────────────────┐\n";
        std::cout << "│ " << std::setw(35) << std::left 
                  << operation << "│\n";
        std::cout << "└─────────────────────────────────────┘\n\n";
        
        // Verificar arquivo de entrada
        if (!fileExists(input_path)) {
            std::cerr << "❌ Error: Input file not found: " 
                     << input_path << std::endl;
            return false;
        }
        
        auto file_size = getFileSize(input_path);
        std::cout << "📄 Input file: " << input_path << std::endl;
        std::cout << "📊 File size: " << formatFileSize(file_size) << std::endl;
        
        grpc::ClientContext context;
        auto stream = rpc_call(&context);
        
        if (!stream) {
            std::cerr << "❌ Error: Failed to create stream" << std::endl;
            return false;
        }
        
        // Enviar arquivo
        std::cout << "⬆️  Uploading file..." << std::endl;
        auto start_upload = std::chrono::high_resolution_clock::now();
        
        if (!sendFile(stream.get(), input_path)) {
            std::cerr << "❌ Error: Failed to send file" << std::endl;
            return false;
        }
        
        stream->WritesDone();
        
        auto end_upload = std::chrono::high_resolution_clock::now();
        auto upload_duration = std::chrono::duration_cast<
            std::chrono::milliseconds>(end_upload - start_upload);
        
        std::cout << "✅ Upload completed in " << upload_duration.count() 
                  << "ms" << std::endl;
        
        // Receber arquivo
        std::cout << "⬇️  Downloading result..." << std::endl;
        auto start_download = std::chrono::high_resolution_clock::now();
        
        if (!receiveFile(stream.get(), output_path)) {
            std::cerr << "❌ Error: Failed to receive file" << std::endl;
            return false;
        }
        
        auto end_download = std::chrono::high_resolution_clock::now();
        auto download_duration = std::chrono::duration_cast<
            std::chrono::milliseconds>(end_download - start_download);
        
        grpc::Status status = stream->Finish();
        
        if (!status.ok()) {
            std::cerr << "❌ RPC failed: " << status.error_message() << std::endl;
            return false;
        }
        
        auto output_size = getFileSize(output_path);
        
        std::cout << "✅ Download completed in " << download_duration.count() 
                  << "ms" << std::endl;
        std::cout << "💾 Output file: " << output_path << std::endl;
        std::cout << "📊 Output size: " << formatFileSize(output_size) << std::endl;
        
        auto total_duration = upload_duration + download_duration;
        std::cout << "\n⏱️  Total time: " << total_duration.count() 
                  << "ms" << std::endl;
        std::cout << "✅ Operation completed successfully!\n" << std::endl;
        
        return true;
    }

    bool sendFile(grpc::ClientReaderWriter<file_processor::FileChunk,
                                           file_processor::FileChunk>* stream,
                 const std::string& file_path) {
        
        std::ifstream file(file_path, std::ios::binary);
        if (!file) {
            return false;
        }
        
        const size_t chunk_size = 64 * 1024; // 64KB
        std::vector<char> buffer(chunk_size);
        size_t total_sent = 0;
        
        while (file.read(buffer.data(), chunk_size) || file.gcount() > 0) {
            file_processor::FileChunk chunk;
            chunk.set_content(buffer.data(), file.gcount());
            
            if (!stream->Write(chunk)) {
                return false;
            }
            
            total_sent += file.gcount();
        }
        
        return true;
    }

    bool receiveFile(grpc::ClientReaderWriter<file_processor::FileChunk,
                                              file_processor::FileChunk>* stream,
                    const std::string& file_path) {
        
        std::ofstream file(file_path, std::ios::binary);
        if (!file) {
            return false;
        }
        
        file_processor::FileChunk chunk;
        size_t total_received = 0;
        
        while (stream->Read(&chunk)) {
            file.write(chunk.content().c_str(), chunk.content().size());
            total_received += chunk.content().size();
            
            if (!file.good()) {
                return false;
            }
        }
        
        return true;
    }

    bool fileExists(const std::string& path) {
        struct stat buffer;
        return (stat(path.c_str(), &buffer) == 0);
    }

    size_t getFileSize(const std::string& path) {
        struct stat buffer;
        if (stat(path.c_str(), &buffer) == 0) {
            return buffer.st_size;
        }
        return 0;
    }

    std::string formatFileSize(size_t bytes) {
        const char* units[] = {"B", "KB", "MB", "GB"};
        int unit_index = 0;
        double size = static_cast<double>(bytes);
        
        while (size >= 1024 && unit_index < 3) {
            size /= 1024;
            unit_index++;
        }
        
        std::ostringstream oss;
        oss << std::fixed << std::setprecision(2) << size 
            << " " << units[unit_index];
        return oss.str();
    }

    std::unique_ptr<file_processor::FileProcessorService::Stub> stub_;
};

void printMenu() {
    std::cout << "\n╔════════════════════════════════════════╗\n";
    std::cout << "║   File Processor gRPC Client (C++)    ║\n";
    std::cout << "╠════════════════════════════════════════╣\n";
    std::cout << "║  1. Compress PDF                       ║\n";
    std::cout << "║  2. Convert PDF to TXT                 ║\n";
    std::cout << "║  3. Convert Image Format               ║\n";
    std::cout << "║  4. Resize Image                       ║\n";
    std::cout << "║  5. Exit                               ║\n";
    std::cout << "╚════════════════════════════════════════╝\n";
    std::cout << "\nChoose an option: ";
}

int main(int argc, char** argv) {
    std::string server_address = "localhost:50051";
    
    if (argc > 1) {
        server_address = argv[1];
    }
    
    grpc::ChannelArguments args;
    args.SetMaxReceiveMessageSize(100 * 1024 * 1024);
    args.SetMaxSendMessageSize(100 * 1024 * 1024);
    
    auto channel = grpc::CreateCustomChannel(
        server_address, 
        grpc::InsecureChannelCredentials(),
        args);
    
    FileProcessorClient client(channel);
    
    while (true) {
        printMenu();
        
        int choice;
        std::cin >> choice;
        std::cin.ignore();
        
        if (choice == 5) {
            std::cout << "\n👋 Goodbye!\n" << std::endl;
            break;
        }
        
        std::string input_file, output_file;
        
        std::cout << "\nInput file path: ";
        std::getline(std::cin, input_file);
        
        std::cout << "Output file path: ";
        std::getline(std::cin, output_file);
        
        bool success = false;
        
        switch (choice) {
            case 1:
                success = client.CompressPDF(input_file, output_file);
                break;
            case 2:
                success = client.ConvertToTXT(input_file, output_file);
                break;
            case 3: {
                std::string format;
                std::cout << "Output format (png, jpg, etc.): ";
                std::getline(std::cin, format);
                success = client.ConvertImageFormat(input_file, output_file, format);
                break;
            }
            case 4: {
                int width, height;
                std::cout << "Width: ";
                std::cin >> width;
                std::cout << "Height: ";
                std::cin >> height;
                success = client.ResizeImage(input_file, output_file, width, height);
                break;
            }
            default:
                std::cout << "❌ Invalid option!" << std::endl;
        }
        
        if (!success) {
            std::cout << "\n❌ Operation failed!\n" << std::endl;
        }
    }
    
    return 0;
}
