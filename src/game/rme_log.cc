#include "game/rme_log.h"

#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <mutex>
#include <string>

static FILE* rme_log_fp = nullptr;
static std::string rme_log_env;
static std::mutex rme_log_mutex;
static bool rme_log_initialized = false;

static void rme_format_time(char* buf, size_t bufsize)
{
    std::time_t t = std::time(nullptr);
    std::tm tm;
#if defined(_WIN32)
    gmtime_s(&tm, &t);
#else
    gmtime_r(&t, &tm);
#endif
    std::snprintf(buf, bufsize, "%04d-%02d-%02dT%02d:%02d:%02dZ",
        tm.tm_year + 1900,
        tm.tm_mon + 1,
        tm.tm_mday,
        tm.tm_hour,
        tm.tm_min,
        tm.tm_sec);
}

extern "C" {

void rme_log_init_from_env(void)
{
    std::lock_guard<std::mutex> lock(rme_log_mutex);
    if (rme_log_initialized) {
        return;
    }

    const char* env = std::getenv("RME_LOG");
    if (env == nullptr || env[0] == '\0') {
        rme_log_initialized = true;
        return;
    }

    rme_log_env = std::string(env);

    const char* file = std::getenv("RME_LOG_FILE");
    if (file == nullptr || file[0] == '\0') {
        file = "rme.log";
    }

    // Open for write to create a fresh log for each run
    rme_log_fp = std::fopen(file, "w");
    if (rme_log_fp != nullptr) {
        // line buffering
        setvbuf(rme_log_fp, nullptr, _IOLBF, 1024);
    }

    rme_log_initialized = true;
}

int rme_log_topic_enabled(const char* topic)
{
    if (!rme_log_initialized) {
        rme_log_init_from_env();
    }

    if (rme_log_fp == nullptr) {
        return 0;
    }

    if (rme_log_env == "all") {
        return 1;
    }

    // Simple substring match for comma-separated list
    const std::string needle(topic);
    size_t pos = 0;
    while (pos < rme_log_env.size()) {
        size_t comma = rme_log_env.find(',', pos);
        if (comma == std::string::npos) comma = rme_log_env.size();
        std::string token = rme_log_env.substr(pos, comma - pos);
        // trim
        size_t start = token.find_first_not_of(" \t\n\r");
        size_t end = token.find_last_not_of(" \t\n\r");
        if (start != std::string::npos && end != std::string::npos) {
            token = token.substr(start, end - start + 1);
            if (token == needle) return 1;
        }
        pos = comma + 1;
    }

    return 0;
}

void rme_logf(const char* topic, const char* fmt, ...)
{
    if (!rme_log_initialized) {
        rme_log_init_from_env();
    }

    if (rme_log_fp == nullptr) {
        return;
    }

    if (!rme_log_topic_enabled(topic)) {
        return;
    }

    char timebuf[32];
    rme_format_time(timebuf, sizeof(timebuf));

    char msgbuf[1024];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(msgbuf, sizeof(msgbuf), fmt, ap);
    va_end(ap);

    std::lock_guard<std::mutex> lock(rme_log_mutex);
    if (rme_log_fp) {
        std::fprintf(rme_log_fp, "%s %s %s\n", timebuf, topic, msgbuf);
        std::fflush(rme_log_fp);
    }
}

} // extern "C"
