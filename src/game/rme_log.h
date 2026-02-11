#ifndef FALLOUT_GAME_RME_LOG_H_
#define FALLOUT_GAME_RME_LOG_H_

#include <string>

#include "game/config.h"

namespace fallout {

// Initialize logging from environment variable before config is available.
void rme_log_init_from_env();

// Merge config-provided toggle into logging state (debug/rme_log).
void rme_log_sync_config(const Config* config);

// Returns true when any RME logging is enabled.
bool rme_log_enabled();

// Returns true when logging is enabled for the given topic (for example: db, map, script).
bool rme_log_topic_enabled(const char* topic);

// Emit a formatted log line if the topic is enabled.
void rme_logf(const char* topic, const char* format, ...);

// Emit a formatted log line only once for the provided key.
void rme_log_once(const std::string& key, const char* topic, const char* format, ...);

} // namespace fallout

#endif /* FALLOUT_GAME_RME_LOG_H_ */
