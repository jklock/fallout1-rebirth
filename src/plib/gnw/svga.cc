#include "plib/gnw/svga.h"

#include <SDL3/SDL.h>

#include "plib/db/patchlog.h"
#include <algorithm>
#include <stdlib.h>

#include "game/map.h"
#include "plib/gnw/debug.h"
#include "plib/gnw/gnw.h"
#include "plib/gnw/grbuf.h"
#include "plib/gnw/mouse.h"
#include "plib/gnw/winmain.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IOS
#include "platform/ios/pencil.h"
#endif
#endif

namespace fallout {

static bool createRenderer(int width, int height);
static void destroyRenderer();

// Monotonic sequence number for GNW_SHOW_RECT / renderPresent events
static unsigned long long g_seq = 0;

// Recent suspicious surface wipe events (ring buffer for diagnostics)
struct SurfSuspect {
    unsigned long long seq;
    unsigned char* surfacePtr;
    int destX;
    int destY;
    int copyW;
    int copyH;
    int sampleSurf0;
    long preSurfaceNonZero;
    long postSurfaceNonZero;
};

static SurfSuspect g_suspects[16];
static int g_suspect_pos = 0;

// screen rect
Rect scr_size;

// 0x6ACA18
ScreenBlitFunc* scr_blit = GNW95_ShowRect;

SDL_Window* gSdlWindow = NULL;
SDL_Surface* gSdlSurface = NULL;
SDL_Renderer* gSdlRenderer = NULL;
SDL_Texture* gSdlTexture = NULL;
SDL_Surface* gSdlTextureSurface = NULL;

// When running under a non-Cocoa SDL video driver (dummy/offscreen), we treat
// rendering as "headless". Some renderer features (like logical presentation)
// are optional in that mode and should not hard-fail initialization.
static bool gHeadlessVideo = false;

#if __APPLE__ && TARGET_OS_IOS
// iOS-specific: Custom destination rect for fullscreen rendering
static SDL_FRect g_iOS_destRect = { 0, 0, 0, 0 };
static bool g_iOS_useCustomRect = false;
static int g_iOS_gameWidth = 640; // Game logical resolution
static int g_iOS_gameHeight = 480;
static int g_iOS_last_window_pw = 0;
static int g_iOS_last_window_ph = 0;

static void iOS_updateDestRect()
{
    if (gSdlWindow == NULL) {
        g_iOS_useCustomRect = false;
        return;
    }

    int window_pw = 0;
    int window_ph = 0;
    SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);

    if (window_pw <= 0 || window_ph <= 0) {
        g_iOS_useCustomRect = false;
        return;
    }

    int sdl_w = window_pw; // SDL's reported width (larger for portrait device)
    int sdl_h = window_ph; // SDL's reported height (smaller for portrait device)

    SDL_Log("iOS_updateDestRect: SDL pixel size: %dx%d", sdl_w, sdl_h);

    // Calculate in SDL's coordinate system
    // The game needs to maintain 4:3 aspect ratio
    float game_aspect = (float)g_iOS_gameWidth / (float)g_iOS_gameHeight; // 4:3 = 1.333
    float sdl_aspect = (float)sdl_w / (float)sdl_h;

    SDL_Log("iOS_updateDestRect: sdl_aspect=%.3f game_aspect=%.3f", sdl_aspect, game_aspect);

    if (sdl_aspect > game_aspect) {
        // SDL viewport is wider than game - constrain by height, add bars on sides
        // This is the normal case for portrait iPad showing 4:3 game
        int content_w = (int)(sdl_h * game_aspect);
        g_iOS_destRect.x = (sdl_w - content_w) / 2.0f;
        g_iOS_destRect.y = 0;
        g_iOS_destRect.w = (float)content_w;
        g_iOS_destRect.h = (float)sdl_h;
        SDL_Log("iOS_updateDestRect: pillarbox in SDL space (bars on sides)");
    } else {
        // SDL viewport is taller than game - constrain by width, add bars top/bottom
        int content_h = (int)(sdl_w / game_aspect);
        g_iOS_destRect.x = 0;
        g_iOS_destRect.y = (sdl_h - content_h) / 2.0f;
        g_iOS_destRect.w = (float)sdl_w;
        g_iOS_destRect.h = (float)content_h;
        SDL_Log("iOS_updateDestRect: letterbox in SDL space (bars top/bottom)");
    }
    g_iOS_useCustomRect = true;

    SDL_Log("iOS_updateDestRect: dest rect: (%.0f, %.0f, %.0f, %.0f)",
        g_iOS_destRect.x, g_iOS_destRect.y, g_iOS_destRect.w, g_iOS_destRect.h);
}
#endif

