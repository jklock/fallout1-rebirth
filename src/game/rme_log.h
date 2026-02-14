#ifndef FALLOUT_GAME_RME_LOG_H_
#define FALLOUT_GAME_RME_LOG_H_

#ifdef F1R_DISABLE_RME_LOGGING
// F1R AUDIT NOTE:
// Allow release builds to compile out Rebirth-specific diagnostics while
// keeping callsites intact for developer/debug builds.

#ifdef __cplusplus
extern "C" {
#endif

#define rme_log_init_from_env() ((void)0)
#define rme_log_topic_enabled(topic) (0)
#define rme_logf(...) ((void)0)

#ifdef __cplusplus
}
// C++ helpers
#include "game/config.h"
#include <string>
namespace fallout {
inline void rme_log_once(const std::string&, const char*, const char*, ...)
{
}
inline void rme_log_sync_config(const Config*)
{
}
} // namespace fallout
#endif

#else

#ifdef __cplusplus
extern "C" {
#endif

void rme_log_init_from_env(void);
int rme_log_topic_enabled(const char* topic);
void rme_logf(const char* topic, const char* fmt, ...);

#ifdef __cplusplus
}
// C++ helpers
#include "game/config.h"
#include <string>
namespace fallout {
void rme_log_once(const std::string& key, const char* topic, const char* fmt, ...);
void rme_log_sync_config(const Config* cfg);
} // namespace fallout
#endif

#endif // F1R_DISABLE_RME_LOGGING

#endif // FALLOUT_GAME_RME_LOG_H_
