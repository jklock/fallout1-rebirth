#include "game/rme_log.h"

#include "game/gconfig.h"

#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <ctime>
#include <set>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

#include "platform_compat.h"

namespace fallout {

namespace {

    constexpr size_t kMaxLogSize = 1024 * 1024; // 1 MiB
    constexpr const char* kLogFileName = "rme.log";
    constexpr const char* kLogBackupName = "rme.log.1";

    bool g_enabled = false;
    bool g_has_filters = false;
    std::set<std::string> g_filters;
    std::set<std::string> g_once_keys;
    FILE* g_log_file = nullptr;
    std::string g_source;

    std::string toLower(const std::string& value)
    {
        std::string lowered(value);
        std::transform(lowered.begin(), lowered.end(), lowered.begin(), [](unsigned char ch) { return static_cast<char>(tolower(ch)); });
        return lowered;
    }

    std::vector<std::string> splitTopics(const std::string& value)
    {
        std::vector<std::string> topics;

        std::string current;
        for (char ch : value) {
            if (ch == ',') {
                if (!current.empty()) {
                    topics.push_back(toLower(current));
                    current.clear();
                }
            } else if (!isspace(static_cast<unsigned char>(ch))) {
                current.push_back(ch);
            }
        }

        if (!current.empty()) {
            topics.push_back(toLower(current));
        }

        return topics;
    }

    bool isEnabledValue(const std::string& value)
    {
        const std::string lowered = toLower(value);
        return lowered == "1" || lowered == "true" || lowered == "yes" || lowered == "on" || lowered == "all" || lowered == "*";
    }

    void rotateIfNeeded()
    {
        struct stat st {};
        if (g_log_file != nullptr) {
            if (fstat(fileno(g_log_file), &st) == 0 && static_cast<size_t>(st.st_size) >= kMaxLogSize) {
                fclose(g_log_file);
                g_log_file = nullptr;
            }
        }

        if (g_log_file == nullptr) {
            if (stat(kLogFileName, &st) == 0 && static_cast<size_t>(st.st_size) >= kMaxLogSize) {
                unlink(kLogBackupName);
                rename(kLogFileName, kLogBackupName);
            }
        }
    }

    void ensureLogFile()
    {
        if (!g_enabled) {
            return;
        }

        rotateIfNeeded();

        if (g_log_file == nullptr) {
            g_log_file = compat_fopen(kLogFileName, "a");
        }
    }

    void emit(const char* topic, const char* message, bool force)
    {
        if (!force && !g_enabled) {
            return;
        }

        const std::time_t now = std::time(nullptr);
        std::tm time_info {};
        localtime_r(&now, &time_info);

        char timestamp[32];
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", &time_info);

        if (topic == nullptr) {
            topic = "general";
        }

        char line[2048];
        std::snprintf(line, sizeof(line), "[RME %s] %s: %s\n", timestamp, topic, message);

        // stderr output for immediate visibility
        fputs(line, stderr);
        fflush(stderr);

        ensureLogFile();
        if (g_log_file != nullptr) {
            fputs(line, g_log_file);
            fflush(g_log_file);
        }
    }

    void applyTopics(const std::string& raw)
    {
        if (raw.empty()) {
            return;
        }

        const bool enable_all = isEnabledValue(raw);
        const std::vector<std::string> topics = splitTopics(raw);

        if (!enable_all && topics.empty()) {
            return;
        }

        g_enabled = true;
        g_source = raw;
        g_has_filters = false;
        g_filters.clear();

        if (!enable_all && !topics.empty()) {
            g_has_filters = true;
            g_filters.insert(topics.begin(), topics.end());
        }

        char summary[256];
        std::snprintf(summary, sizeof(summary), "logging enabled via %s topics=%s", g_source.c_str(), g_has_filters ? "filtered" : "all");
        emit("config", summary, true);
    }

} // namespace

void rme_log_init_from_env()
{
    const char* env = getenv("RME_LOG");
    if (env == nullptr) {
        return;
    }

    applyTopics(env);
}

void rme_log_sync_config(const Config* config)
{
    if (config == nullptr) {
        return;
    }

    char* value = nullptr;
    if (!config_get_string(const_cast<Config*>(config), GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_RME_LOG_KEY, &value)) {
        return;
    }

    if (value != nullptr && value[0] != '\0') {
        applyTopics(value);
    }
}

bool rme_log_enabled()
{
    return g_enabled;
}

bool rme_log_topic_enabled(const char* topic)
{
    if (!g_enabled) {
        return false;
    }

    if (!g_has_filters || topic == nullptr) {
        return true;
    }

    return g_filters.find(toLower(topic)) != g_filters.end();
}

void rme_logf(const char* topic, const char* format, ...)
{
    if (!rme_log_topic_enabled(topic)) {
        return;
    }

    char buffer[1536];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    emit(topic, buffer, false);
}

void rme_log_once(const std::string& key, const char* topic, const char* format, ...)
{
    if (!rme_log_topic_enabled(topic)) {
        return;
    }

    if (!g_once_keys.insert(key).second) {
        return;
    }

    char buffer[1536];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    emit(topic, buffer, false);
}

} // namespace fallout
