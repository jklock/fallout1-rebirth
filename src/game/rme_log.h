#ifndef FALLOUT_GAME_RME_LOG_H_
#define FALLOUT_GAME_RME_LOG_H_

#ifdef __cplusplus
extern "C" {
#endif

void rme_log_init_from_env(void);
int rme_log_topic_enabled(const char* topic);
void rme_logf(const char* topic, const char* fmt, ...);

#ifdef __cplusplus
}
#endif

#endif // FALLOUT_GAME_RME_LOG_H_
