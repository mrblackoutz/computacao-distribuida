#include <iostream>
#include <memory>
#include <string>
#include <csignal>
#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>

#include "file_processor_service_impl.h"
#include "logger.h"

std::unique_ptr<grpc::Server> server;

void signalHandler(int signal) {
    Logger::getInstance().log(LogLevel::INFO_LEVEL, "System", "N/A",
                             "Shutdown signal received");
    if (server) {
        server->Shutdown();
    }
}

void RunServer(const std::string& server_address) {
    Logger& logger = Logger::getInstance();
    logger.setLogFile("../logs/server.log");
    
    FileProcessorServiceImpl service;
    
    grpc::EnableDefaultHealthCheckService(true);
    grpc::reflection::InitProtoReflectionServerBuilderPlugin();
    
    grpc::ServerBuilder builder;
    
    // Configurações do servidor
    builder.AddListeningPort(server_address,
                            grpc::InsecureServerCredentials());
    builder.RegisterService(&service);
    
    // Configurações de tamanho de mensagem (importante para arquivos grandes)
    builder.SetMaxReceiveMessageSize(100 * 1024 * 1024); // 100MB
    builder.SetMaxSendMessageSize(100 * 1024 * 1024);    // 100MB
    
    server = builder.BuildAndStart();
    
    logger.log(LogLevel::SUCCESS_LEVEL, "System", "N/A",
              "Server listening on " + server_address);
    
    std::cout << "\n";
    std::cout << "╔════════════════════════════════════════════╗\n";
    std::cout << "║   File Processor gRPC Server Started      ║\n";
    std::cout << "╠════════════════════════════════════════════╣\n";
    std::cout << "║  Address: " << server_address;
    // Padding to align
    int padding = 28 - server_address.length();
    for(int i = 0; i < padding; i++) std::cout << " ";
    std::cout << "║\n";
    std::cout << "║  Press Ctrl+C to shutdown                  ║\n";
    std::cout << "╚════════════════════════════════════════════╝\n";
    std::cout << "\n";
    
    server->Wait();
    
    logger.log(LogLevel::INFO_LEVEL, "System", "N/A", "Server shutdown complete");
}

int main(int argc, char** argv) {
    std::string server_address = "0.0.0.0:50051";
    
    if (argc > 1) {
        server_address = argv[1];
    }
    
    // Registrar handler de sinal para shutdown gracioso
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);
    
    try {
        RunServer(server_address);
    } catch (const std::exception& e) {
        std::cerr << "Server error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
