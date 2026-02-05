#include "plib/gnw/svga.h"

#include <SDL3/SDL.h>

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

// screen rect
Rect scr_size;

// 0x6ACA18
ScreenBlitFunc* scr_blit = GNW95_ShowRect;

SDL_Window* gSdlWindow = NULL;
SDL_Surface* gSdlSurface = NULL;
SDL_Renderer* gSdlRenderer = NULL;
SDL_Texture* gSdlTexture = NULL;
SDL_Surface* gSdlTextureSurface = NULL;

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

    buf_to_buf(src + srcPitch * srcOffsetY + srcOffsetX,
        copyW,
        copyH,
        srcPitch,
        (unsigned char*)gSdlSurface->pixels + gSdlSurface->pitch * copyY + copyX,
        gSdlSurface->pitch);

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

    SDL_BlitSurface(gSdlSurface, &srcRect, gSdlTextureSurface, &destRect);
}

bool svga_init(VideoOptions* video_options)
{
    SDL_Log("svga_init: starting with %dx%d (scale=%d)", 
        video_options->width, video_options->height, video_options->scale);

    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");

    if (!SDL_InitSubSystem(SDL_INIT_VIDEO)) {
        SDL_Log("svga_init: SDL_InitSubSystem failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("svga_init: SDL video subsystem initialized");

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

    if (!SDL_SetRenderLogicalPresentation(gSdlRenderer, width, height, SDL_LOGICAL_PRESENTATION_LETTERBOX)) {
        SDL_Log("createRenderer: SDL_SetRenderLogicalPresentation failed: %s", SDL_GetError());
        return false;
    }
    SDL_Log("createRenderer: logical presentation set to %dx%d", width, height);

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

void handleWindowSizeChanged()
{
    destroyRenderer();
    createRenderer(screenGetWidth(), screenGetHeight());
}

void renderPresent()
{
    SDL_UpdateTexture(gSdlTexture, NULL, gSdlTextureSurface->pixels, gSdlTextureSurface->pitch);
    SDL_RenderClear(gSdlRenderer);
    SDL_RenderTexture(gSdlRenderer, gSdlTexture, NULL, NULL);
    SDL_RenderPresent(gSdlRenderer);
}

} // namespace fallout
