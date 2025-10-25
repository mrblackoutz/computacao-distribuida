#include "file_processor_service_impl.h"
#include <fstream>
#include <sstream>
#include <vector>

FileProcessorServiceImpl::FileProcessorServiceImpl()
    : logger_(Logger::getInstance()) {
    logger_.log(LogLevel::INFO_LEVEL, "System", "N/A",
               "FileProcessorService initialized");
}

FileProcessorServiceImpl::~FileProcessorServiceImpl() {
    logger_.log(LogLevel::INFO_LEVEL, "System", "N/A",
               "FileProcessorService shutting down");
}

bool FileProcessorServiceImpl::receiveFile(
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream,
    const std::string& output_path,
    std::string& error_message) {
    
    std::ofstream output_file(output_path, std::ios::binary);
    if (!output_file) {
        error_message = "Failed to create temporary file: " + output_path;
        return false;
    }

    file_processor::FileChunk chunk;
    size_t total_bytes = 0;
    
    while (stream->Read(&chunk)) {
        output_file.write(chunk.content().c_str(), chunk.content().size());
        total_bytes += chunk.content().size();
        
        if (!output_file.good()) {
            error_message = "Error writing to file";
            output_file.close();
            return false;
        }
    }
    
    output_file.close();
    
    logger_.log(LogLevel::INFO_LEVEL, "FileTransfer", output_path,
               "Received " + std::to_string(total_bytes) + " bytes");
    
    return true;
}

bool FileProcessorServiceImpl::sendFile(
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream,
    const std::string& input_path,
    std::string& error_message) {
    
    std::ifstream input_file(input_path, std::ios::binary);
    if (!input_file) {
        error_message = "Failed to open file for sending: " + input_path;
        return false;
    }

    const size_t chunk_size = 64 * 1024; // 64KB chunks
    std::vector<char> buffer(chunk_size);
    size_t total_bytes = 0;
    
    while (input_file.read(buffer.data(), chunk_size) || input_file.gcount() > 0) {
        file_processor::FileChunk chunk;
        chunk.set_content(buffer.data(), input_file.gcount());
        
        if (!stream->Write(chunk)) {
            error_message = "Failed to send chunk";
            input_file.close();
            return false;
        }
        
        total_bytes += input_file.gcount();
    }
    
    input_file.close();
    
    logger_.log(LogLevel::INFO_LEVEL, "FileTransfer", input_path,
               "Sent " + std::to_string(total_bytes) + " bytes");
    
    return true;
}

