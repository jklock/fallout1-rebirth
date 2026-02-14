# Input Handling Deep Dive

> **Technical documentation for Fallout 1 Rebirth input system architecture**

This document provides a comprehensive technical overview of mouse, touch, and Apple Pencil input handling in Fallout 1 Rebirth. Understanding this architecture is essential for debugging input issues, adding new input features, or porting to new platforms.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Mouse Input](#mouse-input)
3. [Touch Input](#touch-input)
4. [Apple Pencil Support](#apple-pencil-support)
5. [Coordinate Systems](#coordinate-systems)
6. [Configuration](#configuration)
7. [Platform-Specific Details](#platform-specific-details)

---

## Architecture Overview

### Event Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SDL3 Event Loop                                    │
│                        (GNW95_process_message)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐     ┌─────────────────────┐     ┌─────────────────┐
│  SDL_EVENT_     │     │  SDL_EVENT_FINGER_  │     │  SDL_EVENT_KEY_ │
│  MOUSE_*        │     │  DOWN/MOTION/UP     │     │  DOWN/UP        │
└─────────────────┘     └─────────────────────┘     └─────────────────┘
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐     ┌─────────────────────┐     ┌─────────────────┐
│ handleMouseEvent│     │ touch_handle_*()    │     │GNW95_process_key│
│    (dxinput)    │     │    (touch.cc)       │     │   (input.cc)    │
└─────────────────┘     └─────────────────────┘     └─────────────────┘
         │                          │                          │
         │                          ▼                          │
         │              ┌─────────────────────┐                │
         │              │ touch_process_      │                │
         │              │ gesture()           │                │
         │              │ ┌─────────────────┐ │                │
         │              │ │ Gesture Queue   │ │                │
         │              │ └─────────────────┘ │                │
         │              └─────────────────────┘                │
         │                          │                          │
         └───────────┬──────────────┘                          │
                     ▼                                         │
         ┌─────────────────────┐                               │
         │   mouse_info()      │                               │
         │   (mouse.cc)        │                               │
         │ ┌─────────────────┐ │                               │
         │ │ mouse_x, mouse_y│ │                               │
         │ │ mouse_buttons   │ │                               │
         │ └─────────────────┘ │                               │
         └─────────────────────┘                               │
                     │                                         │
                     ▼                                         ▼
         ┌─────────────────────────────────────────────────────────────┐
         │                    Input Buffer (Ring)                       │
         │                  (input_buffer[40])                          │
         │            GNW_add_input_buffer() → get_input()             │
         └─────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
         ┌─────────────────────────────────────────────────────────────┐
         │                      Game Logic                              │
         │                  (get_input() consumers)                     │
         └─────────────────────────────────────────────────────────────┘
```

### Key Components

| File | Purpose |
|------|---------|
| [src/plib/gnw/input.cc](../src/plib/gnw/input.cc) | Main event loop, input buffer, key processing |
| [src/plib/gnw/mouse.cc](../src/plib/gnw/mouse.cc) | Mouse state, cursor rendering, gesture→mouse translation |
| [src/plib/gnw/touch.cc](../src/plib/gnw/touch.cc) | Touch event tracking, gesture recognition |
| [src/plib/gnw/dxinput.cc](../src/plib/gnw/dxinput.cc) | Low-level SDL input interface |
| [src/platform/ios/pencil.mm](../src/platform/ios/pencil.mm) | Apple Pencil detection (iOS only) |
| [src/plib/gnw/svga.cc](../src/plib/gnw/svga.cc) | Coordinate transformation, screen setup |

### Input Buffer

The input system uses a ring buffer for queuing input events:

```cpp
// Ring buffer of input events (input.cc)
static inputdata input_buffer[40];
static int input_get;  // Read index (-1 if empty)
static int input_put;  // Write index

typedef struct inputdata {
    int input;  // Key code or event ID
    int mx;     // Mouse X at event time
    int my;     // Mouse Y at event time
} inputdata;
```

Events are queued via `GNW_add_input_buffer()` and consumed via `get_input()` + `get_input_position()`.

---

## Mouse Input

### Event Handling

Mouse events are processed in `GNW95_process_message()` ([input.cc#L1103-L1125](../src/plib/gnw/input.cc#L1103)):

```cpp
case SDL_EVENT_MOUSE_MOTION:
    dxinput_notify_mouse();
    handleMouseEvent(&e);
    break;
case SDL_EVENT_MOUSE_BUTTON_DOWN:
    dxinput_notify_mouse();
    handleMouseEvent(&e);
    break;
case SDL_EVENT_MOUSE_BUTTON_UP:
    dxinput_notify_mouse();
    handleMouseEvent(&e);
    break;
case SDL_EVENT_MOUSE_WHEEL:
    dxinput_notify_mouse();
    handleMouseEvent(&e);
    break;
```

### Mouse State Structure

```cpp
// dxinput.h
typedef struct MouseData {
    int x;              // Relative X movement (or absolute on iOS)
    int y;              // Relative Y movement (or absolute on iOS)
    unsigned char buttons[2];  // [0]=left, [1]=right
    int wheelX;         // Horizontal scroll
    int wheelY;         // Vertical scroll
} MouseData;
```

### Button State Flags

```cpp
// mouse.h - Button state
#define MOUSE_STATE_LEFT_BUTTON_DOWN   0x01
#define MOUSE_STATE_RIGHT_BUTTON_DOWN  0x02

// Mouse events (edge-triggered)
#define MOUSE_EVENT_LEFT_BUTTON_DOWN    0x01
#define MOUSE_EVENT_RIGHT_BUTTON_DOWN   0x02
#define MOUSE_EVENT_LEFT_BUTTON_REPEAT  0x04
#define MOUSE_EVENT_RIGHT_BUTTON_REPEAT 0x08
#define MOUSE_EVENT_LEFT_BUTTON_UP      0x10
#define MOUSE_EVENT_RIGHT_BUTTON_UP     0x20
#define MOUSE_EVENT_WHEEL               0x40
```

### Cursor Management

The mouse cursor is rendered as a software sprite:

```cpp
// mouse.cc - Default cursor (8x8 pixels)
static unsigned char or_mask[MOUSE_DEFAULT_CURSOR_SIZE] = {
    // Color codes: 0=transparent, 1=white, 15=black
    1,  1,  1,  1,  1,  1,  1, 0,
    1, 15, 15, 15, 15, 15,  1, 0,
    1, 15, 15, 15, 15,  1,  1, 0,
    // ... (arrow cursor shape)
};
```

Key cursor functions:
- `mouse_show()` - Renders cursor to screen
- `mouse_hide()` - Removes cursor, triggers refresh
- `mouse_set_shape()` - Changes cursor appearance
- `mouse_clip()` - Constrains cursor to screen bounds

### macOS-Specific: Relative Mouse Mode

On macOS, SDL uses relative mouse mode for smooth cursor movement:

```cpp
// dxinput.cc - macOS uses relative mouse
bool dxinput_mouse_init()
{
#if defined(__APPLE__) && TARGET_OS_IOS
    return true;  // iOS: absolute positioning
#else
    return SDL_SetWindowRelativeMouseMode(gSdlWindow, true);  // macOS: relative
#endif
}
```

On macOS, `dxinput_get_mouse_state()` uses `SDL_GetRelativeMouseState()` to get movement deltas.

---

## Touch Input

### Touch Event Processing

Touch events flow through [touch.cc](../src/plib/gnw/touch.cc):

```cpp
void touch_handle_start(SDL_TouchFingerEvent* event);  // FINGER_DOWN
void touch_handle_move(SDL_TouchFingerEvent* event);   // FINGER_MOTION
void touch_handle_end(SDL_TouchFingerEvent* event);    // FINGER_UP
void touch_process_gesture();  // Called after all events processed
```

### Touch Data Structure

```cpp
// touch.cc - Per-finger tracking
struct Touch {
    bool used;
    SDL_FingerID fingerId;
    TouchLocation startLocation;
    Uint64 startTimestamp;    // Milliseconds
    TouchLocation currentLocation;
    Uint64 currentTimestamp;
    int phase;  // TOUCH_PHASE_BEGAN/MOVED/ENDED
};

static Touch touches[MAX_TOUCHES];  // MAX_TOUCHES = 10
```

### Gesture Recognition

The touch system recognizes three gesture types:

| Gesture | Recognition Criteria | Game Action |
|---------|---------------------|-------------|
| **Tap** | Touch duration < 75ms, minimal movement | Single-finger: click or move cursor; Two-finger: right-click; Three-finger: left-click |
| **Pan** | Movement > 4 pixels | Drag cursor or held-button drag |
| **Long Press** | Hold > 500ms with minimal movement | Right-click (examine/context menu) |

```cpp
// touch.cc - Recognition thresholds
#define TAP_MAXIMUM_DURATION        75   // ms
#define PAN_MINIMUM_MOVEMENT        4    // pixels
#define LONG_PRESS_MINIMUM_DURATION 500  // ms
```

### Gesture State Machine

```cpp
enum GestureType {
    kUnrecognized,
    kTap,
    kLongPress,
    kPan,
};

enum GestureState {
    kPossible,  // Initial state
    kBegan,     // Gesture started
    kChanged,   // Continuous gesture updated
    kEnded,     // Gesture completed
};
```

### Touch-to-Mouse Translation

Gestures are translated to mouse actions in `mouse_info()` ([mouse.cc#L427-L650](../src/plib/gnw/mouse.cc#L427)):

**Single-Finger Tap:**
```cpp
// Tap within click radius of cursor → click at cursor
// Tap outside radius → move cursor only (no click)
int radius = (40 * screen_width) / 640;  // Scaled radius
if (distance_sq < radius_sq) {
    mouse_simulate_input(0, 0, MOUSE_STATE_LEFT_BUTTON_DOWN);
    mouse_simulate_input(0, 0, 0);  // Release
} else {
    mouse_simulate_input(dx, dy, 0);  // Move only
}
```

**Two-Finger Tap → Right-Click:**
```cpp
mouse_simulate_input(0, 0, MOUSE_STATE_RIGHT_BUTTON_DOWN);
mouse_simulate_input(0, 0, 0);  // Release
```

**Pan Gesture → Drag:**
```cpp
if (pencil_dragging) {
    mouse_simulate_input(dx, dy, MOUSE_STATE_LEFT_BUTTON_DOWN);
} else {
    mouse_simulate_input(dx, dy, 0);  // Reposition only
}
```

### Two-Finger Scroll

Two-finger pan gestures generate mouse wheel events:

```cpp
gMouseWheelX = (prevx - gesture.x) / 2;
gMouseWheelY = (gesture.y - prevy) / 2;
if (gMouseWheelX != 0 || gMouseWheelY != 0) {
    mouse_buttons |= MOUSE_EVENT_WHEEL;
}
```

---

## Apple Pencil Support

> **iOS/iPadOS Only** — Apple Pencil support requires native iOS code because SDL cannot distinguish pencil from finger touch.

### Architecture

The pencil system uses a custom `UIGestureRecognizer` subclass that observes all touches without interfering with SDL:

```
┌─────────────────────────────────────────────────────────────────┐
│                        UIView (SDL Window)                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────────────────────┐  │
│  │  PencilObserver  │    │     UIPencilInteraction          │  │
│  │  (Gesture Rec.)  │    │     (Body Gestures)              │  │
│  │                  │    │                                  │  │
│  │ touchesBegan     │    │ pencilInteractionDidTap          │  │
│  │ touchesMoved     │    │ didReceiveSqueeze                │  │
│  │ touchesEnded     │    │                                  │  │
│  └──────────────────┘    └──────────────────────────────────┘  │
│           │                           │                         │
│           ▼                           ▼                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Global State Variables                         │  │
│  │  g_pencil_touching, g_last_touch_was_pencil              │  │
│  │  g_pencil_position, g_pencil_pressure                    │  │
│  │  g_pending_gesture                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Pencil Detection

The `PencilObserver` class checks `UITouch.type` to distinguish input sources:

```objc
// pencil.mm
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.type == UITouchTypePencil) {
            g_pencil_touching = YES;
            g_last_touch_was_pencil = YES;
            g_pencil_pressure = touch.force / touch.maximumPossibleForce;
        } else if (touch.type == UITouchTypeDirect) {
            g_last_touch_was_pencil = NO;  // Finger
        }
    }
    self.state = UIGestureRecognizerStateFailed;  // Don't consume
}
```

### Touch Types

```objc
typedef enum UITouchType : NSInteger {
    UITouchTypeDirect = 0,         // Finger
    UITouchTypeIndirect = 1,       // Remote/non-screen
    UITouchTypePencil = 2,         // Apple Pencil ✓
    UITouchTypeIndirectPointer = 3 // Mouse/trackpad
} UITouchType;
```

### Pencil Body Gestures

Apple Pencil 2nd generation and Pro support body gestures via `UIPencilInteraction`:

| Gesture | Pencil Models | iOS Version | Game Action |
|---------|--------------|-------------|-------------|
| Double-tap | 2nd Gen, Pro | iOS 12.1+ | Right-click |
| Squeeze | Pro only | iOS 17.5+ | Right-click |

```objc
// pencil.mm - UIPencilInteractionDelegate
- (void)pencilInteractionDidTap:(UIPencilInteraction *)interaction {
    g_pending_gesture = PENCIL_GESTURE_DOUBLE_TAP;
}

- (void)pencilInteraction:(UIPencilInteraction *)interaction 
       didReceiveSqueeze:(UIPencilInteractionSqueeze *)squeeze {
    g_pending_gesture = PENCIL_GESTURE_SQUEEZE;
}
```

### Pencil C API

```cpp
// pencil.h - Public interface
bool pencil_init(void* sdl_window);
void pencil_shutdown(void);
bool pencil_is_active(void);           // Last input was pencil?
bool pencil_is_touching(void);         // Currently touching?
bool pencil_get_position(int* x, int* y);
float pencil_get_pressure(void);       // 0.0 to 1.0
PencilGestureType pencil_poll_gesture(); // Check for body gesture
```

### Pencil vs Finger Behavior

| Feature | Finger Touch | Apple Pencil |
|---------|-------------|--------------|
| Tap click | Click radius check | Always click at tip position |
| Pan start | May just reposition cursor | Always initiates drag |
| Long press | Right-click | Right-click (configurable) |
| Precision | Lower | Pixel-perfect |

```cpp
// mouse.cc - Pencil tap always clicks at exact position
if (pencil_active) {
    mouse_simulate_input(dx, dy, 0);  // Move to tip
    mouse_simulate_input(0, 0, MOUSE_STATE_LEFT_BUTTON_DOWN);
    mouse_simulate_input(0, 0, 0);  // Release
}
```

### Pressure Sensitivity

While pressure data is captured, it is not currently used for gameplay. The pressure value (0.0-1.0) is available via `pencil_get_pressure()` for future enhancements.

---

## Coordinate Systems

### Overview

The input system must handle multiple coordinate spaces:

```
┌──────────────────────────────────────────────────────────────────┐
│                        Screen Coordinates                         │
│                    (iOS: Pixels, macOS: Points)                   │
│                                                                   │
│    ┌────────────────────────────────────────────────────────┐    │
│    │               Window Coordinates                        │    │
│    │              (SDL Window Space)                         │    │
│    │                                                         │    │
│    │    ┌──────────────────────────────────────────────┐    │    │
│    │    │           Game Render Area                    │    │    │
│    │    │          (Dest Rect / Logical)                │    │    │
│    │    │                                               │    │    │
│    │    │    ┌────────────────────────────────────┐    │    │    │
│    │    │    │      Game Coordinates              │    │    │    │
│    │    │    │      (640x480 or configured)       │    │    │    │
│    │    │    │                                    │    │    │    │
│    │    │    │   mouse_x, mouse_y live here      │    │    │    │
│    │    │    │                                    │    │    │    │
│    │    │    └────────────────────────────────────┘    │    │    │
│    │    │                                               │    │    │
│    │    │         (Letterbox/Pillarbox bars)           │    │    │
│    │    └──────────────────────────────────────────────┘    │    │
│    │                                                         │    │
│    └────────────────────────────────────────────────────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Touch Coordinate Conversion

Touch events arrive in normalized coordinates (0.0-1.0) and must be converted to game coordinates:

```cpp
// touch.cc - convert_touch_to_logical()
static void convert_touch_to_logical(SDL_TouchFingerEvent* event, int* out_x, int* out_y)
{
    // Step 1: Get window pixel dimensions
    int window_pw, window_ph;
    SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);
    
    // Step 2: Convert normalized (0...1) to pixels
    float pixel_x = event->x * window_pw;
    float pixel_y = event->y * window_ph;
    
#if __APPLE__ && TARGET_OS_IOS
    // Step 3 (iOS): Use custom dest rect conversion
    iOS_screenToGameCoords(pixel_x, pixel_y, out_x, out_y);
#else
    // Step 3 (macOS): Use SDL render coordinate conversion
    float logical_x, logical_y;
    SDL_RenderCoordinatesFromWindow(gSdlRenderer, pixel_x, pixel_y, 
                                     &logical_x, &logical_y);
    *out_x = static_cast<int>(logical_x);
    *out_y = static_cast<int>(logical_y);
#endif
}
```

### iOS Custom Dest Rect

On iOS, we manually calculate the game content rectangle within the fullscreen window:

```cpp
// svga.cc - iOS destination rect calculation
float game_aspect = (float)g_iOS_gameWidth / (float)g_iOS_gameHeight;  // 4:3
float sdl_aspect = (float)sdl_w / (float)sdl_h;

if (sdl_aspect > game_aspect) {
    // Wider than game: pillarbox (bars on sides)
    int content_w = (int)(sdl_h * game_aspect);
    g_iOS_destRect.x = (sdl_w - content_w) / 2.0f;
    g_iOS_destRect.y = 0;
    g_iOS_destRect.w = (float)content_w;
    g_iOS_destRect.h = (float)sdl_h;
} else {
    // Taller than game: letterbox (bars top/bottom)
    int content_h = (int)(sdl_w / game_aspect);
    g_iOS_destRect.x = 0;
    g_iOS_destRect.y = (sdl_h - content_h) / 2.0f;
    g_iOS_destRect.w = (float)sdl_w;
    g_iOS_destRect.h = (float)content_h;
}
```

### iOS Coordinate Conversion Function

```cpp
// svga.cc - Convert screen pixels to game coordinates
bool iOS_screenToGameCoords(float screen_x, float screen_y, int* game_x, int* game_y)
{
    // Check if touch is within game content area
    if (screen_x < g_iOS_destRect.x || 
        screen_x >= g_iOS_destRect.x + g_iOS_destRect.w ||
        screen_y < g_iOS_destRect.y || 
        screen_y >= g_iOS_destRect.y + g_iOS_destRect.h) {
        return false;  // Outside game area
    }
    
    // Convert to game coordinates
    *game_x = (int)((screen_x - g_iOS_destRect.x) * g_iOS_gameWidth / g_iOS_destRect.w);
    *game_y = (int)((screen_y - g_iOS_destRect.y) * g_iOS_gameHeight / g_iOS_destRect.h);
    
    return true;
}
```

### Touch Coordinate Fix History

The iOS touch coordinate system required several fixes:

1. **Points vs Pixels**: SDL reports positions in points, but touch events need pixels
2. **Dest Rect Offset**: Touch coordinates must account for letterbox/pillarbox offset
3. **Scale Factor**: High-DPI displays require proper scaling between window and pixel coordinates

```cpp
// dxinput.cc - iOS coordinate scaling
int window_w, window_h, window_pw, window_ph;
SDL_GetWindowSize(gSdlWindow, &window_w, &window_h);
SDL_GetWindowSizeInPixels(gSdlWindow, &window_pw, &window_ph);
float scale_x = (float)window_pw / (float)window_w;
float scale_y = (float)window_ph / (float)window_h;

// Convert points to pixels
float pixel_x = system_x * scale_x;
float pixel_y = system_y * scale_y;
```

---

## Configuration

### f1_res.ini Settings

```ini
[INPUT]
; CLICK_OFFSET_X: Horizontal click position adjustment in game pixels
; Positive = shift clicks RIGHT, Negative = shift clicks LEFT
; Default: 0 (macOS), 0 (iOS)
CLICK_OFFSET_X=0

; CLICK_OFFSET_Y: Vertical click position adjustment in game pixels
; Positive = shift clicks DOWN, Negative = shift clicks UP
; Default: 0 (macOS), 0 (iOS)
CLICK_OFFSET_Y=0

; CLICK_OFFSET_MOUSE_X/Y: Mouse/trackpad-specific calibration
CLICK_OFFSET_MOUSE_X=0
CLICK_OFFSET_MOUSE_Y=0
```

### Click Offset Calibration

The `CLICK_OFFSET_X` and `CLICK_OFFSET_Y` settings allow calibrating where clicks register relative to the cursor tip. This is loaded during `GNW_mouse_init()` and applied in the `mouse_click_in()` function.

**Why iOS may need offset**: device/setup-specific touch alignment can vary, so offsets are available for calibration when needed.

**How to calibrate**:
1. If clicks seem to miss their target consistently in one direction, adjust the offset
2. Positive X shifts clicks right, negative shifts left
3. Positive Y shifts clicks down, negative shifts up
4. Values are in game pixels (at 640x480 base resolution)

### Apple Pencil Configuration

Apple Pencil behavior can be configured via `game_config`:

```cpp
// Configuration key for pencil right-click
GAME_CONFIG_PENCIL_RIGHT_CLICK_KEY

// Usage in input.cc
int pencil_right_click_enabled = 1;
config_get_value(&game_config, GAME_CONFIG_INPUT_KEY, 
                 GAME_CONFIG_PENCIL_RIGHT_CLICK_KEY, 
                 &pencil_right_click_enabled);
```

When `pencil_right_click` is disabled:
- Pencil long-press behaves as left-click drag (precise mode)
- Body gestures (double-tap, squeeze) are ignored

### Mouse Sensitivity

```cpp
// mouse.cc - Sensitivity control
static double mouse_sensitivity = 1.0;

void mouse_set_sensitivity(double value);
double mouse_get_sensitivity();

// Applied in mouse_info()
x = (int)(x * mouse_sensitivity);
y = (int)(y * mouse_sensitivity);
```

---

## Platform-Specific Details

### macOS

| Feature | Implementation |
|---------|---------------|
| Mouse mode | Relative (SDL captures cursor) |
| Cursor | Software-rendered sprite |
| Trackpad | Treated as mouse |
| F-keys | Standard keyboard mapping |

### iOS/iPadOS

| Feature | Implementation |
|---------|---------------|
| Mouse mode | Absolute positioning with trackpad/mouse |
| Touch input | Gesture recognition → mouse simulation |
| Apple Pencil | Native iOS detection + body gestures |
| F-keys | Cmd+Number emulation (Cmd+1 → F1, etc.) |
| Status bar | Hidden via `SDL_WINDOW_BORDERLESS` |

### iOS F-Key Emulation

iPad keyboards lack function keys, so Cmd+Number combinations are mapped:

```cpp
// input.cc - iPadOS F-key mapping
SDL_Keymod modState = SDL_GetModState();
if ((modState & SDL_KMOD_GUI) != 0) {
    switch (data->key) {
    case SDL_SCANCODE_1: data->key = SDL_SCANCODE_F1; break;
    case SDL_SCANCODE_2: data->key = SDL_SCANCODE_F2; break;
    // ... through F7
    case SDL_SCANCODE_0: data->key = SDL_SCANCODE_F10; break;
    case SDL_SCANCODE_MINUS: data->key = SDL_SCANCODE_F11; break;
    case SDL_SCANCODE_EQUALS: data->key = SDL_SCANCODE_F12; break;
    }
}
```

### Input Mode Detection (iOS)

The system tracks whether the last input was mouse/trackpad or touch:

```cpp
// dxinput.cc
static bool last_input_was_mouse = false;

void dxinput_notify_mouse() {
    last_input_was_mouse = true;
}

void dxinput_notify_touch() {
    last_input_was_mouse = false;
}

bool dxinput_is_using_mouse() {
    return last_input_was_mouse;
}
```

This allows `mouse_info()` to choose the appropriate input path:
- Mouse mode: Uses `dxinput_get_mouse_state()` directly
- Touch mode: Processes gesture queue via `touch_get_gesture()`

---

## Debugging Tips

### Enable Input Logging

Input events are logged via `SDL_Log()`. Look for these prefixes:
- `INPUT:` - Raw SDL events
- `TOUCH START/END:` - Touch tracking
- `TAP GESTURE:` - Recognized tap
- `GESTURE:` - Gesture processing
- `DXINPUT:` - Mouse state polling

### Common Issues

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| Touch doesn't click | Tap outside click radius | Move cursor first, then tap |
| Cursor jumps | Coordinate conversion error | Check dest rect calculation |
| No pencil detection | Pencil init failed | Verify SDL window properties |
| Wrong button events | Button state desync | Check event tracking in dxinput.cc |

### Coordinate Debugging

Add logging to trace coordinate conversion:
```cpp
SDL_Log("Touch: raw=(%.3f,%.3f) pixels=(%.0f,%.0f) game=(%d,%d)",
        event->x, event->y, pixel_x, pixel_y, *out_x, *out_y);
```

---

## Proof of Work

**Timestamp:** February 5, 2026

**Files Read to Create This Document:**
- [src/plib/gnw/input.cc](../src/plib/gnw/input.cc) - Main input event loop, key processing
- [src/plib/gnw/input.h](../src/plib/gnw/input.h) - Input function declarations
- [src/plib/gnw/mouse.cc](../src/plib/gnw/mouse.cc) - Mouse state, cursor, gesture translation
- [src/plib/gnw/mouse.h](../src/plib/gnw/mouse.h) - Mouse constants and API
- [src/plib/gnw/touch.cc](../src/plib/gnw/touch.cc) - Touch event tracking and gesture recognition
- [src/plib/gnw/touch.h](../src/plib/gnw/touch.h) - Gesture types and structures
- [src/plib/gnw/dxinput.cc](../src/plib/gnw/dxinput.cc) - Low-level SDL input, iOS coordinate handling
- [src/plib/gnw/dxinput.h](../src/plib/gnw/dxinput.h) - Input data structures
- [src/plib/gnw/svga.cc](../src/plib/gnw/svga.cc) - Screen setup, iOS dest rect, coordinate conversion
- [src/plib/gnw/svga.h](../src/plib/gnw/svga.h) - Screen API including iOS coordinate functions
- [src/platform/ios/pencil.h](../src/platform/ios/pencil.h) - Apple Pencil C API
- [src/platform/ios/pencil.mm](../src/platform/ios/pencil.mm) - Native iOS pencil implementation
- [development/archive/applepencil/APPLE_PENCIL.md](../development/archive/applepencil/APPLE_PENCIL.md) - Pencil implementation history
- [gameconfig/ios/f1_res.ini](../gameconfig/ios/f1_res.ini) - iOS configuration reference

**Summary of What Was Documented:**
1. **Architecture Overview** - Complete event flow from SDL through game logic, including diagrams
2. **Mouse Input** - Event handling, state structures, button flags, cursor management, macOS relative mode
3. **Touch Input** - Event processing, gesture recognition (tap/pan/long-press), touch-to-mouse translation, multi-finger gestures
4. **Apple Pencil Support** - Native iOS detection via UITouch.type, body gestures (double-tap/squeeze), pencil vs finger behavior differences, pressure API
5. **Coordinate Systems** - Screen/window/game coordinate spaces, iOS dest rect calculation, touch coordinate conversion with fixes
6. **Configuration** - f1_res.ini options, pencil right-click toggle, mouse sensitivity
7. **Platform Details** - macOS vs iOS differences, F-key emulation, input mode detection
