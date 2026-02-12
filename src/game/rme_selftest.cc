#include "game/rme_selftest.h"

#include <cctype>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <unistd.h>
#include <vector>

#include "game/gsound.h"
#include "game/message.h"
#include "game/rme_log.h"
#include "plib/db/db.h"

namespace fs = std::filesystem;

static void json_escape(std::string& out, const std::string& s)
{
    for (char c : s) {
        switch (c) {
        case '\"':
            out += "\\\"";
            break;
        case '\\':
            out += "\\\\";
            break;
        case '\n':
            out += "\\n";
            break;
        case '\r':
            out += "\\r";
            break;
        case '\t':
            out += "\\t";
            break;
        default:
            out.push_back(c);
            break;
        }
    }
}

void rme_selftest_maybe_run(void)
{
    const char* env = std::getenv("RME_SELFTEST");
    if (env == nullptr || env[0] == '\0' || env[0] == '0') {
        return;
    }

    rme_logf("selftest", "starting selftest (RME_SELFTEST=1)");

    struct Failure {
        std::string kind;
        std::string path;
        std::string error;
    };

    std::vector<Failure> failures;

    auto add_failure = [&](const std::string& kind, const std::string& path, const std::string& error) {
        failures.push_back({ kind, path, error });
        rme_logf("selftest", "failure kind=%s path=%s error=%s", kind.c_str(), path.c_str(), error.c_str());
    };

    // Basic DB probe: ensure master.dat + critter.dat exist
    if (access("master.dat", R_OK) != 0) {
        add_failure("db", "master.dat", "missing or unreadable");
    }
    if (access("critter.dat", R_OK) != 0) {
        add_failure("db", "critter.dat", "missing or unreadable");
    }

    // Scripts: sample files under data/scripts
    int scripts_checked = 0;
    try {
        fs::path scripts_dir("data/scripts");
        if (fs::exists(scripts_dir) && fs::is_directory(scripts_dir)) {
            for (auto& p : fs::recursive_directory_iterator(scripts_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                // Sample up to 10
                if (++scripts_checked > 10) break;
                FILE* f = fopen(p.path().c_str(), "rb");
                if (!f) {
                    add_failure("scripts", p.path().string(), std::strerror(errno));
                    continue;
                }
                char buf[64];
                size_t got = fread(buf, 1, sizeof(buf), f);
                if (got == 0 && ferror(f)) {
                    add_failure("scripts", p.path().string(), "read failed");
                }
                fclose(f);
            }
        } else {
            add_failure("scripts", "data/scripts", "missing scripts directory");
        }
    } catch (const std::exception& e) {
        add_failure("scripts", "data/scripts", e.what());
    }

    // Maps: sample files under data/maps, read header bytes
    int maps_checked = 0;
    try {
        fs::path maps_dir("data/maps");
        if (fs::exists(maps_dir) && fs::is_directory(maps_dir)) {
            for (auto& p : fs::recursive_directory_iterator(maps_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                std::string ext = p.path().extension().string();
                for (auto& c : ext)
                    c = (char)std::tolower((unsigned char)c);
                if (ext == ".map") {
                    if (++maps_checked > 10) break;
                    FILE* f = fopen(p.path().c_str(), "rb");
                    if (!f) {
                        add_failure("map", p.path().string(), std::strerror(errno));
                        continue;
                    }
                    unsigned char header[236];
                    size_t got = fread(header, 1, sizeof(header), f);
                    if (got < 8) {
                        add_failure("map", p.path().string(), "header too small or read failed");
                    }
                    fclose(f);
                }
            }
        } else {
            add_failure("map", "data/maps", "missing maps directory");
        }
    } catch (const std::exception& e) {
        add_failure("map", "data/maps", e.what());
    }

    // Proto: look for .lst files under data/proto and sample
    int proto_checked = 0;
    try {
        fs::path proto_dir("data/proto");
        if (fs::exists(proto_dir) && fs::is_directory(proto_dir)) {
            for (auto& p : fs::recursive_directory_iterator(proto_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                std::string ext = p.path().extension().string();
                for (auto& c : ext)
                    c = (char)std::tolower((unsigned char)c);
                if (ext == ".lst") {
                    if (++proto_checked > 10) break;
                    FILE* f = fopen(p.path().c_str(), "rb");
                    if (!f) {
                        add_failure("proto", p.path().string(), std::strerror(errno));
                        continue;
                    }
                    char buf[256];
                    if (fgets(buf, sizeof(buf), f) == NULL && ferror(f)) {
                        add_failure("proto", p.path().string(), "read failed");
                    }
                    fclose(f);
                }
            }
        } else {
            add_failure("proto", "data/proto", "missing proto directory");
        }
    } catch (const std::exception& e) {
        add_failure("proto", "data/proto", e.what());
    }

    // Messages: sample .msg files under data/text
    int msgs_checked = 0;
    try {
        fs::path text_dir("data/text");
        if (fs::exists(text_dir) && fs::is_directory(text_dir)) {
            for (auto& p : fs::recursive_directory_iterator(text_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                std::string ext = p.path().extension().string();
                for (auto& c : ext)
                    c = (char)std::tolower((unsigned char)c);
                if (ext == ".msg") {
                    if (++msgs_checked > 10) break;

                    // Compute a path relative to data/text/<language>/ so
                    // message_load is invoked with a path like "game/map.msg".
                    fs::path rel = fs::relative(p.path(), text_dir);
                    auto it = rel.begin();
                    if (it == rel.end()) {
                        add_failure("message", p.path().string(), "unexpected text path layout");
                        continue;
                    }
                    // language component
                    std::string language = it->string();
                    ++it;
                    if (it == rel.end()) {
                        add_failure("message", p.path().string(), "unexpected text path layout");
                        continue;
                    }
                    fs::path rel_after_lang;
                    for (; it != rel.end(); ++it) {
                        rel_after_lang /= *it;
                    }

                    std::string rel_path = rel_after_lang.string();
                    // Normalize separators to backslash which the engine expects
                    for (auto& ch : rel_path)
                        if (ch == '/') ch = '\\';

                    // Try to use message_load on the relative path (safe-ish)
                    fallout::MessageList ml;
                    if (!fallout::message_init(&ml)) {
                        add_failure("message", p.path().string(), "message_init failed");
                        continue;
                    }
                    if (!fallout::message_load(&ml, rel_path.c_str())) {
                        add_failure("message", p.path().string(), "message_load failed");
                    }
                    fallout::message_exit(&ml);
                }
            }
        } else {
            add_failure("message", "data/text", "missing text directory");
        }
    } catch (const std::exception& e) {
        add_failure("message", "data/text", e.what());
    }

    // Art and Sound: sample files under data/art and data/sound
    int art_checked = 0;
    try {
        fs::path art_dir("data/art");
        if (fs::exists(art_dir) && fs::is_directory(art_dir)) {
            for (auto& p : fs::recursive_directory_iterator(art_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                if (++art_checked > 10) break;
                FILE* f = fopen(p.path().c_str(), "rb");
                if (!f) {
                    add_failure("art", p.path().string(), std::strerror(errno));
                    continue;
                }
                char buf[16];
                size_t got = fread(buf, 1, sizeof(buf), f);
                if (got == 0 && ferror(f)) {
                    add_failure("art", p.path().string(), "read failed");
                }
                fclose(f);
            }
        } else {
            add_failure("art", "data/art", "missing art directory");
        }
    } catch (const std::exception& e) {
        add_failure("art", "data/art", e.what());
    }

    int sound_checked = 0;
    try {
        fs::path sound_dir("data/sound");
        if (fs::exists(sound_dir) && fs::is_directory(sound_dir)) {
            for (auto& p : fs::recursive_directory_iterator(sound_dir)) {
                if (!fs::is_regular_file(p.path())) continue;
                if (++sound_checked > 10) break;
                FILE* f = fopen(p.path().c_str(), "rb");
                if (!f) {
                    add_failure("sound", p.path().string(), std::strerror(errno));
                    continue;
                }
                char buf[16];
                size_t got = fread(buf, 1, sizeof(buf), f);
                if (got == 0 && ferror(f)) {
                    add_failure("sound", p.path().string(), "read failed");
                }
                fclose(f);
            }
        } else {
            add_failure("sound", "data/sound", "missing sound directory");
        }
    } catch (const std::exception& e) {
        add_failure("sound", "data/sound", e.what());
    }

    // Prepare JSON output
    std::string out;
    std::ostringstream ss;
    ss << "{\n";
    ss << "  \"totals\": {\n";
    ss << "    \"scripts_checked\": " << scripts_checked << ",\n";
    ss << "    \"maps_checked\": " << maps_checked << ",\n";
    ss << "    \"proto_checked\": " << proto_checked << ",\n";
    ss << "    \"messages_checked\": " << msgs_checked << ",\n";
    ss << "    \"art_checked\": " << art_checked << ",\n";
    ss << "    \"sound_checked\": " << sound_checked << "\n";
    ss << "  },\n";
    ss << "  \"failures\": [\n";
    for (size_t i = 0; i < failures.size(); ++i) {
        const auto& f = failures[i];
        ss << "    {\"kind\": \"";
        std::string tmp;
        json_escape(tmp, f.kind);
        ss << tmp << "\", \"path\": \"";
        tmp.clear();
        json_escape(tmp, f.path);
        ss << tmp << "\", \"error\": \"";
        tmp.clear();
        json_escape(tmp, f.error);
        ss << tmp << "\"}";
        if (i + 1 < failures.size()) ss << ",";
        ss << "\n";
    }
    ss << "  ]\n";
    ss << "}\n";

    std::string json_out = ss.str();

    FILE* out_f = fopen("rme-selftest.json", "w");
    if (out_f) {
        fwrite(json_out.c_str(), 1, json_out.size(), out_f);
        fclose(out_f);
    } else {
        rme_logf("selftest", "failed to write rme-selftest.json: %s", std::strerror(errno));
    }

    // Summary log
    rme_logf("selftest", "completed: checked scripts=%d maps=%d proto=%d messages=%d art=%d sound=%d failures=%d",
        scripts_checked, maps_checked, proto_checked, msgs_checked, art_checked, sound_checked, (int)failures.size());

    // Attempt conservative cleanup
    rme_logf("selftest", "performing conservative cleanup prior to exit");
    // Close databases and sound systems
    fallout::db_exit();
    fallout::gsound_exit();

    // Exit process; 0=success, 2=some failures
    if (failures.empty()) {
        exit(0);
    } else {
        exit(2);
    }
}