// TODO: Remove once migration to update-render cycle is completed.
FpsLimiter sharedFpsLimiter;

// 0x4CB310
void GNW95_SetPaletteEntries(unsigned char* palette, int start, int count)
{
    if (gSdlSurface != NULL) {
        SDL_Palette* pal = SDL_GetSurfacePalette(gSdlSurface);
        if (pal != NULL) {
            SDL_Color colors[256];

            if (count != 0) {
                for (int index = 0; index < count; index++) {
                    colors[index].r = palette[index * 3] << 2;
                    colors[index].g = palette[index * 3 + 1] << 2;
                    colors[index].b = palette[index * 3 + 2] << 2;
                    colors[index].a = 255;
                }
            }

            SDL_SetPaletteColors(pal, colors, start, count);
            SDL_BlitSurface(gSdlSurface, NULL, gSdlTextureSurface, NULL);
        }
    }
}

// 0x4CB568
void GNW95_SetPalette(unsigned char* palette)
{
    if (gSdlSurface != NULL) {
        SDL_Palette* pal = SDL_GetSurfacePalette(gSdlSurface);
        if (pal != NULL) {
            SDL_Color colors[256];

            for (int index = 0; index < 256; index++) {
                colors[index].r = palette[index * 3] << 2;
                colors[index].g = palette[index * 3 + 1] << 2;
                colors[index].b = palette[index * 3 + 2] << 2;
                colors[index].a = 255;
            }

            SDL_SetPaletteColors(pal, colors, 0, 256);
            SDL_BlitSurface(gSdlSurface, NULL, gSdlTextureSurface, NULL);
        }
    }
}

