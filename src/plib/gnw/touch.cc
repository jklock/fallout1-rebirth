#include "plib/gnw/touch.h"

#include <deque>

#include <SDL3/SDL.h>

#include "plib/gnw/input_state_machine.h"
#include "plib/gnw/svga.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IOS
#include "platform/ios/pencil.h"
#endif
#endif

namespace fallout {

namespace {

InputStateMachine gInputStateMachine;
std::deque<Gesture> gGestureCompatQueue;

bool convert_touch_to_logical(SDL_TouchFingerEvent* event, int* outX, int* outY)
{
    int windowW = 0;
    int windowH = 0;
    SDL_GetWindowSize(gSdlWindow, &windowW, &windowH);

    if (windowW <= 0 || windowH <= 0) {
        *outX = 0;
        *outY = 0;
        return false;
    }

    float windowX = event->x * static_cast<float>(windowW);
    float windowY = event->y * static_cast<float>(windowH);

#if defined(__APPLE__) && TARGET_OS_IOS
    return iOS_windowToGameCoords(windowX, windowY, outX, outY);
#else
    float logicalX = windowX;
    float logicalY = windowY;
    if (!SDL_RenderCoordinatesFromWindow(gSdlRenderer, windowX, windowY, &logicalX, &logicalY)) {
        *outX = static_cast<int>(event->x * static_cast<float>(screenGetWidth()));
        *outY = static_cast<int>(event->y * static_cast<float>(screenGetHeight()));
    } else {
        *outX = static_cast<int>(logicalX);
        *outY = static_cast<int>(logicalY);
    }

    if (*outX < 0) *outX = 0;
    if (*outY < 0) *outY = 0;
    if (*outX >= screenGetWidth()) *outX = screenGetWidth() - 1;
    if (*outY >= screenGetHeight()) *outY = screenGetHeight() - 1;

    return true;
#endif
}

PointerDeviceKind classify_pointer_device()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    if (pencil_is_touching()) {
        return PointerDeviceKind::kPencil;
    }

    if (pencil_is_active() && gInputStateMachine.getActiveTouchCount() == 0) {
        return PointerDeviceKind::kPencil;
    }
#endif
    return PointerDeviceKind::kFinger;
}

void push_compat_ended_gesture(int x, int y)
{
    Gesture gesture;
    gesture.type = kTap;
    gesture.state = kEnded;
    gesture.numberOfTouches = 1;
    gesture.x = x;
    gesture.y = y;
    gGestureCompatQueue.push_back(gesture);
}

} // namespace

void touch_handle_start(SDL_TouchFingerEvent* event)
{
    int x = 0;
    int y = 0;
    bool inBounds = convert_touch_to_logical(event, &x, &y);
    PointerDeviceKind kind = classify_pointer_device();
    gInputStateMachine.onFingerDown(static_cast<std::int64_t>(event->fingerID), x, y, inBounds, kind);
}

void touch_handle_move(SDL_TouchFingerEvent* event)
{
    int x = 0;
    int y = 0;
    bool inBounds = convert_touch_to_logical(event, &x, &y);
    gInputStateMachine.onFingerMove(static_cast<std::int64_t>(event->fingerID), x, y, inBounds);
}

void touch_handle_end(SDL_TouchFingerEvent* event)
{
    int x = 0;
    int y = 0;
    bool inBounds = convert_touch_to_logical(event, &x, &y);
    gInputStateMachine.onFingerUp(static_cast<std::int64_t>(event->fingerID), x, y, inBounds);
    push_compat_ended_gesture(x, y);
}

void touch_process_gesture()
{
    gInputStateMachine.endFrame();
}

bool touch_get_gesture(Gesture* gesture)
{
    if (gGestureCompatQueue.empty()) {
        return false;
    }

    *gesture = gGestureCompatQueue.front();
    gGestureCompatQueue.pop_front();
    return true;
}

bool touch_pop_mouse_event(TouchMouseEvent* event)
{
    InputAction action;
    if (!gInputStateMachine.popAction(&action)) {
        return false;
    }

    if (action.kind == InputActionKind::kWheel) {
        event->type = kTouchMouseEventWheel;
        event->x = 0;
        event->y = 0;
        event->buttons = 0;
        event->wheelX = action.wheelX;
        event->wheelY = action.wheelY;
    } else {
        event->type = kTouchMouseEventPointer;
        event->x = action.x;
        event->y = action.y;
        event->buttons = action.buttons;
        event->wheelX = 0;
        event->wheelY = 0;
    }

    return true;
}

void touch_submit_mouse_state(int absoluteX, int absoluteY, int buttons, int wheelX, int wheelY)
{
    gInputStateMachine.onMouseAbsolute(absoluteX, absoluteY, buttons, wheelX, wheelY);
}

void touch_enqueue_secondary_click(int x, int y)
{
    gInputStateMachine.onSecondaryClick(x, y);
    push_compat_ended_gesture(x, y);
}

bool touch_is_pointer_active()
{
    return gInputStateMachine.hasActivePointer();
}

void touch_reset()
{
    gInputStateMachine.reset();
    gGestureCompatQueue.clear();
}

} // namespace fallout
