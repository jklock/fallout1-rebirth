// Patch logging helpers for diagnostics.
#ifndef FALLOUT_PLIB_DB_PATCHLOG_H_
#define FALLOUT_PLIB_DB_PATCHLOG_H_

namespace fallout {

// Patch logging controls:
//   F1R_PATCHLOG=1            enable logging
//   F1R_PATCHLOG_VERBOSE=1    include successful opens
//   F1R_PATCHLOG_PATH=/path   override log file location
// F1R AUDIT NOTE:
// Patch logging is an explicit validation surface for RME/community auditing.
// Release builds can compile these hooks out via F1R_DISABLE_RME_LOGGING.

#ifdef F1R_DISABLE_RME_LOGGING
// Community audit note: release builds can disable diagnostic patch logging
// without touching DB callsites that are useful during patch validation.

#define patchlog_enabled() (false)
#define patchlog_verbose() (false)
#define patchlog_write(...) ((void)0)
#define patchlog_context(...) ((void)0)

#else

bool patchlog_enabled();
bool patchlog_verbose();

void patchlog_write(const char* category, const char* format, ...);
void patchlog_context(const char* patches_path, const char* datafile_path);

#endif // F1R_DISABLE_RME_LOGGING

} // namespace fallout

#endif // FALLOUT_PLIB_DB_PATCHLOG_H_
