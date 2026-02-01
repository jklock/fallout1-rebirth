// clang-format off
#ifndef FALLOUT_PLATFORM_IOS_PENCIL_H_
#define FALLOUT_PLATFORM_IOS_PENCIL_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @file pencil.h
 * @brief Apple Pencil detection and gesture handling for iOS/iPadOS
 *
 * This module provides native iOS integration for Apple Pencil support,
 * including detection of pencil vs finger touch, and handling of pencil-specific
 * gestures like double-tap and squeeze.
 *
 * SDL2 cannot distinguish Apple Pencil from finger touch, so we need native
 * iOS code to query UITouch.type and register UIPencilInteraction.
 */

// Pencil gesture event types
typedef enum {
    PENCIL_GESTURE_NONE = 0,
    PENCIL_GESTURE_DOUBLE_TAP = 1,  // Double-tap on pencil body (2nd gen, Pro)
    PENCIL_GESTURE_SQUEEZE = 2      // Squeeze gesture (Pro only, iOS 17.5+)
} PencilGestureType;

/**
 * Initialize Apple Pencil detection and gesture handling.
 * Must be called after SDL window is created.
 *
 * @param sdl_window Pointer to SDL_Window*
 * @return true if initialization succeeded, false otherwise
 */
bool pencil_init(void* sdl_window);

/**
 * Shutdown pencil detection and cleanup resources.
 */
void pencil_shutdown(void);

/**
 * Check if the last touch input was from Apple Pencil.
 * Call this at the start of touch event handling to determine input type.
 *
 * @return true if last touch was Apple Pencil, false if finger or unknown
 */
bool pencil_is_active(void);

/**
 * Check if pencil is currently touching the screen.
 *
 * @return true if Apple Pencil is currently in contact with screen
 */
bool pencil_is_touching(void);

/**
 * Get the current pencil position (if touching).
 *
 * @param x Output: x coordinate in screen coordinates
 * @param y Output: y coordinate in screen coordinates
 * @return true if pencil is currently touching and position was retrieved
 */
bool pencil_get_position(int* x, int* y);

/**
 * Get pencil pressure (0.0 to 1.0).
 *
 * @return Pressure value, or 0.0 if not a pencil or not touching
 */
float pencil_get_pressure(void);

/**
 * Poll for pencil gesture events (double-tap, squeeze).
 * Returns the type of gesture if one occurred since last call,
 * then clears the pending gesture.
 *
 * These gestures occur on the pencil body, not on the screen,
 * so they should trigger actions at the current cursor position.
 *
 * @return Gesture type, or PENCIL_GESTURE_NONE if no pending gesture
 */
PencilGestureType pencil_poll_gesture(void);

/**
 * Update pencil position tracking.
 * Called internally when touch events are processed.
 *
 * @param x Screen x coordinate
 * @param y Screen y coordinate
 */
void pencil_update_position(float x, float y);

#ifdef __cplusplus
}
#endif

#endif /* FALLOUT_PLATFORM_IOS_PENCIL_H_ */
// clang-format on
