// Patch logging helpers for diagnostics.
#ifndef FALLOUT_PLIB_DB_PATCHLOG_H_
#define FALLOUT_PLIB_DB_PATCHLOG_H_

namespace fallout {

// Patch logging controls:
//   F1R_PATCHLOG=1            enable logging
//   F1R_PATCHLOG_VERBOSE=1    include successful opens
//   F1R_PATCHLOG_PATH=/path   override log file location

bool patchlog_enabled();
bool patchlog_verbose();

void patchlog_write(const char* category, const char* format, ...);
void patchlog_context(const char* patches_path, const char* datafile_path);

} // namespace fallout

#endif // FALLOUT_PLIB_DB_PATCHLOG_H_