#include "plib/gnw/winmain.h"

#include <algorithm>
#include <dirent.h>
#include <errno.h>
#include <iterator>
#include <limits.h>
#include <sstream>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <string>
#include <vector>
#include <unistd.h>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "game/gconfig.h"
#include "game/main.h"
#include "game/rme_log.h"
#include "plib/gnw/kb.h"
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

namespace {

struct ProbeKeySpec {
    const char* section;
    const char* key;
    const char* appliedSection;
    const char* appliedKey;
};

static const ProbeKeySpec kFalloutCfgProbeKeys[] = {
    { "debug", "mode", "debug", "mode" },
    { "debug", "output_map_data_info", "debug", "output_map_data_info" },
    { "debug", "show_load_info", "debug", "show_load_info" },
    { "debug", "show_script_messages", "debug", "show_script_messages" },
    { "debug", "show_tile_num", "debug", "show_tile_num" },
    { "input", "map_scroll_delay", "input", "map_scroll_delay" },
    { "input", "pencil_right_click", "input", "pencil_right_click" },
    { "preferences", "brightness", "preferences", "brightness" },
    { "preferences", "combat_difficulty", "preferences", "combat_difficulty" },
    { "preferences", "combat_messages", "preferences", "combat_messages" },
    { "preferences", "combat_speed", "preferences", "combat_speed" },
    { "preferences", "combat_taunts", "preferences", "combat_taunts" },
    { "preferences", "game_difficulty", "preferences", "game_difficulty" },
    { "preferences", "item_highlight", "preferences", "item_highlight" },
    { "preferences", "language_filter", "preferences", "language_filter" },
    { "preferences", "mouse_sensitivity", "preferences", "mouse_sensitivity" },
    { "preferences", "player_speed", "preferences", "player_speed" },
    { "preferences", "player_speedup", "preferences", "player_speedup" },
    { "preferences", "running", "preferences", "running" },
    { "preferences", "running_burning_guy", "preferences", "running_burning_guy" },
    { "preferences", "subtitles", "preferences", "subtitles" },
    { "preferences", "target_highlight", "preferences", "target_highlight" },
    { "preferences", "text_base_delay", "preferences", "text_base_delay" },
    { "preferences", "text_line_delay", "preferences", "text_line_delay" },
    { "preferences", "violence_level", "preferences", "violence_level" },
    { "sound", "cache_size", "sound", "cache_size" },
    { "sound", "device", "sound", "device" },
    { "sound", "dma", "sound", "dma" },
    { "sound", "initialize", "sound", "initialize" },
    { "sound", "irq", "sound", "irq" },
    { "sound", "master_volume", "sound", "master_volume" },
    { "sound", "music", "sound", "music" },
    { "sound", "music_path1", "sound", "music_path1" },
    { "sound", "music_path2", "sound", "music_path2" },
    { "sound", "music_volume", "sound", "music_volume" },
    { "sound", "port", "sound", "port" },
    { "sound", "sndfx_volume", "sound", "sndfx_volume" },
    { "sound", "sounds", "sound", "sounds" },
    { "sound", "speech", "sound", "speech" },
    { "sound", "speech_volume", "sound", "speech_volume" },
    { "system", "art_cache_size", "system", "art_cache_size" },
    { "system", "color_cycling", "system", "color_cycling" },
    { "system", "critter_dat", "system", "critter_dat" },
    { "system", "critter_patches", "system", "critter_patches" },
    { "system", "cycle_speed_factor", "system", "cycle_speed_factor" },
    { "system", "executable", "system", "executable" },
    { "system", "free_space", "system", "free_space" },
    { "system", "hashing", "system", "hashing" },
    { "system", "interrupt_walk", "system", "interrupt_walk" },
    { "system", "language", "system", "language" },
    { "system", "master_dat", "system", "master_dat" },
    { "system", "master_patches", "system", "master_patches" },
    { "system", "scroll_lock", "system", "scroll_lock" },
    { "system", "splash", "system", "splash" },
    { "system", "times_run", "system", "times_run" },
};

static const ProbeKeySpec kF1ResProbeKeys[] = {
    { "DISPLAY", "FPS_LIMIT", "DISPLAY", "FPS_LIMIT" },
    { "DISPLAY", "VSYNC", "DISPLAY", "VSYNC" },
    { "MAIN", "SCALE_2X", "MAIN", "SCALE_2X" },
    { "MAIN", "SCR_HEIGHT", "MAIN", "SCR_HEIGHT" },
    { "MAIN", "SCR_WIDTH", "MAIN", "SCR_WIDTH" },
    { "MAIN", "WINDOWED", "MAIN", "WINDOWED" },
};

static std::string escape_json(const std::string& value)
{
    std::string escaped;
    escaped.reserve(value.size());
    for (char ch : value) {
        switch (ch) {
        case '\\':
            escaped += "\\\\";
            break;
        case '"':
            escaped += "\\\"";
            break;
        case '\n':
            escaped += "\\n";
            break;
        case '\r':
            escaped += "\\r";
            break;
        case '\t':
            escaped += "\\t";
            break;
        default:
            escaped.push_back(ch);
            break;
        }
    }
    return escaped;
}

static bool probe_get_config_string(Config* config, const char* section, const char* key, std::string& out)
{
    char* value = nullptr;
    if (!config_get_string(config, section, key, &value) || value == nullptr) {
        out.clear();
        return false;
    }

    out = value;
    return true;
}

static std::string probe_string_for_int(int value)
{
    return std::to_string(value);
}

static int run_config_compat_probe(int argc, char* argv[])
{
    const char* probeEnv = getenv("RME_CONFIG_COMPAT_PROBE");
    if (probeEnv == nullptr || probeEnv[0] == '\0' || probeEnv[0] == '0') {
        return -1;
    }

    Config rawFalloutConfig;
    Config rawF1ResConfig;
    if (!config_init(&rawFalloutConfig) || !config_init(&rawF1ResConfig)) {
        return 2;
    }

    const bool rawFalloutLoaded = config_load(&rawFalloutConfig, GAME_CONFIG_FILE_NAME, false);

    if (!gconfig_init(false, argc, argv)) {
        config_exit(&rawFalloutConfig);
        config_exit(&rawF1ResConfig);
        return 2;
    }

    std::string f1ResPath;
    auto tryLoadResolutionConfig = [&](const char* path) {
        if (path == nullptr || path[0] == '\0') {
            return false;
        }
        if (config_load(&rawF1ResConfig, path, false)) {
            f1ResPath = path;
            return true;
        }
        return false;
    };

    bool rawF1Loaded = tryLoadResolutionConfig("f1_res.ini");
    if (!rawF1Loaded && argc > 0 && argv != nullptr && argv[0] != nullptr) {
        char resolvedArgvPath[PATH_MAX];
        const char* executablePath = argv[0];
        if (realpath(argv[0], resolvedArgvPath) != nullptr) {
            executablePath = resolvedArgvPath;
        }

        std::string executableDir(executablePath);
        size_t separatorPos = executableDir.find_last_of("/\\");
        if (separatorPos != std::string::npos) {
            executableDir = executableDir.substr(0, separatorPos + 1);
            rawF1Loaded = tryLoadResolutionConfig((executableDir + "../Resources/f1_res.ini").c_str());
            if (!rawF1Loaded) {
                rawF1Loaded = tryLoadResolutionConfig((executableDir + "f1_res.ini").c_str());
            }
        }
    }

    int requestedWidth = 640;
    int requestedHeight = 480;
    int scale = 1;
    int exclusive = 1;
    int vsync = 1;
    int fpsLimit = -1;
    bool fullscreen = true;

    if (rawF1Loaded) {
        int screenWidth = 0;
        if (config_get_value(&rawF1ResConfig, "MAIN", "SCR_WIDTH", &screenWidth)) {
            requestedWidth = std::max(screenWidth, 640);
        }

        int screenHeight = 0;
        if (config_get_value(&rawF1ResConfig, "MAIN", "SCR_HEIGHT", &screenHeight)) {
            requestedHeight = std::max(screenHeight, 480);
        }

        bool windowed = false;
        if (configGetBool(&rawF1ResConfig, "MAIN", "WINDOWED", &windowed)) {
            fullscreen = !windowed;
        }

        bool exclusiveMode = true;
        if (configGetBool(&rawF1ResConfig, "MAIN", "EXCLUSIVE", &exclusiveMode)) {
            exclusive = exclusiveMode ? 1 : 0;
        }

        int scaleValue = 0;
        if (config_get_value(&rawF1ResConfig, "MAIN", "SCALE_2X", &scaleValue)) {
            scale = std::clamp(scaleValue, 0, 1) + 1;
        }

        int vsyncValue = 0;
        if (config_get_value(&rawF1ResConfig, "DISPLAY", "VSYNC", &vsyncValue)) {
            vsync = vsyncValue != 0 ? 1 : 0;
        }

        int fpsLimitValue = -1;
        if (config_get_value(&rawF1ResConfig, "DISPLAY", "FPS_LIMIT", &fpsLimitValue)) {
            fpsLimit = std::max(-1, fpsLimitValue);
        }
    }

    int logicalWidth = requestedWidth;
    int logicalHeight = requestedHeight;
    if (scale > 1) {
        logicalWidth = requestedWidth / scale;
        logicalHeight = requestedHeight / scale;
    }
    logicalWidth = std::max(logicalWidth, 640);
    logicalHeight = std::max(logicalHeight, 480);

    int legacyDevice = -1;
    int legacyPort = -1;
    int legacyIrq = -1;
    int legacyDma = -1;
    config_get_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_DEVICE_KEY, &legacyDevice);
    config_get_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_PORT_KEY, &legacyPort);
    config_get_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_IRQ_KEY, &legacyIrq);
    config_get_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_DMA_KEY, &legacyDma);

    int soundInitNumBuffers = 24;
    if (legacyPort > 0) {
        soundInitNumBuffers = std::clamp(legacyPort, 4, 128);
    }

    int soundInitDataSize = 0x8000;
    if (legacyIrq > 0) {
        soundInitDataSize = std::clamp(legacyIrq, 4096, 131072);
    }

    int soundInitSampleRate = 22050;
    if (legacyDma > 0) {
        soundInitSampleRate = std::clamp(legacyDma, 8000, 96000);
    }

    int hashingValue = 0;
    config_get_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_HASHING_KEY, &hashingValue);
    bool showLoadInfo = false;
    configGetBool(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_SHOW_LOAD_INFO_KEY, &showLoadInfo);
    bool outputMapDataInfo = false;
    configGetBool(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_OUTPUT_MAP_DATA_INFO_KEY, &outputMapDataInfo);
    bool showTileNum = false;
    configGetBool(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_SHOW_TILE_NUM_KEY, &showTileNum);
    int timesRun = 0;
    config_get_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_TIMES_RUN_KEY, &timesRun);

    auto makeKeyId = [](const char* section, const char* key) {
        return std::string(section) + "::" + std::string(key);
    };

    std::ostringstream out;
    out << "{\n";
    out << "  \"fallout_cfg\": {\n";
    out << "    \"loaded\": " << (rawFalloutLoaded ? 1 : 0) << ",\n";
    out << "    \"keys\": [\n";
    for (size_t index = 0; index < std::size(kFalloutCfgProbeKeys); index++) {
        const ProbeKeySpec& spec = kFalloutCfgProbeKeys[index];
        const std::string keyId = makeKeyId(spec.section, spec.key);

        std::string parsedValue;
        std::string appliedValue;
        const bool parsed = probe_get_config_string(&rawFalloutConfig, spec.section, spec.key, parsedValue);
        const bool applied = probe_get_config_string(&game_config, spec.appliedSection, spec.appliedKey, appliedValue);

        std::string effectName = keyId;
        std::string effectValue = applied ? appliedValue : "";

        if (keyId == "preferences::player_speed") {
            std::string canonical;
            if (probe_get_config_string(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_PLAYER_SPEEDUP_KEY, canonical)) {
                effectName = "preferences::player_speedup";
                effectValue = canonical;
            }
        } else if (keyId == "system::hashing") {
            effectName = "db::hash_table_enabled";
            effectValue = hashingValue != 0 ? "1" : "0";
        } else if (keyId == "system::scroll_lock") {
            effectName = "input::scroll_lock_state";
            effectValue = kb_get_scroll_lock_state() ? "1" : "0";
        } else if (keyId == "system::times_run") {
            effectName = "system::times_run_runtime";
            effectValue = probe_string_for_int(timesRun);
        } else if (keyId == "sound::device") {
            effectName = "sound::detect_device";
            effectValue = probe_string_for_int(legacyDevice);
        } else if (keyId == "sound::port") {
            effectName = "sound::init_num_buffers";
            effectValue = probe_string_for_int(soundInitNumBuffers);
        } else if (keyId == "sound::irq") {
            effectName = "sound::init_data_size";
            effectValue = probe_string_for_int(soundInitDataSize);
        } else if (keyId == "sound::dma") {
            effectName = "sound::init_sample_rate";
            effectValue = probe_string_for_int(soundInitSampleRate);
        } else if (keyId == "debug::show_load_info") {
            effectName = "debug::show_load_info_runtime";
            effectValue = showLoadInfo ? "1" : "0";
        } else if (keyId == "debug::output_map_data_info") {
            effectName = "debug::output_map_data_info_runtime";
            effectValue = outputMapDataInfo ? "1" : "0";
        } else if (keyId == "debug::show_tile_num") {
            effectName = "debug::show_tile_num_runtime";
            effectValue = showTileNum ? "1" : "0";
        }

        out << "      {\"section\":\"" << escape_json(spec.section)
            << "\",\"key\":\"" << escape_json(spec.key)
            << "\",\"parsed\":" << (parsed ? 1 : 0)
            << ",\"parsed_value\":\"" << escape_json(parsed ? parsedValue : "")
            << "\",\"applied\":" << (applied ? 1 : 0)
            << ",\"applied_value\":\"" << escape_json(applied ? appliedValue : "")
            << "\",\"effect\":\"" << escape_json(effectName)
            << "\",\"effect_value\":\"" << escape_json(effectValue)
            << "\"}";
        if (index + 1 < std::size(kFalloutCfgProbeKeys)) {
            out << ",";
        }
        out << "\n";
    }
    out << "    ]\n";
    out << "  },\n";

    out << "  \"f1_res_ini\": {\n";
    out << "    \"loaded\": " << (rawF1Loaded ? 1 : 0) << ",\n";
    out << "    \"path\": \"" << escape_json(f1ResPath) << "\",\n";
    out << "    \"keys\": [\n";
    for (size_t index = 0; index < std::size(kF1ResProbeKeys); index++) {
        const ProbeKeySpec& spec = kF1ResProbeKeys[index];
        const std::string keyId = makeKeyId(spec.section, spec.key);

        std::string parsedValue;
        bool parsed = probe_get_config_string(&rawF1ResConfig, spec.section, spec.key, parsedValue);

        std::string appliedValue;
        std::string effectName = keyId;
        std::string effectValue;

        if (keyId == "MAIN::SCR_WIDTH") {
            appliedValue = probe_string_for_int(requestedWidth);
            effectName = "video::window_width";
            effectValue = probe_string_for_int(requestedWidth);
        } else if (keyId == "MAIN::SCR_HEIGHT") {
            appliedValue = probe_string_for_int(requestedHeight);
            effectName = "video::window_height";
            effectValue = probe_string_for_int(requestedHeight);
        } else if (keyId == "MAIN::WINDOWED") {
            appliedValue = fullscreen ? "0" : "1";
            effectName = "video::fullscreen";
            effectValue = fullscreen ? "1" : "0";
        } else if (keyId == "MAIN::SCALE_2X") {
            appliedValue = probe_string_for_int(scale - 1);
            effectName = "video::scale";
            effectValue = probe_string_for_int(scale);
        } else if (keyId == "DISPLAY::VSYNC") {
            appliedValue = probe_string_for_int(vsync);
            effectName = "video::vsync";
            effectValue = probe_string_for_int(vsync);
        } else if (keyId == "DISPLAY::FPS_LIMIT") {
            appliedValue = probe_string_for_int(fpsLimit);
            effectName = "video::fps_limit";
            effectValue = probe_string_for_int(fpsLimit);
        } else {
            appliedValue.clear();
            effectValue.clear();
        }

        out << "      {\"section\":\"" << escape_json(spec.section)
            << "\",\"key\":\"" << escape_json(spec.key)
            << "\",\"parsed\":" << (parsed ? 1 : 0)
            << ",\"parsed_value\":\"" << escape_json(parsed ? parsedValue : "")
            << "\",\"applied\":1"
            << ",\"applied_value\":\"" << escape_json(appliedValue)
            << "\",\"effect\":\"" << escape_json(effectName)
            << "\",\"effect_value\":\"" << escape_json(effectValue)
            << "\"}";
        if (index + 1 < std::size(kF1ResProbeKeys)) {
            out << ",";
        }
        out << "\n";
    }
    out << "    ],\n";
    out << "    \"video\": {"
        << "\"requested_width\":" << requestedWidth
        << ",\"requested_height\":" << requestedHeight
        << ",\"logical_width\":" << logicalWidth
        << ",\"logical_height\":" << logicalHeight
        << ",\"scale\":" << scale
        << ",\"fullscreen\":" << (fullscreen ? 1 : 0)
        << ",\"exclusive\":" << exclusive
        << ",\"vsync\":" << vsync
        << ",\"fps_limit\":" << fpsLimit
        << "}\n";
    out << "  }\n";
    out << "}\n";

    const char* outPath = getenv("RME_CONFIG_COMPAT_PROBE_OUT");
    if (outPath == nullptr || outPath[0] == '\0') {
        outPath = "rme-config-compat-probe.json";
    }

    FILE* stream = fopen(outPath, "w");
    if (stream == nullptr) {
        gconfig_exit(false);
        config_exit(&rawFalloutConfig);
        config_exit(&rawF1ResConfig);
        return 2;
    }

    std::string payload = out.str();
    fwrite(payload.data(), 1, payload.size(), stream);
    fclose(stream);

    if (rme_log_topic_enabled("config")) {
        rme_logf("config", "config compatibility probe wrote %s", outPath);
    }

    gconfig_exit(false);
    config_exit(&rawFalloutConfig);
    config_exit(&rawF1ResConfig);
    return 0;
}

} // namespace

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

    rc = run_config_compat_probe(argc, argv);
    if (rc >= 0) {
        return rc;
    }
#if __APPLE__ && TARGET_OS_IOS
    // Use dedicated touch gesture handling; avoid synthetic touch->mouse events
    SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    SDL_SetHint(SDL_HINT_PEN_MOUSE_EVENTS, "0");
    SDL_SetHint(SDL_HINT_PEN_TOUCH_EVENTS, "0");
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
