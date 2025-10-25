#ifndef FILE_PROCESSOR_UTILS_H
#define FILE_PROCESSOR_UTILS_H

#include <string>
#include <memory>
#include <vector>
#include <array>
#include <cstdio>
#include <stdexcept>
#include <algorithm>
#include <chrono>
#include <cstdlib>

#ifdef _WIN32
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#define popen _popen
#define pclose _pclose
#define stat _stat
#define S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#else
#include <sys/stat.h>
#include <unistd.h>
#endif

class FileProcessorUtils {
public:
    struct CommandResult {
        int exit_code;
        std::string output;
        std::string error;
    };

    // Executar comando do sistema e capturar saída
    static CommandResult executeCommand(const std::string& command) {
        CommandResult result;
        std::array<char, 128> buffer;
        std::string output;
        
        // Adicionar 2>&1 para capturar stderr também
        std::string full_command = command + " 2>&1";
        
        std::unique_ptr<FILE, decltype(&pclose)> pipe(
            popen(full_command.c_str(), "r"), pclose);
        
        if (!pipe) {
            result.exit_code = -1;
            result.error = "Failed to execute command";
            return result;
        }
        
        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            output += buffer.data();
        }
        
#ifdef _WIN32
        result.exit_code = _pclose(pipe.release());
#else
        result.exit_code = pclose(pipe.release()) / 256;
#endif
        result.output = output;
        
        return result;
    }

    // Gerar nome único para arquivo temporário
    static std::string generateTempFileName(const std::string& prefix,
                                           const std::string& extension) {
        auto now = std::chrono::system_clock::now();
        auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()).count();
        
#ifdef _WIN32
        std::string temp_dir = getenv("TEMP") ? getenv("TEMP") : "C:\\Temp";
        return temp_dir + "\\" + prefix + "_" + std::to_string(timestamp) 
               + "_" + std::to_string(rand()) + extension;
#else
        return "/tmp/" + prefix + "_" + std::to_string(timestamp) 
               + "_" + std::to_string(rand()) + extension;
#endif
    }

    // Verificar se arquivo existe
    static bool fileExists(const std::string& path) {
        struct stat buffer;
        return (stat(path.c_str(), &buffer) == 0 && S_ISREG(buffer.st_mode));
    }

    // Obter tamanho do arquivo
    static size_t getFileSize(const std::string& path) {
        if (!fileExists(path)) {
            return 0;
        }
        struct stat buffer;
        if (stat(path.c_str(), &buffer) == 0) {
            return buffer.st_size;
        }
        return 0;
    }

    // Limpar arquivo temporário com segurança
    static bool cleanupFile(const std::string& path) {
        try {
            if (fileExists(path)) {
#ifdef _WIN32
                return (_unlink(path.c_str()) == 0);
#else
                return (unlink(path.c_str()) == 0);
#endif
            }
            return true;
        } catch (const std::exception& e) {
            return false;
        }
    }

    // Extrair extensão do arquivo
    static std::string getFileExtension(const std::string& filename) {
        size_t dot_pos = filename.find_last_of('.');
        if (dot_pos != std::string::npos) {
            return filename.substr(dot_pos);
        }
        return "";
    }

    // Validar formato de imagem
    static bool isValidImageFormat(const std::string& format) {
        static const std::vector<std::string> valid_formats = {
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"
        };
        
        std::string lower_format = format;
        std::transform(lower_format.begin(), lower_format.end(),
                      lower_format.begin(), ::tolower);
        
        return std::find(valid_formats.begin(), valid_formats.end(),
                        lower_format) != valid_formats.end();
    }

    // Validar dimensões de imagem
    static bool isValidDimension(int width, int height) {
        return width > 0 && height > 0 && 
               width <= 10000 && height <= 10000;
    }
};

#endif // FILE_PROCESSOR_UTILS_H