// 0x4CB850
void GNW95_ShowRect(unsigned char* src, unsigned int srcPitch, unsigned int a3, unsigned int srcX, unsigned int srcY, unsigned int srcWidth, unsigned int srcHeight, unsigned int destX, unsigned int destY)
{
    // Clip copy to the bounds of gSdlSurface to avoid out-of-bounds when logical
    // resolution is smaller than interface assets (e.g. 512-wide surface vs 640-wide bar).
    int copyX = static_cast<int>(destX);
    int copyY = static_cast<int>(destY);
    int copyW = static_cast<int>(srcWidth);
    int copyH = static_cast<int>(srcHeight);
    int srcOffsetX = static_cast<int>(srcX);
    int srcOffsetY = static_cast<int>(srcY);

    if (copyX < 0) {
        srcOffsetX -= copyX;
        copyW += copyX;
        copyX = 0;
    }
    if (copyY < 0) {
        srcOffsetY -= copyY;
        copyH += copyY;
        copyY = 0;
    }
    if (copyX + copyW > gSdlSurface->w) {
        copyW = gSdlSurface->w - copyX;
    }
    if (copyY + copyH > gSdlSurface->h) {
        copyH = gSdlSurface->h - copyY;
    }

    if (copyW <= 0 || copyH <= 0) {
        return;
    }

    bool do_log = false;
    if (patchlog_verbose()) {
        const char* autorun_env = getenv("F1R_AUTORUN_MAP");
        if (autorun_env != NULL && autorun_env[0] != '\0' && autorun_env[0] != '0') {
            do_log = true;
        }
    }

    unsigned char* srcPtr = src + srcPitch * srcOffsetY + srcOffsetX;
    unsigned char* surfacePtr = (unsigned char*)gSdlSurface->pixels + gSdlSurface->pitch * copyY + copyX;

    long preSrcNonZero = 0;
    long preSurfaceNonZero = 0;
    long preDisplayNonZero = 0;
    long postDisplayNonZero = 0;
    int sampleSrc0 = 0;
    int sampleSurf0 = 0;

    // Additional diagnostics: when copying a full-width region that likely
    // covers the map area, capture pointer addresses and the first few bytes
    // of the source/surface to help detect pointer mismatches.
    if (do_log) {
        sampleSrc0 = (int)srcPtr[0];
        sampleSurf0 = (int)surfacePtr[0];

        if (copyW >= 640) {
            unsigned long long seq = ++g_seq;
            patchlog_write("GNW_SHOW_RECT_SRC", "seq=%llu srcPtr=%p surfacePtr=%p dest=(%d,%d) copy=%dx%d srcOffset=(%d,%d) sampleSrc0=%d sampleSurf0=%d", seq, srcPtr, surfacePtr, copyX, copyY, copyW, copyH, srcOffsetX, srcOffsetY, sampleSrc0, sampleSurf0);
        }
    }

    if (do_log) {
        unsigned char* rsrc = srcPtr;
        for (int row = 0; row < copyH; row++) {
            unsigned char* p = rsrc;
            for (int col = 0; col < copyW; col++) {
                if (p[col] != 0) {
                    preSrcNonZero++;
                }
            }
            rsrc += srcPitch;
        }
        unsigned char* rsurf = surfacePtr;
        for (int row = 0; row < copyH; row++) {
            unsigned char* p = rsurf;
            for (int col = 0; col < copyW; col++) {
                if (p[col] != 0) {
                    preSurfaceNonZero++;
                }
            }
            rsurf += gSdlSurface->pitch;
        }

        // Sample the display buffer for the same rectangle (pre-copy)
        preDisplayNonZero = map_count_display_non_zero(copyX, copyY, copyW, copyH);
    }

    buf_to_buf(srcPtr,
        copyW,
        copyH,
        srcPitch,
        surfacePtr,
        gSdlSurface->pitch);

    long postSurfaceNonZero = 0;
    if (do_log) {
        unsigned char* rsurf = surfacePtr;
        for (int row = 0; row < copyH; row++) {
            unsigned char* p = rsurf;
            for (int col = 0; col < copyW; col++) {
                if (p[col] != 0) {
                    postSurfaceNonZero++;
                }
            }
            rsurf += gSdlSurface->pitch;
        }

        // Sample the display buffer for the same rectangle (post-copy)
        postDisplayNonZero = map_count_display_non_zero(copyX, copyY, copyW, copyH);
    }

    SDL_Rect srcRect;
    srcRect.x = copyX;
    srcRect.y = copyY;
    srcRect.w = copyW;
    srcRect.h = copyH;

    SDL_Rect destRect;
    destRect.x = copyX;
    destRect.y = copyY;
    destRect.w = copyW;
    destRect.h = copyH;

    // Also clip destination to texture surface bounds
    if (destRect.x + destRect.w > gSdlTextureSurface->w) {
        destRect.w = gSdlTextureSurface->w - destRect.x;
        srcRect.w = destRect.w;
    }
    if (destRect.y + destRect.h > gSdlTextureSurface->h) {
        destRect.h = gSdlTextureSurface->h - destRect.y;
        srcRect.h = destRect.h;
    }

    if (destRect.w <= 0 || destRect.h <= 0) {
        return;
    }

    long preTextureNonZero = 0;
    if (do_log && gSdlTextureSurface != NULL) {
        int bpp = (gSdlTextureSurface->w > 0) ? (gSdlTextureSurface->pitch / gSdlTextureSurface->w) : 1;
        unsigned char* tptr = (unsigned char*)gSdlTextureSurface->pixels + gSdlTextureSurface->pitch * destRect.y + destRect.x * bpp;
        for (int row = 0; row < destRect.h; row++) {
            unsigned char* r = tptr;
            for (int col = 0; col < destRect.w; col++) {
                unsigned char* pixel = r + col * bpp;
                bool any_non_zero = false;
                for (int byte = 0; byte < bpp; byte++) {
                    if (pixel[byte] != 0) {
                        any_non_zero = true;
                        break;
                    }
                }
                if (any_non_zero) {
                    preTextureNonZero++;
                }
            }
            tptr += gSdlTextureSurface->pitch;
        }
    }

    SDL_BlitSurface(gSdlSurface, &srcRect, gSdlTextureSurface, &destRect);

    if (do_log) {
        long postTextureNonZero = 0;
        if (gSdlTextureSurface != NULL) {
            int bpp = (gSdlTextureSurface->w > 0) ? (gSdlTextureSurface->pitch / gSdlTextureSurface->w) : 1;
            unsigned char* tptr = (unsigned char*)gSdlTextureSurface->pixels + gSdlTextureSurface->pitch * destRect.y + destRect.x * bpp;
            for (int row = 0; row < destRect.h; row++) {
                unsigned char* r = tptr;
                for (int col = 0; col < destRect.w; col++) {
                    unsigned char* pixel = r + col * bpp;
                    bool any_non_zero = false;
                    for (int byte = 0; byte < bpp; byte++) {
                        if (pixel[byte] != 0) {
                            any_non_zero = true;
                            break;
                        }
                    }
                    if (any_non_zero) {
                        postTextureNonZero++;
                    }
                }
                tptr += gSdlTextureSurface->pitch;
            }
        }
        unsigned long long seq = ++g_seq;
        patchlog_write("GNW_SHOW_RECT", "seq=%llu surfacePtr=%p dest=(%d,%d) copy=%dx%d src_nonzero=%ld surf_pre=%ld surf_post=%ld disp_pre=%ld disp_post=%ld tex_pre=%ld tex_post=%ld", seq, surfacePtr, copyX, copyY, copyW, copyH, preSrcNonZero, preSurfaceNonZero, postSurfaceNonZero, preDisplayNonZero, postDisplayNonZero, preTextureNonZero, postTextureNonZero);

        if (preSurfaceNonZero > 0 && postSurfaceNonZero == 0) {
            // Very suspicious: surface had non-zero data before the copy and is zero afterwards.
            // Log additional immediate context to help triage and store in recent-suspect ring buffer.
            int postSurf0 = (int)surfacePtr[0];
            patchlog_write("GNW_SURF_SUSPECT", "seq=%llu surfacePtr=%p dest=(%d,%d) copy=%dx%d sampleSurf0=%d preSurfaceNonZero=%ld postSurfaceNonZero=%ld postTextureNonZero=%ld", seq, surfacePtr, copyX, copyY, copyW, copyH, sampleSurf0, preSurfaceNonZero, postSurfaceNonZero, postTextureNonZero);

            // Store a compact record for later correlation with present anomalies
            g_suspects[g_suspect_pos].seq = seq;
            g_suspects[g_suspect_pos].surfacePtr = surfacePtr;
            g_suspects[g_suspect_pos].destX = copyX;
            g_suspects[g_suspect_pos].destY = copyY;
            g_suspects[g_suspect_pos].copyW = copyW;
            g_suspects[g_suspect_pos].copyH = copyH;
            g_suspects[g_suspect_pos].sampleSurf0 = sampleSurf0;
            g_suspects[g_suspect_pos].preSurfaceNonZero = preSurfaceNonZero;
            g_suspects[g_suspect_pos].postSurfaceNonZero = postSurfaceNonZero;
            g_suspect_pos = (g_suspect_pos + 1) % 16;
        }
    }
}

