#include "game/gconfig.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "game/rme_log.h"
#include "platform_compat.h"

namespace fallout {

// A flag indicating if `game_config` was initialized.
//
// 0x504FD8
static bool gconfig_initialized = false;

// fallout.cfg
//
// 0x58CC20
Config game_config;

// NOTE: There are additional 4 bytes following this array at 0x58EA7C, which
// probably means it's size is 264 bytes.
//
// 0x58CC48
static char gconfig_file_name[COMPAT_MAX_PATH];

// Inits main game config.
//
// `isMapper` is a flag indicating whether we're initing config for a main
// game, or a mapper. This value is `false` for the game itself.
//
// `argc` and `argv` are command line arguments. The engine assumes there is
// at least 1 element which is executable path at index 0. There is no
// additional check for `argc`, so it will crash if you pass NULL, or an empty
// array into `argv`.
//
// The executable path from `argv` is used resolve path to `fallout.cfg`,
// which should be in the same folder. This function provide defaults if
// `fallout.cfg` is not present, or cannot be read for any reason.
//
// Finally, this function merges key-value pairs from `argv` if any, see
// `config_cmd_line_parse` for expected format.
//
// 0x43D690
bool gconfig_init(bool isMapper, int argc, char** argv)
{
    char* sep;

    if (gconfig_initialized) {
        return false;
    }

    // Allow env-driven logging before config is available.
    rme_log_init_from_env();

    if (!config_init(&game_config)) {
        return false;
    }

    // Initialize defaults.
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_EXECUTABLE_KEY, "game");
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_MASTER_DAT_KEY, "master.dat");
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_MASTER_PATCHES_KEY, "data");
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_CRITTER_DAT_KEY, "critter.dat");
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_CRITTER_PATCHES_KEY, "data");
    config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_LANGUAGE_KEY, ENGLISH);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_SCROLL_LOCK_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_INTERRUPT_WALK_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_ART_CACHE_SIZE_KEY, 8);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_COLOR_CYCLING_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_HASHING_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_SPLASH_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_FREE_SPACE_KEY, 20480);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_GAME_DIFFICULTY_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_COMBAT_DIFFICULTY_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_VIOLENCE_LEVEL_KEY, 3);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_TARGET_HIGHLIGHT_KEY, 2);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_ITEM_HIGHLIGHT_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_RUNNING_BURNING_GUY_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_COMBAT_MESSAGES_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_COMBAT_TAUNTS_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_LANGUAGE_FILTER_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_RUNNING_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_SUBTITLES_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_COMBAT_SPEED_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_PLAYER_SPEED_KEY, 0);
    config_set_double(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_TEXT_BASE_DELAY_KEY, 3.5);
    config_set_double(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_TEXT_LINE_DELAY_KEY, 1.399994);
    config_set_double(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_BRIGHTNESS_KEY, 1.0);
    config_set_double(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_MOUSE_SENSITIVITY_KEY, 1.0);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_INITIALIZE_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_DEVICE_KEY, -1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_PORT_KEY, -1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_IRQ_KEY, -1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_DMA_KEY, -1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_SOUNDS_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_SPEECH_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MASTER_VOLUME_KEY, 22281);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_VOLUME_KEY, 22281);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_SNDFX_VOLUME_KEY, 22281);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_SPEECH_VOLUME_KEY, 22281);
    config_set_value(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_CACHE_SIZE_KEY, 448);
    config_set_string(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_PATH1_KEY, "sound\\music\\");
    config_set_string(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_PATH2_KEY, "sound\\music\\");
    config_set_string(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_MODE_KEY, "environment");
    config_set_value(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_SHOW_TILE_NUM_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_INPUT_KEY, GAME_CONFIG_PENCIL_RIGHT_CLICK_KEY, 1);
    config_set_value(&game_config, GAME_CONFIG_INPUT_KEY, GAME_CONFIG_MAP_SCROLL_DELAY_KEY, 66);
    config_set_value(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_SHOW_SCRIPT_MESSAGES_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_SHOW_LOAD_INFO_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_RME_LOG_KEY, 0);
    config_set_value(&game_config, GAME_CONFIG_DEBUG_KEY, GAME_CONFIG_OUTPUT_MAP_DATA_INFO_KEY, 0);

    if (isMapper) {
        config_set_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_EXECUTABLE_KEY, "mapper");
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_OVERRIDE_LIBRARIAN_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_USE_ART_NOT_PROTOS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_REBUILD_PROTOS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_FIX_MAP_OBJECTS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_FIX_MAP_INVENTORY_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_IGNORE_REBUILD_ERRORS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_SHOW_PID_NUMBERS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_SAVE_TEXT_MAPS_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_RUN_MAPPER_AS_GAME_KEY, 0);
        config_set_value(&game_config, GAME_CONFIG_MAPPER_KEY, GAME_CONFIG_DEFAULT_F8_AS_GAME_KEY, 1);
    }

    // Make `fallout.cfg` file path.
    sep = strrchr(argv[0], '\\');
    if (sep != NULL) {
        *sep = '\0';
        snprintf(gconfig_file_name, sizeof(gconfig_file_name), "%s\\%s", argv[0], GAME_CONFIG_FILE_NAME);
        *sep = '\\';
    } else {
        strcpy(gconfig_file_name, GAME_CONFIG_FILE_NAME);
    }

    // Read contents of `fallout.cfg` into config. The values from the file
    // will override the defaults above.
    const bool cfg_loaded = config_load(&game_config, gconfig_file_name, false);

    // Add key-values from command line, which overrides both defaults and
    // whatever was loaded from `fallout.cfg`.
    config_cmd_line_parse(&game_config, argc, argv);

    // Backfill legacy preference key names to active runtime keys.
    // Older templates saved `player_speed` and `combat_looks`; current runtime
    // reads/writes `player_speedup` and `running_burning_guy`.
    int value = 0;
    if (!config_get_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_PLAYER_SPEEDUP_KEY, &value)
        && config_get_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_PLAYER_SPEED_KEY, &value)) {
        config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_PLAYER_SPEEDUP_KEY, value);
    }
    if (!config_get_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_RUNNING_BURNING_GUY_KEY, &value)
        && config_get_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_COMBAT_LOOKS_KEY, &value)) {
        config_set_value(&game_config, GAME_CONFIG_PREFERENCES_KEY, GAME_CONFIG_RUNNING_BURNING_GUY_KEY, value);
    }

    rme_log_sync_config(&game_config);

    if (rme_log_topic_enabled("config")) {
        const bool cfg_exists = access(gconfig_file_name, R_OK) == 0;

        char cwd[COMPAT_MAX_PATH];
        if (getcwd(cwd, sizeof(cwd)) == nullptr) {
            cwd[0] = '\0';
        }

        char* master_dat = nullptr;
        char* master_patches = nullptr;
        char* critter_dat = nullptr;
        char* critter_patches = nullptr;
        char* language = nullptr;
        char* music1 = nullptr;
        char* music2 = nullptr;
        int splash = 0;
        int hashing = 0;

        config_get_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_MASTER_DAT_KEY, &master_dat);
        config_get_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_MASTER_PATCHES_KEY, &master_patches);
        config_get_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_CRITTER_DAT_KEY, &critter_dat);
        config_get_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_CRITTER_PATCHES_KEY, &critter_patches);
        config_get_string(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_LANGUAGE_KEY, &language);
        config_get_string(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_PATH1_KEY, &music1);
        config_get_string(&game_config, GAME_CONFIG_SOUND_KEY, GAME_CONFIG_MUSIC_PATH2_KEY, &music2);
        config_get_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_SPLASH_KEY, &splash);
        config_get_value(&game_config, GAME_CONFIG_SYSTEM_KEY, GAME_CONFIG_HASHING_KEY, &hashing);

        rme_logf("config",
            "fallout.cfg path=%s exists=%d loaded=%d argv_count=%d cwd=%s language=%s hashing=%d splash=%d",
            gconfig_file_name,
            cfg_exists ? 1 : 0,
            cfg_loaded ? 1 : 0,
            argc,
            cwd,
            language != nullptr ? language : "(null)",
            hashing,
            splash);

        rme_logf("config",
            "config master_dat=%s master_patches=%s critter_dat=%s critter_patches=%s music1=%s music2=%s",
            master_dat != nullptr ? master_dat : "(null)",
            master_patches != nullptr ? master_patches : "(null)",
            critter_dat != nullptr ? critter_dat : "(null)",
            critter_patches != nullptr ? critter_patches : "(null)",
            music1 != nullptr ? music1 : "(null)",
            music2 != nullptr ? music2 : "(null)");
    }

    gconfig_initialized = true;

    return true;
}

// Saves game config into `fallout.cfg`.
//
// 0x43DD08
bool gconfig_save()
{
    if (!gconfig_initialized) {
        return false;
    }

    if (!config_save(&game_config, gconfig_file_name, false)) {
        return false;
    }

    return true;
}

// Frees game config, optionally saving it.
//
// 0x43DD30
bool gconfig_exit(bool shouldSave)
{
    if (!gconfig_initialized) {
        return false;
    }

    bool result = true;

    if (shouldSave) {
        if (!config_save(&game_config, gconfig_file_name, false)) {
            result = false;
        }
    }

    config_exit(&game_config);

    gconfig_initialized = false;

    return result;
}

} // namespace fallout
