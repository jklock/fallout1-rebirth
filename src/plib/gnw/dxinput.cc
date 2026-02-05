#include "plib/gnw/dxinput.h"
#include "plib/gnw/debug.h"
#include "plib/gnw/mouse.h"
#include "plib/gnw/svga.h"
#include <SDL3/SDL.h>
#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IOS
#include "platform/ios/pencil.h"
#endif
#endif

namespace fallout {

static bool dxinput_mouse_init();
static void dxinput_mouse_exit();
static bool dxinput_keyboard_init();
static void dxinput_keyboard_exit();

static int gMouseWheelDeltaX = 0;
static int gMouseWheelDeltaY = 0;

#if defined(__APPLE__) && TARGET_OS_IOS
static bool last_input_was_mouse = false;
static int last_system_x = -1;
static int last_system_y = -1;
static Uint32 last_mouse_buttons = 0;
// Track button state from events since SDL_GetMouseState doesn't reflect touch-converted clicks
static bool left_button_down = false;
static bool right_button_down = false;
#endif

// 0x4E0400
bool dxinput_init()
{
    if (!SDL_InitSubSystem(SDL_INIT_EVENTS)) {
        return false;
    }

    if (!dxinput_mouse_init()) {
        goto err;
    }

    if (!dxinput_keyboard_init()) {
        goto err;
    }

    return true;

err:

    dxinput_mouse_exit();

    return false;
}

// 0x4E0478
void dxinput_exit()
{
    SDL_QuitSubSystem(SDL_INIT_EVENTS);
}

// 0x4E04E8
bool dxinput_acquire_mouse()
{
    return true;
}

// 0x4E0514
bool dxinput_unacquire_mouse()
{
    return true;
}

// 0x4E053C
bool dxinput_get_mouse_state(MouseData* mouseState)
{
    // CE: This function is sometimes called outside loops calling `get_input`
    // and subsequently `GNW95_process_message`, so mouse events might not be
    // handled by SDL yet.
    //
    // TODO: Move mouse events processing into `GNW95_process_message` and
    // update mouse position manually.
    SDL_PumpEvents();

#if defined(__APPLE__) && TARGET_OS_IOS
    static int log_count = 0;
    float system_x, system_y;
    SDL_MouseButtonFlags mouse_buttons = SDL_GetMouseState(&system_x, &system_y);
    if (log_count < 20 || (log_count % 100 == 0)) {
        SDL_Log("DXINPUT: SDL_GetMouseState raw=(%.1f,%.1f) buttons=0x%x",
                system_x, system_y, mouse_buttons);
    }
    log_count++;

    // SDL_GetMouseState returns coordinates in POINTS (logical), but
    // iOS_screenToGameCoords expects PIXELS. Get the scale factor.
    int window_w, window_h, window_pw, window_ph;
    SDL_GetWindowSize(gSdlWindow, &window_w, &window_h);
    SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);
    float scale_x = (float)window_pw / (float)window_w;
    float scale_y = (float)window_ph / (float)window_h;
    
    // Convert points to pixels
    float pixel_x = system_x * scale_x;
    float pixel_y = system_y * scale_y;

    bool mouse_activity = false;
    if (last_system_x == -1 && last_system_y == -1) {
        last_system_x = (int)pixel_x;
        last_system_y = (int)pixel_y;
        last_mouse_buttons = mouse_buttons;
    }

    if ((int)pixel_x != last_system_x || (int)pixel_y != last_system_y || mouse_buttons != last_mouse_buttons) {
        mouse_activity = true;
    }

    if (mouse_activity) {
        last_input_was_mouse = true;
    }

    last_system_x = (int)pixel_x;
    last_system_y = (int)pixel_y;
    last_mouse_buttons = mouse_buttons;

    if (last_input_was_mouse) {
        int game_x, game_y;
        mouse_get_position(&game_x, &game_y);

        // Use our custom iOS coordinate conversion that accounts for the dest rect
        int mapped_x, mapped_y;
        iOS_screenToGameCoords(pixel_x, pixel_y, &mapped_x, &mapped_y);

        int delta_x = mapped_x - game_x;
        int delta_y = mapped_y - game_y;
        
        if ((log_count - 1) < 20 || ((log_count - 1) % 100 == 0)) {
            SDL_Log("DXINPUT: pixel=(%.1f,%.1f) mapped=(%d,%d) cursor=(%d,%d) delta=(%d,%d)",
                    pixel_x, pixel_y, mapped_x, mapped_y, game_x, game_y, delta_x, delta_y);
        }

        if (mapped_x >= 0 && mapped_x < screenGetWidth() && mapped_y >= 0 && mapped_y < screenGetHeight()) {
            mouseState->x = delta_x;
            mouseState->y = delta_y;
        } else {
            mouseState->x = 0;
            mouseState->y = 0;
        }
    } else {
        mouseState->x = 0;
        mouseState->y = 0;
    }