grpc::Status FileProcessorServiceImpl::CompressPDF(
    grpc::ServerContext* context,
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream) {
    
    std::string service_name = "CompressPDF";
    logger_.log(LogLevel::INFO_LEVEL, service_name, "N/A", "Request received");
    
    // Gerar nomes de arquivos temporários
    std::string input_file = FileProcessorUtils::generateTempFileName(
        "input_pdf", ".pdf");
    std::string output_file = FileProcessorUtils::generateTempFileName(
        "output_pdf", ".pdf");
    
    // Receber arquivo do cliente
    std::string error_msg;
    if (!receiveFile(stream, input_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error_msg);
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    // Executar compressão com Ghostscript
    std::ostringstream command;
    command << "gs -sDEVICE=pdfwrite "
            << "-dCompatibilityLevel=1.4 "
            << "-dPDFSETTINGS=/ebook "
            << "-dNOPAUSE -dQUIET -dBATCH "
            << "-sOutputFile=\"" << output_file << "\" "
            << "\"" << input_file << "\"";
    
    logger_.log(LogLevel::INFO_LEVEL, service_name, input_file,
               "Executing: " + command.str());
    
    auto result = FileProcessorUtils::executeCommand(command.str());
    
    if (result.exit_code != 0) {
        std::string error = "Ghostscript failed with code " + 
                           std::to_string(result.exit_code) + 
                           ": " + result.output;
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    // Verificar se arquivo de saída foi criado
    if (!FileProcessorUtils::fileExists(output_file)) {
        std::string error = "Output file was not created";
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    // Calcular taxa de compressão
    size_t input_size = FileProcessorUtils::getFileSize(input_file);
    size_t output_size = FileProcessorUtils::getFileSize(output_file);
    double compression_ratio = 
        (1.0 - (double)output_size / input_size) * 100.0;
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, input_file,
               "Compressed from " + std::to_string(input_size) + 
               " to " + std::to_string(output_size) + 
               " bytes (" + std::to_string(compression_ratio) + "% reduction)");
    
    // Enviar arquivo comprimido de volta
    if (!sendFile(stream, output_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error_msg);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    // Limpar arquivos temporários
    FileProcessorUtils::cleanupFile(input_file);
    FileProcessorUtils::cleanupFile(output_file);
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, "N/A",
               "Request completed successfully");
    
    return grpc::Status::OK;
}

grpc::Status FileProcessorServiceImpl::ConvertToTXT(
    grpc::ServerContext* context,
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream) {
    
    std::string service_name = "ConvertToTXT";
    logger_.log(LogLevel::INFO_LEVEL, service_name, "N/A", "Request received");
    
    std::string input_file = FileProcessorUtils::generateTempFileName(
        "input_pdf", ".pdf");
    std::string output_file = FileProcessorUtils::generateTempFileName(
        "output_txt", ".txt");
    
    std::string error_msg;
    if (!receiveFile(stream, input_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error_msg);
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    // Executar conversão com pdftotext
    std::string command = "pdftotext \"" + input_file + "\" \"" + output_file + "\"";
    
    logger_.log(LogLevel::INFO_LEVEL, service_name, input_file,
               "Executing: " + command);
    
    auto result = FileProcessorUtils::executeCommand(command);
    
    if (result.exit_code != 0) {
        std::string error = "pdftotext failed with code " + 
                           std::to_string(result.exit_code) + 
                           ": " + result.output;
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    if (!FileProcessorUtils::fileExists(output_file)) {
        std::string error = "Output file was not created";
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    size_t output_size = FileProcessorUtils::getFileSize(output_file);
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, input_file,
               "Converted to TXT (" + std::to_string(output_size) + " bytes)");
    
    if (!sendFile(stream, output_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error_msg);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    FileProcessorUtils::cleanupFile(input_file);
    FileProcessorUtils::cleanupFile(output_file);
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, "N/A",
               "Request completed successfully");
    
    return grpc::Status::OK;
}

grpc::Status FileProcessorServiceImpl::ConvertImageFormat(
    grpc::ServerContext* context,
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream) {
    
    std::string service_name = "ConvertImageFormat";
    logger_.log(LogLevel::INFO_LEVEL, service_name, "N/A", "Request received");
    
    // Para este exemplo, vamos converter para PNG por padrão
    std::string input_file = FileProcessorUtils::generateTempFileName(
        "input_img", ".tmp");
    std::string output_file = FileProcessorUtils::generateTempFileName(
        "output_img", ".png");
    
    std::string error_msg;
    if (!receiveFile(stream, input_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error_msg);
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    // Executar conversão com ImageMagick
    // No Windows, usar "magick convert" ao invés de apenas "convert"
#ifdef _WIN32
    std::string command = "magick convert \"" + input_file + "\" \"" + output_file + "\"";
#else
    std::string command = "convert \"" + input_file + "\" \"" + output_file + "\"";
#endif
    
    logger_.log(LogLevel::INFO_LEVEL, service_name, input_file,
               "Executing: " + command);
    
    auto result = FileProcessorUtils::executeCommand(command);
    
    if (result.exit_code != 0) {
        std::string error = "ImageMagick convert failed with code " + 
                           std::to_string(result.exit_code) + 
                           ": " + result.output;
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    if (!FileProcessorUtils::fileExists(output_file)) {
        std::string error = "Output file was not created";
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    size_t output_size = FileProcessorUtils::getFileSize(output_file);
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, input_file,
               "Converted to PNG (" + std::to_string(output_size) + " bytes)");
    
    if (!sendFile(stream, output_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error_msg);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    FileProcessorUtils::cleanupFile(input_file);
    FileProcessorUtils::cleanupFile(output_file);
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, "N/A",
               "Request completed successfully");
    
    return grpc::Status::OK;
}

grpc::Status FileProcessorServiceImpl::ResizeImage(
    grpc::ServerContext* context,
    grpc::ServerReaderWriter<file_processor::FileChunk,
                            file_processor::FileChunk>* stream) {
    
    std::string service_name = "ResizeImage";
    logger_.log(LogLevel::INFO_LEVEL, service_name, "N/A", "Request received");
    
    // Para este exemplo, vamos redimensionar para 800x600
    int width = 800;
    int height = 600;
    
    std::string input_file = FileProcessorUtils::generateTempFileName(
        "input_img", ".tmp");
    std::string output_file = FileProcessorUtils::generateTempFileName(
        "output_img", ".jpg");
    
    std::string error_msg;
    if (!receiveFile(stream, input_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error_msg);
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    // Executar redimensionamento com ImageMagick
    // No Windows, usar "magick convert" ao invés de apenas "convert"
    std::ostringstream command;
#ifdef _WIN32
    command << "magick convert \"" << input_file << "\" "
            << "-resize " << width << "x" << height << "! "
            << "\"" << output_file << "\"";
#else
    command << "convert \"" << input_file << "\" "
            << "-resize " << width << "x" << height << "! "
            << "\"" << output_file << "\"";
#endif
    
    logger_.log(LogLevel::INFO_LEVEL, service_name, input_file,
               "Executing: " + command.str());
    
    auto result = FileProcessorUtils::executeCommand(command.str());
    
    if (result.exit_code != 0) {
        std::string error = "ImageMagick resize failed with code " + 
                           std::to_string(result.exit_code) + 
                           ": " + result.output;
        logger_.log(LogLevel::ERROR_LEVEL, service_name, input_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    if (!FileProcessorUtils::fileExists(output_file)) {
        std::string error = "Output file was not created";
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error);
        
        FileProcessorUtils::cleanupFile(input_file);
        return grpc::Status(grpc::StatusCode::INTERNAL, error);
    }
    
    size_t input_size = FileProcessorUtils::getFileSize(input_file);
    size_t output_size = FileProcessorUtils::getFileSize(output_file);
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, input_file,
               "Resized from " + std::to_string(input_size) + 
               " to " + std::to_string(output_size) + 
               " bytes (" + std::to_string(width) + "x" + 
               std::to_string(height) + ")");
    
    if (!sendFile(stream, output_file, error_msg)) {
        logger_.log(LogLevel::ERROR_LEVEL, service_name, output_file, error_msg);
        
        FileProcessorUtils::cleanupFile(input_file);
        FileProcessorUtils::cleanupFile(output_file);
        
        return grpc::Status(grpc::StatusCode::INTERNAL, error_msg);
    }
    
    FileProcessorUtils::cleanupFile(input_file);
    FileProcessorUtils::cleanupFile(output_file);
    
    logger_.log(LogLevel::SUCCESS_LEVEL, service_name, "N/A",
               "Request completed successfully");
    
    return grpc::Status::OK;
}
