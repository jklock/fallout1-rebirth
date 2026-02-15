#ifndef FALLOUT_PLIB_GNW_TOUCH_H
#define FALLOUT_PLIB_GNW_TOUCH_H

#include <SDL3/SDL.h>

namespace fallout {

enum GestureType {
    kUnrecognized,
    kTap,
    kLongPress,
    kPan,
};

enum GestureState {
    kPossible,
    kBegan,
    kChanged,
    kEnded,
};

struct Gesture {
    GestureType type;
    GestureState state;
    int numberOfTouches;
    int x;
    int y;
};

enum TouchMouseEventType {
    kTouchMouseEventPointer,
    kTouchMouseEventWheel,
};

struct TouchMouseEvent {
    TouchMouseEventType type;
    int x;
    int y;
    int buttons;
    int wheelX;
    int wheelY;
};

void touch_handle_start(SDL_TouchFingerEvent* event);
void touch_handle_move(SDL_TouchFingerEvent* event);
void touch_handle_end(SDL_TouchFingerEvent* event);
void touch_process_gesture();
bool touch_get_gesture(Gesture* gesture);
bool touch_pop_mouse_event(TouchMouseEvent* event);
void touch_submit_mouse_state(int absoluteX, int absoluteY, int buttons, int wheelX, int wheelY);
void touch_enqueue_secondary_click(int x, int y);
bool touch_is_pointer_active();
void touch_reset();

} // namespace fallout

#endif /* FALLOUT_PLIB_GNW_TOUCH_H */
