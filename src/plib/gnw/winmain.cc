#include "plib/gnw/winmain.h"

#include <stdlib.h>
#include <string.h>
#include <string>
#include <unistd.h>

#include <limits.h>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "game/main.h"
#include "plib/gnw/gnw.h"
#include "plib/gnw/svga.h"
#include "plib/db/patchlog.h"

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

#if __APPLE__ && TARGET_OS_OSX
    auto resolve_base_path = [argv]() -> std::string {
        std::string sdlBasePath;
        const char* sdlBase = SDL_GetBasePath();
        if (sdlBase != NULL) {
            sdlBasePath.assign(sdlBase);
            SDL_free((void*)sdlBase);
        }

        std::string argvBasePath;
        if (argv != nullptr && argv[0] != nullptr) {
            char resolved[PATH_MAX];
            if (realpath(argv[0], resolved) != NULL) {
                std::string path(resolved);
                size_t sep = path.find_last_of('/');
                if (sep != std::string::npos) {
                    argvBasePath = path.substr(0, sep + 1);
                }
            }
        }

        auto looks_like_bundle = [](const std::string& path) {
            return path.find("/Contents/MacOS/") != std::string::npos
                || path.find("/Contents/Resources/") != std::string::npos;
        };

        if (looks_like_bundle(sdlBasePath)) {
            return sdlBasePath;
        }

        if (looks_like_bundle(argvBasePath)) {
            return argvBasePath;
        }

        if (!sdlBasePath.empty()) {
            return sdlBasePath;
        }

        if (!argvBasePath.empty()) {
            return argvBasePath;
        }

        char cwd[PATH_MAX];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            std::string path(cwd);
            if (!path.empty() && path.back() != '/') {
                path.push_back('/');
            }
            return path;
        }

        return std::string();
    };
#endif

#if __APPLE__ && TARGET_OS_IOS
    // Use dedicated touch gesture handling; avoid synthetic touch->mouse events
    SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    chdir(iOSGetDocumentsPath());
#endif

#if __APPLE__ && TARGET_OS_OSX
    std::string basePath = resolve_base_path();
    if (!basePath.empty()) {
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
        const char* resources = strstr(basePath.c_str(), resourcesMarker);
        const char* macos = strstr(basePath.c_str(), macosMarker);

        if (resources != NULL || macos != NULL) {
            std::string appRoot;

            if (resources != NULL) {
                appRoot.assign(basePath.c_str(), resources - basePath.c_str());
            } else {
                appRoot.assign(basePath.c_str(), macos - basePath.c_str());
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
        }

        if (patchlog_enabled()) {
            patchlog_write("BOOT_PATH", "base=\"%s\" working=\"%s\"",
                basePath.c_str(),
                workingDir.c_str());
        }

        chdir(workingDir.c_str());
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
