#ifndef LOGGER_H
#define LOGGER_H

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#endif

#include <string>
#include <fstream>
#include <mutex>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <iostream>

enum class LogLevel {
    INFO_LEVEL,
    SUCCESS_LEVEL,
    WARNING_LEVEL,
    ERROR_LEVEL
};

class Logger {
public:
    static Logger& getInstance() {
        static Logger instance;
        return instance;
    }

    void setLogFile(const std::string& filename) {
        std::lock_guard<std::mutex> lock(mutex_);
        log_file_path_ = filename;
    }

    void log(LogLevel level, const std::string& service_name,
             const std::string& file_name, const std::string& message) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        std::string timestamp = getCurrentTimestamp();
        std::string level_str = getLevelString(level);
        
        std::ostringstream log_entry;
        log_entry << "[" << timestamp << "] "
                  << "[" << level_str << "] "
                  << "Service: " << service_name << " | "
                  << "File: " << file_name << " | "
                  << "Message: " << message;
        
        // Log para arquivo
        std::ofstream log_file(log_file_path_, std::ios::app);
        if (log_file.is_open()) {
            log_file << log_entry.str() << std::endl;
            log_file.close();
        }
        
        // Log para console com cores
        std::cout << getColorCode(level) << log_entry.str() 
                  << "\033[0m" << std::endl;
    }

private:
    Logger() : log_file_path_("server.log") {}
    ~Logger() = default;
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    std::string getCurrentTimestamp() {
        auto now = std::chrono::system_clock::now();
        auto time_t_now = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()) % 1000;
        
        std::tm tm_now;
#ifdef _WIN32
        localtime_s(&tm_now, &time_t_now);
#else
        localtime_r(&time_t_now, &tm_now);
#endif
        
        std::ostringstream oss;
        oss << std::put_time(&tm_now, "%Y-%m-%d %H:%M:%S")
            << '.' << std::setfill('0') << std::setw(3) << ms.count();
        return oss.str();
    }

    std::string getLevelString(LogLevel level) {
        switch (level) {
            case LogLevel::INFO_LEVEL: return "INFO";
            case LogLevel::SUCCESS_LEVEL: return "SUCCESS";
            case LogLevel::WARNING_LEVEL: return "WARNING";
            case LogLevel::ERROR_LEVEL: return "ERROR";
            default: return "UNKNOWN";
        }
    }

    std::string getColorCode(LogLevel level) {
        switch (level) {
            case LogLevel::INFO_LEVEL: return "\033[36m";      // Cyan
            case LogLevel::SUCCESS_LEVEL: return "\033[32m";   // Green
            case LogLevel::WARNING_LEVEL: return "\033[33m";   // Yellow
            case LogLevel::ERROR_LEVEL: return "\033[31m";     // Red
            default: return "\033[0m";                   // Reset
        }
    }

    std::string log_file_path_;
    std::mutex mutex_;
};

#endif // LOGGER_H
