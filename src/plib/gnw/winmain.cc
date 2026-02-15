#include "plib/gnw/winmain.h"

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <string>
#include <unistd.h>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "game/main.h"
#include "game/rme_log.h"
// Forward declarations as a safety for build systems/compilers that may not
// pick up the header for early boot translation units.
#ifdef __cplusplus
extern "C" {
#endif
void rme_log_init_from_env(void);
int rme_log_topic_enabled(const char* topic);
void rme_logf(const char* topic, const char* fmt, ...);
#ifdef __cplusplus
}
#endif

#include "plib/gnw/gnw.h"
#include "plib/gnw/svga.h"

#if __APPLE__ && TARGET_OS_IOS
#include "platform/ios/paths.h"
#endif
#if __APPLE__ && TARGET_OS_OSX
#include <mach-o/dyld.h>
#endif

namespace fallout {

// F1R AUDIT NOTE:
// Added startup working-directory override and bundle probe diagnostics so
// patched external data roots can be validated deterministically on macOS/iOS.

// 0x53A290
bool GNW95_isActive = false;

// 0x6B0760
char GNW95_title[256];

int main(int argc, char* argv[])
{
    int rc;

    rme_log_init_from_env();

    // RME_WORKING_DIR env override: chdir to this directory before any bundle or DB probes.
    const char* rme_working_dir = getenv("RME_WORKING_DIR");
    if (rme_working_dir != NULL && rme_working_dir[0] != '\0') {
        if (rme_log_topic_enabled("config")) {
            rme_logf("config", "working directory override=%s", rme_working_dir);
        }
        if (chdir(rme_working_dir) != 0) {
            rme_logf("config", "working directory override failed chdir=%s errno=%d", rme_working_dir, errno);
        }

        // Optional lightweight verify mode: if RME_WORKING_DIR_VERIFY is set, report presence of key files and exit early.
        if (getenv("RME_WORKING_DIR_VERIFY")) {
            bool master_present = access("master.dat", R_OK) == 0;
            bool critter_present = access("critter.dat", R_OK) == 0;
            char cwd_buf[PATH_MAX];
            if (getcwd(cwd_buf, sizeof(cwd_buf)) == NULL) {
                cwd_buf[0] = '\0';
            }
            rme_logf("config", "working_dir_verify cwd=%s master.dat=%d critter.dat=%d", cwd_buf, master_present ? 1 : 0, critter_present ? 1 : 0);
            // Write JSON to cwd so test harness can find it.
            FILE* f = fopen("rme-working-dir-verify.json", "w");
            if (f != NULL) {
                fprintf(f, "{\"override\":\"%s\",\"cwd\":\"%s\",\"master.dat\":%d,\"critter.dat\":%d}\n", rme_working_dir, cwd_buf, master_present ? 1 : 0, critter_present ? 1 : 0);
                fclose(f);
            }
            exit(master_present && critter_present ? 0 : 1);
        }
    }
#if __APPLE__ && TARGET_OS_IOS
    // Use dedicated touch gesture handling; avoid synthetic touch->mouse events
    SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    const char* documentsPath = iOSGetDocumentsPath();
    if (documentsPath != NULL) {
        chdir(documentsPath);
    }

    struct stat dataStat;
    const bool masterPresent = access("master.dat", R_OK) == 0;
    const bool critterPresent = access("critter.dat", R_OK) == 0;
    const bool dataDirPresent = stat("data", &dataStat) == 0 && S_ISDIR(dataStat.st_mode);

    if (!(masterPresent && critterPresent && dataDirPresent)) {
        if (rme_log_topic_enabled("config")) {
            rme_logf("config",
                "ios preflight missing data cwd=%s master.dat=%d critter.dat=%d data_dir=%d",
                documentsPath != NULL ? documentsPath : "(null)",
                masterPresent ? 1 : 0,
                critterPresent ? 1 : 0,
                dataDirPresent ? 1 : 0);
        }

        SDL_ShowSimpleMessageBox(
            SDL_MESSAGEBOX_ERROR,
            "Missing Game Files",
            "Could not find the master datafile. Install master.dat, critter.dat, and the data folder in Files > Fallout 1 Rebirth > Documents.",
            NULL);
        // On iOS, returning from SDL_main can keep the UIKit shell alive.
        // Terminate explicitly once the user dismisses the preflight error.
        exit(EXIT_FAILURE);
    }
#endif

#if __APPLE__ && TARGET_OS_OSX
    if (getenv("RME_WORKING_DIR") != NULL) {
        if (rme_log_topic_enabled("config")) {
            rme_logf("config", "skipping macOS bundle probe due to RME_WORKING_DIR override");
        }
    } else {
        auto hasGameFiles = [](const std::string& dir) {
            std::string cfg = dir + "fallout.cfg";
            std::string master = dir + "master.dat";
            std::string critter = dir + "critter.dat";
            return access(cfg.c_str(), R_OK) == 0
                || (access(master.c_str(), R_OK) == 0 && access(critter.c_str(), R_OK) == 0);
        };

        bool keepCwd = false;
        char cwd[PATH_MAX];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            std::string cwdDir(cwd);
            if (!cwdDir.empty() && cwdDir.back() != '/') {
                cwdDir.push_back('/');
            }
            if (hasGameFiles(cwdDir)) {
                keepCwd = true;
            }
        }

        if (!keepCwd) {
            const char* basePath = SDL_GetBasePath();
            if (rme_log_topic_enabled("config")) {
                rme_logf("config", "SDL base path=%s", basePath != NULL ? basePath : "(null)");
            }
            std::string workingDir;
            std::string appRoot;
            std::string macosPath;
            std::string resourcesPath;
            bool haveAppRoot = false;

            auto withTrailingSlash = [](std::string path) {
                if (!path.empty() && path.back() != '/') {
                    path.push_back('/');
                }
                return path;
            };

            auto extractAppRoot = [&](const std::string& rawPath) -> bool {
                if (rawPath.empty()) {
                    return false;
                }

                const char* markers[] = {
                    "/Contents/MacOS/",
                    "/Contents/MacOS",
                    "/Contents/Resources/",
                    "/Contents/Resources",
                };

                size_t markerPos = std::string::npos;
                for (const char* marker : markers) {
                    size_t pos = rawPath.find(marker);
                    if (pos != std::string::npos) {
                        markerPos = pos;
                        break;
                    }
                }

                if (markerPos == std::string::npos) {
                    return false;
                }

                appRoot = rawPath.substr(0, markerPos);
                if (appRoot.empty()) {
                    return false;
                }

                macosPath = appRoot + "/Contents/MacOS/";
                resourcesPath = appRoot + "/Contents/Resources/";
                haveAppRoot = true;
                return true;
            };

            if (basePath != NULL) {
                workingDir = withTrailingSlash(basePath);
                extractAppRoot(workingDir);
            }

            // SDL base path can resolve to /Applications/ in some launch modes.
            // Fall back to the actual executable path to recover the app root.
            if (!haveAppRoot) {
                uint32_t exePathSize = PATH_MAX;
                char exePath[PATH_MAX];
                if (_NSGetExecutablePath(exePath, &exePathSize) == 0) {
                    char resolvedExePath[PATH_MAX];
                    const char* probe = exePath;
                    if (realpath(exePath, resolvedExePath) != NULL) {
                        probe = resolvedExePath;
                    }
                    extractAppRoot(probe);
                    if (rme_log_topic_enabled("config")) {
                        rme_logf("config", "bundle probe executable path=%s", probe);
                    }
                }
            }

            if (!haveAppRoot && argc > 0 && argv != NULL && argv[0] != NULL) {
                char resolvedArgvPath[PATH_MAX];
                const char* probe = argv[0];
                if (realpath(argv[0], resolvedArgvPath) != NULL) {
                    probe = resolvedArgvPath;
                }
                extractAppRoot(probe);
                if (rme_log_topic_enabled("config")) {
                    rme_logf("config", "bundle probe argv0 path=%s", probe);
                }
            }

            auto pathExists = [](const std::string& path) {
                return access(path.c_str(), R_OK) == 0;
            };

            auto findWithExtension = [](const std::string& dir, const char* ext) {
                DIR* d = opendir(dir.c_str());
                if (d == NULL) {
                    return std::string();
                }

                std::string found;
                struct dirent* ent;
                const size_t extLen = strlen(ext);
                while ((ent = readdir(d)) != NULL) {
                    if (ent->d_name[0] == '.') {
                        continue;
                    }

                    std::string name(ent->d_name);
                    if (name.size() >= extLen && name.rfind(ext) == name.size() - extLen) {
                        found = name;
                        break;
                    }
                }

                closedir(d);
                return found;
            };

            if (haveAppRoot) {
                std::string parentDir;
                size_t sep = appRoot.find_last_of('/');
                if (sep != std::string::npos) {
                    parentDir = appRoot.substr(0, sep + 1);
                }

                const std::string candidates[] = { macosPath, resourcesPath, parentDir };
                for (const auto& candidate : candidates) {
                    if (!candidate.empty() && hasGameFiles(candidate)) {
                        workingDir = candidate;
                        break;
                    }
                }

                if (!workingDir.empty() && !hasGameFiles(workingDir)) {
                    // Prefer app bundle Resources when present so fallout.cfg/f1_res.ini
                    // and game payload copied there are visible at startup.
                    if (pathExists(resourcesPath)) {
                        workingDir = resourcesPath;
                    }
                }

                if (rme_log_topic_enabled("config")) {
                    for (const auto& candidate : candidates) {
                        if (candidate.empty()) {
                            continue;
                        }

                        const bool cfg_present = access((candidate + "fallout.cfg").c_str(), R_OK) == 0;
                        const bool master_present = access((candidate + "master.dat").c_str(), R_OK) == 0;
                        const bool critter_present = access((candidate + "critter.dat").c_str(), R_OK) == 0;
                        const bool data_present = access((candidate + "data").c_str(), R_OK) == 0;

                        rme_logf("config",
                            "startup candidate=%s cfg=%d master.dat=%d critter.dat=%d data_dir=%d",
                            candidate.c_str(),
                            cfg_present ? 1 : 0,
                            master_present ? 1 : 0,
                            critter_present ? 1 : 0,
                            data_present ? 1 : 0);
                    }

                    const bool info_plist = access((appRoot + "/Contents/Info.plist").c_str(), R_OK) == 0;
                    const bool macos_dir = access(macosPath.c_str(), R_OK) == 0;
                    const bool resources_dir = access(resourcesPath.c_str(), R_OK) == 0;
                    const bool macos_data = pathExists(macosPath + "data");
                    const bool resources_data = pathExists(resourcesPath + "data");
                    std::string icns = findWithExtension(resourcesPath, ".icns");
                    std::string storyboard = findWithExtension(resourcesPath, ".storyboardc");
                    if (storyboard.empty()) {
                        storyboard = findWithExtension(resourcesPath, ".storyboard");
                    }
                    rme_logf("config",
                        "bundle probe appRoot=%s info_plist=%d macos_dir=%d resources_dir=%d macos_data=%d resources_data=%d icns=%s storyboard=%s",
                        appRoot.c_str(),
                        info_plist ? 1 : 0,
                        macos_dir ? 1 : 0,
                        resources_dir ? 1 : 0,
                        macos_data ? 1 : 0,
                        resources_data ? 1 : 0,
                        icns.empty() ? "(none)" : icns.c_str(),
                        storyboard.empty() ? "(none)" : storyboard.c_str());
                }
            }

            if (!workingDir.empty()) {
                chdir(workingDir.c_str());
                if (rme_log_topic_enabled("config")) {
                    const bool chosen_has_data = access((workingDir + "data").c_str(), R_OK) == 0;
                    const bool macos_has_data = haveAppRoot ? access((macosPath + "data").c_str(), R_OK) == 0 : false;
                    const bool resources_has_data = haveAppRoot ? access((resourcesPath + "data").c_str(), R_OK) == 0 : false;
                    if (!chosen_has_data && (macos_has_data || resources_has_data)) {
                        rme_logf("config",
                            "bundle warning data missing in chosen dir=%s macos_has_data=%d resources_has_data=%d",
                            workingDir.c_str(),
                            macos_has_data ? 1 : 0,
                            resources_has_data ? 1 : 0);
                    }
                }
            }
            // SDL3 returns a cached `const char*` here; do NOT free it —
            // SDL_filesystem maintains an internal cache and will free it at
            // SDL_QuitFilesystem(). Freeing it here would lead to a double-free.
            /* intentionally not freeing `basePath` */
        }
    }
#endif

    SDL_HideCursor();

    GNW95_isActive = true;
    rc = gnw_main(argc, argv);

    return rc;
}

} // namespace fallout

int main(int argc, char* argv[])
{
    return fallout::main(argc, argv);
}
