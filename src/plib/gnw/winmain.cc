#include "plib/gnw/winmain.h"

#include <stdlib.h>
#include <string.h>
#include <string>
#include <unistd.h>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "game/main.h"
#include "game/rme_log.h"
#include "plib/gnw/gnw.h"
#include "plib/gnw/svga.h"

#if __APPLE__ && TARGET_OS_IOS
#include "platform/ios/paths.h"
#endif

namespace fallout {

// 0x53A290
bool GNW95_isActive = false;

// 0x6B0760
char GNW95_title[256];

int main(int argc, char* argv[])
{
    int rc;

    rme_log_init_from_env();

#if __APPLE__ && TARGET_OS_IOS
    // Use dedicated touch gesture handling; avoid synthetic touch->mouse events
    SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    chdir(iOSGetDocumentsPath());
#endif

#if __APPLE__ && TARGET_OS_OSX
    const char* basePath = SDL_GetBasePath();
    if (rme_log_topic_enabled("config")) {
        rme_logf("config", "SDL base path=%s", basePath != NULL ? basePath : "(null)");
    }
    if (basePath != NULL) {
        std::string workingDir(basePath);

        auto hasGameFiles = [](const std::string& dir) {
            std::string cfg = dir + "fallout.cfg";
            std::string master = dir + "master.dat";
            std::string critter = dir + "critter.dat";
            return access(cfg.c_str(), R_OK) == 0
                || (access(master.c_str(), R_OK) == 0 && access(critter.c_str(), R_OK) == 0);
        };

        const char resourcesMarker[] = "/Contents/Resources/";
        const char macosMarker[] = "/Contents/MacOS/";
        const char* resources = strstr(basePath, resourcesMarker);
        const char* macos = strstr(basePath, macosMarker);

        if (resources != NULL || macos != NULL) {
            std::string appRoot;

            if (resources != NULL) {
                appRoot.assign(basePath, resources - basePath);
            } else {
                appRoot.assign(basePath, macos - basePath);
            }

            std::string macosPath = appRoot + "/Contents/MacOS/";
            std::string resourcesPath = appRoot + "/Contents/Resources/";

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
                rme_logf("config",
                    "bundle probe appRoot=%s info_plist=%d macos_dir=%d resources_dir=%d",
                    appRoot.c_str(),
                    info_plist ? 1 : 0,
                    macos_dir ? 1 : 0,
                    resources_dir ? 1 : 0);
            }
        }

        chdir(workingDir.c_str());
        if (rme_log_topic_enabled("config")) {
            rme_logf("config", "working directory selected=%s", workingDir.c_str());
        }
        // SDL3 returns const char* but it's still allocated memory that needs freeing
        SDL_free((void*)basePath);
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