    // Use tracked button state from events OR SDL button flags
    // Event tracking catches button presses, SDL flags provide backup
    bool left_down = left_button_down || (mouse_buttons & SDL_BUTTON_LMASK) != 0;
    bool right_down = right_button_down || (mouse_buttons & SDL_BUTTON_RMASK) != 0;
    mouseState->buttons[0] = left_down;
    mouseState->buttons[1] = right_down;
    mouseState->wheelX = gMouseWheelDeltaX;
    mouseState->wheelY = gMouseWheelDeltaY;
    gMouseWheelDeltaX = 0;
    gMouseWheelDeltaY = 0;
    return true;
#endif

    float rel_x, rel_y;
    SDL_MouseButtonFlags buttons = SDL_GetRelativeMouseState(&rel_x, &rel_y);
    mouseState->x = (int)rel_x;
    mouseState->y = (int)rel_y;
    mouseState->buttons[0] = (buttons & SDL_BUTTON_LMASK) != 0;
    mouseState->buttons[1] = (buttons & SDL_BUTTON_RMASK) != 0;
    mouseState->wheelX = gMouseWheelDeltaX;
    mouseState->wheelY = gMouseWheelDeltaY;
    gMouseWheelDeltaX = 0;
    gMouseWheelDeltaY = 0;
    return true;
}

// 0x4E05A8
bool dxinput_acquire_keyboard()
{
    return true;
}

// 0x4E05D4
bool dxinput_unacquire_keyboard()
{
    return true;
}

// 0x4E05FC
bool dxinput_flush_keyboard_buffer()
{
    SDL_FlushEvents(SDL_EVENT_KEY_DOWN, SDL_EVENT_TEXT_INPUT);
    return true;
}

// 0x4E0650
bool dxinput_read_keyboard_buffer(KeyboardData* keyboardData)
{
    return true;
}

// 0x4E070C
bool dxinput_mouse_init()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    return true;
#else
    return SDL_SetWindowRelativeMouseMode(gSdlWindow, true);
#endif
}

// 0x4E078C
void dxinput_mouse_exit()
{
}

// 0x4E07B8
bool dxinput_keyboard_init()
{
    return true;
}

// 0x4E0874
void dxinput_keyboard_exit()
{
}

void handleMouseEvent(SDL_Event* event)
{
    // Mouse movement and buttons are accumulated in SDL itself and will be
    // processed later in `mouseDeviceGetData` via `SDL_GetRelativeMouseState`.

    if (event->type == SDL_EVENT_MOUSE_WHEEL) {
        gMouseWheelDeltaX += (int)event->wheel.x;
        gMouseWheelDeltaY += (int)event->wheel.y;
    }
    
#if defined(__APPLE__) && TARGET_OS_IOS
    // Track button state from events for iOS
    if (event->type == SDL_EVENT_MOUSE_BUTTON_DOWN) {
        if (event->button.button == SDL_BUTTON_LEFT) {
            left_button_down = true;
        } else if (event->button.button == SDL_BUTTON_RIGHT) {
            right_button_down = true;
        }
    } else if (event->type == SDL_EVENT_MOUSE_BUTTON_UP) {
        if (event->button.button == SDL_BUTTON_LEFT) {
            left_button_down = false;
        } else if (event->button.button == SDL_BUTTON_RIGHT) {
            right_button_down = false;
        }
    }
#endif
}

void dxinput_notify_mouse()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    last_input_was_mouse = true;
    static int mouse_event_count = 0;
    if (mouse_event_count < 5) {
        debug_printf("iOS: Mouse event received (count=%d)\n", ++mouse_event_count);
    }
#endif
}

void dxinput_notify_touch()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    last_input_was_mouse = false;
    static int touch_event_count = 0;
    if (touch_event_count < 5) {
        debug_printf("iOS: Touch event received (count=%d)\n", ++touch_event_count);
    }
#endif
}

bool dxinput_is_using_mouse()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    return last_input_was_mouse;
#else
    return true;  // Non-iOS always uses mouse
#endif
}

} // namespace fallout
