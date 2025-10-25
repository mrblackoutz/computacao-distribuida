#ifndef FILE_PROCESSOR_SERVICE_IMPL_H
#define FILE_PROCESSOR_SERVICE_IMPL_H

#include <grpcpp/grpcpp.h>
#include "file_processor.grpc.pb.h"
#include "logger.h"
#include "file_processor_utils.h"

class FileProcessorServiceImpl final 
    : public file_processor::FileProcessorService::Service {
public:
    FileProcessorServiceImpl();
    ~FileProcessorServiceImpl();

    // Compressão de PDF
    grpc::Status CompressPDF(
        grpc::ServerContext* context,
        grpc::ServerReaderWriter<file_processor::FileChunk,
                                file_processor::FileChunk>* stream) override;

    // Conversão PDF para TXT
    grpc::Status ConvertToTXT(
        grpc::ServerContext* context,
        grpc::ServerReaderWriter<file_processor::FileChunk,
                                file_processor::FileChunk>* stream) override;

    // Conversão de formato de imagem
    grpc::Status ConvertImageFormat(
        grpc::ServerContext* context,
        grpc::ServerReaderWriter<file_processor::FileChunk,
                                file_processor::FileChunk>* stream) override;

    // Redimensionamento de imagem
    grpc::Status ResizeImage(
        grpc::ServerContext* context,
        grpc::ServerReaderWriter<file_processor::FileChunk,
                                file_processor::FileChunk>* stream) override;

private:
    // Receber arquivo via streaming
    bool receiveFile(grpc::ServerReaderWriter<file_processor::FileChunk,
                                             file_processor::FileChunk>* stream,
                    const std::string& output_path,
                    std::string& error_message);

    // Enviar arquivo via streaming
    bool sendFile(grpc::ServerReaderWriter<file_processor::FileChunk,
                                          file_processor::FileChunk>* stream,
                 const std::string& input_path,
                 std::string& error_message);

    Logger& logger_;
};

#endif // FILE_PROCESSOR_SERVICE_IMPL_H