bool svga_init(VideoOptions* video_options)
{
    SDL_Log("svga_init: starting with %dx%d (scale=%d)",
        video_options->width, video_options->height, video_options->scale);

#if __APPLE__ && TARGET_OS_IOS
    SDL_SetHint(SDL_HINT_IOS_HIDE_HOME_INDICATOR, "2");
#endif

    if (!SDL_InitSubSystem(SDL_INIT_VIDEO)) {
        SDL_Log("svga_init: SDL_InitSubSystem failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("svga_init: SDL video subsystem initialized");

    const char* video_driver = SDL_GetCurrentVideoDriver();
    if (video_driver != NULL) {
        SDL_Log("svga_init: video driver=%s", video_driver);
    } else {
        SDL_Log("svga_init: video driver unavailable");
    }

    gHeadlessVideo = video_driver != NULL
        && (SDL_strcasecmp(video_driver, "dummy") == 0
            || SDL_strcasecmp(video_driver, "offscreen") == 0);
    if (gHeadlessVideo) {
        SDL_Log("svga_init: headless video driver detected");
    }

    if (!gHeadlessVideo) {
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    }

    SDL_WindowFlags windowFlags = SDL_WINDOW_HIGH_PIXEL_DENSITY;

// This hides the status bar on iPadOS, which otherwise interferes
// with the cursor in the top margin of the screen.
#if __APPLE__ && TARGET_OS_IOS
    windowFlags |= SDL_WINDOW_BORDERLESS;
    // On iOS, always use fullscreen to fill the entire screen
    windowFlags |= SDL_WINDOW_FULLSCREEN;
#else
    if (video_options->fullscreen) {
        windowFlags |= SDL_WINDOW_FULLSCREEN;
    }
#endif

    SDL_Log("svga_init: creating window %dx%d flags=0x%x",
        video_options->width * video_options->scale,
        video_options->height * video_options->scale,
        (unsigned int)windowFlags);

#if __APPLE__ && TARGET_OS_IOS
    // On iOS, create window with 0x0 dimensions to let fullscreen determine size
    // This ensures the window fills the entire screen regardless of device
    gSdlWindow = SDL_CreateWindow(GNW95_title, 0, 0, windowFlags);
#else
    gSdlWindow = SDL_CreateWindow(GNW95_title,
        video_options->width * video_options->scale,
        video_options->height * video_options->scale,
        windowFlags);
#endif
    if (gSdlWindow == NULL) {
        SDL_Log("svga_init: SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }

    // Log actual window dimensions after creation
    int window_w, window_h;
    SDL_GetWindowSize(gSdlWindow, &window_w, &window_h);
    int window_pw, window_ph;
    SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);
    SDL_Log("svga_init: window created - size=%dx%d, pixels=%dx%d", window_w, window_h, window_pw, window_ph);

    // Log safe area info
    SDL_Rect safeArea;
    if (SDL_GetWindowSafeArea(gSdlWindow, &safeArea)) {
        SDL_Log("svga_init: safe area: x=%d y=%d w=%d h=%d", safeArea.x, safeArea.y, safeArea.w, safeArea.h);
    } else {
        SDL_Log("svga_init: no safe area info available");
    }

#if __APPLE__ && TARGET_OS_IOS
    // On iOS with HIGH_PIXEL_DENSITY, we skip SDL_SetRenderLogicalPresentation
    // and instead manually control the destination rect during rendering.
    //
    // IMPORTANT: SDL3 on iOS reports dimensions and uses coordinates in "native landscape"
    // orientation, even when the device is in portrait. The iOS display system handles
    // the rotation automatically when presenting to the screen.
    //
    // For a 4:3 landscape game on an iPad in portrait:
    // - SDL reports: 2752x2064 (landscape, w > h)
    // - Actual display: 2064x2752 (portrait, h > w)
    // - We need to render the 4:3 game content letterboxed within SDL's coordinate space
    //
    // Since SDL operates in landscape coordinates:
    // - SDL width (2752) corresponds to the portrait screen's HEIGHT
    // - SDL height (2064) corresponds to the portrait screen's WIDTH
    //
    // For a 4:3 game in a 3:4 portrait view (through SDL's landscape lens):
    // - The "width" (SDL's coordinate) should be constrained by the narrow dimension
    // - We want black bars at the "top" and "bottom" of the portrait display
    // - In SDL's coordinate system, that's the LEFT and RIGHT sides
    //
    // Store game resolution for coordinate conversion
    g_iOS_gameWidth = video_options->width;
    g_iOS_gameHeight = video_options->height;
    iOS_updateDestRect();
    SDL_GetWindowSizeInPixels(gSdlWindow, &g_iOS_last_window_pw, &g_iOS_last_window_ph);
#endif

    if (!createRenderer(video_options->width, video_options->height)) {
        SDL_Log("svga_init: createRenderer failed");
        destroyRenderer();

        SDL_DestroyWindow(gSdlWindow);
        gSdlWindow = NULL;

        return false;
    }
    SDL_Log("svga_init: renderer created successfully");

    gSdlSurface = SDL_CreateSurface(
        video_options->width,
        video_options->height,
        SDL_PIXELFORMAT_INDEX8);
    if (gSdlSurface == NULL) {
        SDL_Log("svga_init: SDL_CreateSurface failed: %s", SDL_GetError());
        destroyRenderer();

        SDL_DestroyWindow(gSdlWindow);
        gSdlWindow = NULL;
    }

    SDL_Color colors[256];
    for (int index = 0; index < 256; index++) {
        colors[index].r = index;
        colors[index].g = index;
        colors[index].b = index;
        colors[index].a = 255;
    }

    SDL_Palette* palette = SDL_CreatePalette(256);
    if (palette != NULL) {
        SDL_SetPaletteColors(palette, colors, 0, 256);
        SDL_SetSurfacePalette(gSdlSurface, palette);
        SDL_DestroyPalette(palette);
    }

    scr_size.ulx = 0;
    scr_size.uly = 0;
    scr_size.lrx = video_options->width - 1;
    scr_size.lry = video_options->height - 1;

    mouse_blit_trans = NULL;
    scr_blit = GNW95_ShowRect;
    mouse_blit = GNW95_ShowRect;

#if defined(__APPLE__) && TARGET_OS_IOS
    // Initialize Apple Pencil detection and gesture handling
    pencil_init(gSdlWindow);
#endif

    return true;
}

void svga_exit()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    // Shutdown Apple Pencil detection
    pencil_shutdown();
#endif

    destroyRenderer();

    if (gSdlWindow != NULL) {
        SDL_DestroyWindow(gSdlWindow);
        gSdlWindow = NULL;
    }

    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}

int screenGetWidth()
{
    // TODO: Make it on par with _xres;
    return rectGetWidth(&scr_size);
}

int screenGetHeight()
{
    // TODO: Make it on par with _yres.
    return rectGetHeight(&scr_size);
}

static bool createRenderer(int width, int height)
{
    SDL_Log("createRenderer: creating renderer for %dx%d", width, height);

    gSdlRenderer = SDL_CreateRenderer(gSdlWindow, NULL);
    if (gSdlRenderer == NULL) {
        SDL_Log("createRenderer: SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("createRenderer: renderer created");

    // Enable VSync
    SDL_SetRenderVSync(gSdlRenderer, 1);

    // Log display refresh rate for diagnostic purposes
    SDL_DisplayID displayID = SDL_GetDisplayForWindow(gSdlWindow);
    const SDL_DisplayMode* mode = SDL_GetCurrentDisplayMode(displayID);
    if (mode != NULL) {
        SDL_Log("Display refresh rate: %.2f Hz", mode->refresh_rate);
        SDL_Log("Display resolution: %dx%d", mode->w, mode->h);
    } else {
        SDL_Log("Could not query display mode: %s", SDL_GetError());
    }

#if !(__APPLE__ && TARGET_OS_IOS)
    // On iOS, we use custom destination rect instead of logical presentation
    // to have better control over fullscreen scaling.
    if (!SDL_SetRenderLogicalPresentation(gSdlRenderer, width, height, SDL_LOGICAL_PRESENTATION_LETTERBOX)) {
        SDL_Log("createRenderer: SDL_SetRenderLogicalPresentation failed: %s", SDL_GetError());
        if (!gHeadlessVideo) {
            return false;
        }
        SDL_Log("createRenderer: headless video - continuing without logical presentation");
    } else {
        SDL_Log("createRenderer: logical presentation set to %dx%d", width, height);
    }
#else
    SDL_Log("createRenderer: iOS - skipping logical presentation (using custom dest rect)");
#endif

    gSdlTexture = SDL_CreateTexture(gSdlRenderer, SDL_PIXELFORMAT_XRGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
    if (gSdlTexture == NULL) {
        SDL_Log("createRenderer: SDL_CreateTexture failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("createRenderer: texture created");

    // Enable nearest neighbor (pixel-perfect) scaling for crisp retro graphics
    SDL_SetTextureScaleMode(gSdlTexture, SDL_SCALEMODE_NEAREST);

    // SDL3: Get texture format via properties instead of SDL_QueryTexture
    SDL_PropertiesID props = SDL_GetTextureProperties(gSdlTexture);
    SDL_PixelFormat format = (SDL_PixelFormat)SDL_GetNumberProperty(props, SDL_PROP_TEXTURE_FORMAT_NUMBER, SDL_PIXELFORMAT_UNKNOWN);
    if (format == SDL_PIXELFORMAT_UNKNOWN) {
        SDL_Log("createRenderer: SDL_GetTextureProperties failed - format unknown");
        return false;
    }

    gSdlTextureSurface = SDL_CreateSurface(width, height, format);
    if (gSdlTextureSurface == NULL) {
        SDL_Log("createRenderer: SDL_CreateSurface for texture failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("createRenderer: texture surface created - initialization complete");

    return true;
}

static void destroyRenderer()
{
    if (gSdlTextureSurface != NULL) {
        SDL_DestroySurface(gSdlTextureSurface);
        gSdlTextureSurface = NULL;
    }

    if (gSdlTexture != NULL) {
        SDL_DestroyTexture(gSdlTexture);
        gSdlTexture = NULL;
    }

    if (gSdlRenderer != NULL) {
        SDL_DestroyRenderer(gSdlRenderer);
        gSdlRenderer = NULL;
    }
}

bool handleWindowSizeChanged()
{
#if __APPLE__ && TARGET_OS_IOS
    if (gSdlWindow == NULL) {
        return false;
    }

    int window_pw = 0;
    int window_ph = 0;
    SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);
    if (window_pw <= 0 || window_ph <= 0) {
        return false;
    }

    if (window_pw == g_iOS_last_window_pw && window_ph == g_iOS_last_window_ph) {
        return false;
    }

    g_iOS_last_window_pw = window_pw;
    g_iOS_last_window_ph = window_ph;
    iOS_updateDestRect();
    return true;
#else
    destroyRenderer();
    createRenderer(screenGetWidth(), screenGetHeight());
    return true;
#endif
}

void renderPresent()
{
    long pre_texture_surface_non_zero = 0;
    if (patchlog_verbose()) {
        const char* autorun_env = getenv("F1R_AUTORUN_MAP");
        if (autorun_env != NULL && autorun_env[0] != '\0' && autorun_env[0] != '0') {
            int window_h = gSdlTextureSurface->h;
            int ui_h = 120;
            int top_h = window_h - ui_h;
            if (top_h < 0) {
                top_h = 0;
            }

            int bpp = (gSdlTextureSurface->w > 0) ? (gSdlTextureSurface->pitch / gSdlTextureSurface->w) : 1;
            unsigned char* pixels = (unsigned char*)gSdlTextureSurface->pixels;
            int pitch = gSdlTextureSurface->pitch;
            int width = gSdlTextureSurface->w;
            for (int row = 0; row < top_h; row++) {
                unsigned char* rowp = pixels + row * pitch;
                for (int col = 0; col < width; col++) {
                    unsigned char* pixel = rowp + col * bpp;
                    bool any_non_zero = false;
                    for (int byte = 0; byte < bpp; byte++) {
                        if (pixel[byte] != 0) {
                            any_non_zero = true;
                            break;
                        }
                    }
                    if (any_non_zero) {
                        pre_texture_surface_non_zero++;
                    }
                }
            }
        }
    }

    SDL_UpdateTexture(gSdlTexture, NULL, gSdlTextureSurface->pixels, gSdlTextureSurface->pitch);
    SDL_RenderClear(gSdlRenderer);
#if __APPLE__ && TARGET_OS_IOS
    // On iOS, render to custom destination rect to fill screen with proper aspect ratio
    if (g_iOS_useCustomRect) {
        SDL_RenderTexture(gSdlRenderer, gSdlTexture, NULL, &g_iOS_destRect);
    } else {
        SDL_RenderTexture(gSdlRenderer, gSdlTexture, NULL, NULL);
    }
#else
    SDL_RenderTexture(gSdlRenderer, gSdlTexture, NULL, NULL);
#endif
    SDL_RenderPresent(gSdlRenderer);

    if (patchlog_verbose()) {
        const char* autorun_env = getenv("F1R_AUTORUN_MAP");
        if (autorun_env != NULL && autorun_env[0] != '\0' && autorun_env[0] != '0') {
            int window_h = gSdlTextureSurface->h;
            int ui_h = 120;
            int top_h = window_h - ui_h;
            if (top_h < 0) {
                top_h = 0;
            }

            long present_non_zero = 0;
            SDL_Surface* surf = SDL_RenderReadPixels(gSdlRenderer, NULL);
            if (surf != NULL) {
                int surfW = surf->w;
                int surfH = surf->h;
                int surfBpp = (surfW > 0) ? (surf->pitch / surfW) : 4;
                unsigned char* surfPixels = (unsigned char*)surf->pixels;
                int surfPitch = surf->pitch;
                int rows = top_h < surfH ? top_h : surfH;
                for (int row = 0; row < rows; row++) {
                    unsigned char* rowp = surfPixels + row * surfPitch;
                    for (int col = 0; col < surfW; col++) {
                        unsigned char* pixel = rowp + col * surfBpp;
                        if (pixel[0] != 0 || pixel[1] != 0 || pixel[2] != 0 || (surfBpp > 3 && pixel[3] != 0)) {
                            present_non_zero++;
                        }
                    }
                }

                // Detect anomaly: texture claims zero content for top area, but the actual
                // presented pixels contain non-zero content (possible race between fills
                // and re-blit, or an out-of-band present).
                if (pre_texture_surface_non_zero == 0 && present_non_zero > 0) {
                    unsigned long long anomaly_seq = ++g_seq;
                    patchlog_write("RENDER_PRESENT_ANOMALY", "seq=%llu pre=%ld present=%ld", anomaly_seq, pre_texture_surface_non_zero, present_non_zero);

                    // Dump recent GNW_SURF_SUSPECT records for correlation
                    for (int i = 0; i < 16; i++) {
                        if (g_suspects[i].seq != 0) {
                            patchlog_write("RENDER_PRESENT_ANOMALY_CONTEXT", "suspect_seq=%llu surfacePtr=%p dest=(%d,%d) copy=%dx%d sampleSurf0=%d pre=%ld post=%ld", g_suspects[i].seq, g_suspects[i].surfacePtr, g_suspects[i].destX, g_suspects[i].destY, g_suspects[i].copyW, g_suspects[i].copyH, g_suspects[i].sampleSurf0, g_suspects[i].preSurfaceNonZero, g_suspects[i].postSurfaceNonZero);
                        }
                    }

                    // Save presented pixels as a BMP for offline inspection (if we could
                    // read the surface). Save before destroying.
                    char path[256];
                    snprintf(path, sizeof(path), "/tmp/f1r-present-anom-%llu.bmp", anomaly_seq);
                    if (surf != NULL) {
                        SDL_SaveBMP(surf, path);
                        patchlog_write("RENDER_PRESENT_ANOMALY", "screenshot=%s", path);
                    }
                }

                SDL_DestroySurface(surf);
            }

            unsigned long long seq = ++g_seq;
            patchlog_write("RENDER_PRESENT_TOP_PIXELS", "seq=%llu pre=%ld present=%ld", seq, pre_texture_surface_non_zero, present_non_zero);
        }
    }
}

#if __APPLE__ && TARGET_OS_IOS
// Convert screen pixel coordinates to game logical coordinates
// This accounts for the custom dest rect used on iOS
bool iOS_screenToGameCoords(float screen_x, float screen_y, int* game_x, int* game_y)
{
    SDL_Log("iOS_screenToGameCoords: screen=(%.1f, %.1f)", screen_x, screen_y);

    if (!g_iOS_useCustomRect || g_iOS_destRect.w <= 0 || g_iOS_destRect.h <= 0) {
        // Fallback: direct mapping
        SDL_Log("iOS_screenToGameCoords: FALLBACK - no custom rect (useCustomRect=%d, destRect=%.0fx%.0f)",
            g_iOS_useCustomRect, g_iOS_destRect.w, g_iOS_destRect.h);
        *game_x = (int)screen_x;
        *game_y = (int)screen_y;
        return false;
    }

    SDL_Log("iOS_screenToGameCoords: destRect=(%.1f, %.1f, %.1f, %.1f) game=%dx%d",
        g_iOS_destRect.x, g_iOS_destRect.y, g_iOS_destRect.w, g_iOS_destRect.h,
        g_iOS_gameWidth, g_iOS_gameHeight);

    // Check if the point is within the dest rect
    float local_x = screen_x - g_iOS_destRect.x;
    float local_y = screen_y - g_iOS_destRect.y;

    SDL_Log("iOS_screenToGameCoords: local=(%.1f, %.1f)", local_x, local_y);

    // Scale from dest rect size to game resolution
    float scale_x = (float)g_iOS_gameWidth / g_iOS_destRect.w;
    float scale_y = (float)g_iOS_gameHeight / g_iOS_destRect.h;

    SDL_Log("iOS_screenToGameCoords: scale=(%.6f, %.6f)", scale_x, scale_y);

    int result_x = (int)(local_x * scale_x);
    int result_y = (int)(local_y * scale_y);

    SDL_Log("iOS_screenToGameCoords: pre-clamp result=(%d, %d)", result_x, result_y);

    // Clamp to game bounds
    if (result_x < 0) result_x = 0;
    if (result_x >= g_iOS_gameWidth) result_x = g_iOS_gameWidth - 1;
    if (result_y < 0) result_y = 0;
    if (result_y >= g_iOS_gameHeight) result_y = g_iOS_gameHeight - 1;

    *game_x = result_x;
    *game_y = result_y;

    // Return true if the point was within the dest rect
    bool in_bounds = (local_x >= 0 && local_x < g_iOS_destRect.w && local_y >= 0 && local_y < g_iOS_destRect.h);

    SDL_Log("iOS_screenToGameCoords: RESULT=(%d, %d) in_bounds=%d", result_x, result_y, in_bounds);

    return in_bounds;
}

// Convert window coordinates (points) to game coordinates on iOS
bool iOS_windowToGameCoords(float window_x, float window_y, int* game_x, int* game_y)
{
    float render_x = window_x;
    float render_y = window_y;

    if (gSdlRenderer != NULL) {
        if (!SDL_RenderCoordinatesFromWindow(gSdlRenderer, window_x, window_y, &render_x, &render_y)) {
            int window_w = 0;
            int window_h = 0;
            int window_pw = 0;
            int window_ph = 0;
            SDL_GetWindowSize(gSdlWindow, &window_w, &window_h);
            SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);

            float scale_x = (window_w > 0) ? (float)window_pw / (float)window_w : 1.0f;
            float scale_y = (window_h > 0) ? (float)window_ph / (float)window_h : 1.0f;
            render_x = window_x * scale_x;
            render_y = window_y * scale_y;
        }
    }

    return iOS_screenToGameCoords(render_x, render_y, game_x, game_y);
}

// Get the iOS dest rect for external use
void iOS_getDestRect(float* x, float* y, float* w, float* h)
{
    if (g_iOS_useCustomRect) {
        *x = g_iOS_destRect.x;
        *y = g_iOS_destRect.y;
        *w = g_iOS_destRect.w;
        *h = g_iOS_destRect.h;
    } else {
        *x = 0;
        *y = 0;
        *w = (float)g_iOS_gameWidth;
        *h = (float)g_iOS_gameHeight;
    }
}
#endif

} // namespace fallout
