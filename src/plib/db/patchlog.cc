#include "plib/db/patchlog.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "platform_compat.h"

namespace fallout {

static FILE* patchlog_file = NULL;
static bool patchlog_checked = false;
static bool patchlog_is_enabled = false;
static bool patchlog_is_verbose = false;
static bool patchlog_context_written = false;
static char patchlog_last_patches[COMPAT_MAX_PATH] = "";
static char patchlog_last_datafile[COMPAT_MAX_PATH] = "";

static bool patchlog_env_enabled()
{
    const char* env = getenv("F1R_PATCHLOG");
    if (env == NULL) {
        return false;
    }
    if (env[0] == '0' || env[0] == '\0') {
        return false;
    }
    return true;
}

static bool patchlog_env_verbose()
{
    const char* env = getenv("F1R_PATCHLOG_VERBOSE");
    if (env == NULL) {
        return false;
    }
    if (env[0] == '0' || env[0] == '\0') {
        return false;
    }
    return true;
}

static const char* patchlog_env_path()
{
    const char* env = getenv("F1R_PATCHLOG_PATH");
    if (env == NULL || env[0] == '\0') {
        return "patchlog.txt";
    }
    return env;
}

static void patchlog_init()
{
    if (patchlog_checked) {
        return;
    }

    patchlog_checked = true;
    patchlog_is_enabled = patchlog_env_enabled();
    patchlog_is_verbose = patchlog_env_verbose();

    if (!patchlog_is_enabled) {
        return;
    }

    const char* path = patchlog_env_path();
    patchlog_file = compat_fopen(path, "a");
    if (patchlog_file == NULL) {
        patchlog_is_enabled = false;
        patchlog_is_verbose = false;
    }
}

bool patchlog_enabled()
{
    patchlog_init();
    return patchlog_is_enabled;
}

bool patchlog_verbose()
{
    patchlog_init();
    return patchlog_is_verbose;
}

static void patchlog_write_prefix(const char* category)
{
    if (patchlog_file == NULL) {
        return;
    }

    time_t now = time(NULL);
    struct tm tm_info;
#if defined(_WIN32)
    localtime_s(&tm_info, &now);
#else
    localtime_r(&now, &tm_info);
#endif

    char ts[32];
    strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", &tm_info);
    fprintf(patchlog_file, "[%s] [%s] ", ts, category);
}

void patchlog_write(const char* category, const char* format, ...)
{
    patchlog_init();
    if (!patchlog_is_enabled || patchlog_file == NULL) {
        return;
    }

    patchlog_write_prefix(category);

    va_list args;
    va_start(args, format);
    vfprintf(patchlog_file, format, args);
    va_end(args);

    fprintf(patchlog_file, "\n");
    fflush(patchlog_file);
}

void patchlog_context(const char* patches_path, const char* datafile_path)
{
    patchlog_init();
    if (!patchlog_is_enabled) {
        return;
    }

    const char* patches = patches_path != NULL ? patches_path : "(null)";
    const char* datafile = datafile_path != NULL ? datafile_path : "(null)";

    if (patchlog_context_written
        && strcmp(patchlog_last_patches, patches) == 0
        && strcmp(patchlog_last_datafile, datafile) == 0) {
        return;
    }

    patchlog_context_written = true;
    strncpy(patchlog_last_patches, patches, sizeof(patchlog_last_patches) - 1);
    patchlog_last_patches[sizeof(patchlog_last_patches) - 1] = '\0';
    strncpy(patchlog_last_datafile, datafile, sizeof(patchlog_last_datafile) - 1);
    patchlog_last_datafile[sizeof(patchlog_last_datafile) - 1] = '\0';

    patchlog_write("DB_CONTEXT", "patches_path=\"%s\" datafile_path=\"%s\"", patches, datafile);
}

} // namespace fallout
