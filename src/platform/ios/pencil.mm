// clang-format off
/**
 * @file pencil.mm
 * @brief Apple Pencil native iOS implementation
 *
 * This file provides native iOS integration for Apple Pencil support:
 * - Detection of Apple Pencil vs finger touch using UITouch.type
 * - UIPencilInteraction for double-tap (2nd gen+) and squeeze (Pro) gestures
 *
 * SDL2 treats all touch input identically, so we use a custom gesture recognizer
 * to observe touches without interfering with SDL's handling.
 */

#import <UIKit/UIKit.h>
#import <SDL3/SDL.h>
#import "pencil.h"

#if TARGET_OS_IOS

// =============================================================================
// Global State
// =============================================================================

static BOOL g_pencil_touching = NO;
static BOOL g_last_touch_was_pencil = NO;
static CGPoint g_pencil_position = CGPointZero;
static CGFloat g_pencil_pressure = 0.0;
static UIView *g_tracked_view = nil;
static PencilGestureType g_pending_gesture = PENCIL_GESTURE_NONE;

// =============================================================================
// PencilObserver - Custom gesture recognizer to observe all touches
// =============================================================================

/**
 * Custom gesture recognizer that observes all touches without interfering
 * with SDL's touch handling. We use this to detect UITouch.type.
 */
@interface PencilObserver : UIGestureRecognizer
@end

@implementation PencilObserver

- (instancetype)init {
    self = [super initWithTarget:nil action:nil];
    if (self) {
        // We never "recognize" - just observe all touches
        self.cancelsTouchesInView = NO;
        self.delaysTouchesBegan = NO;
        self.delaysTouchesEnded = NO;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.type == UITouchTypePencil) {
            g_pencil_touching = YES;
            g_last_touch_was_pencil = YES;
            g_pencil_position = [touch locationInView:g_tracked_view];
            if (touch.maximumPossibleForce > 0) {
                g_pencil_pressure = touch.force / touch.maximumPossibleForce;
            } else {
                g_pencil_pressure = 0.0;
            }
        } else if (touch.type == UITouchTypeDirect) {
            // Finger touch
            g_last_touch_was_pencil = NO;
        }
        // UITouchTypeIndirectPointer (trackpad/mouse) is handled separately by SDL
    }
    // Always fail to avoid interfering with other recognizers
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.type == UITouchTypePencil) {
            g_pencil_position = [touch locationInView:g_tracked_view];
            if (touch.maximumPossibleForce > 0) {
                g_pencil_pressure = touch.force / touch.maximumPossibleForce;
            }
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.type == UITouchTypePencil) {
            g_pencil_touching = NO;
            g_pencil_pressure = 0.0;
            // Keep g_last_touch_was_pencil = YES so we know the last input was pencil
        }
    }
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    g_pencil_touching = NO;
    g_pencil_pressure = 0.0;
    self.state = UIGestureRecognizerStateFailed;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return NO;  // Never prevent other recognizers
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    return NO;  // Can't be prevented
}

@end

// =============================================================================
// PencilInteractionHandler - UIPencilInteraction delegate for body gestures
// =============================================================================

/**
 * Delegate for UIPencilInteraction to handle double-tap and squeeze gestures
 * that occur on the pencil body (not on screen).
 */
API_AVAILABLE(ios(12.1))
@interface PencilInteractionHandler : NSObject <UIPencilInteractionDelegate>
@end

@implementation PencilInteractionHandler

- (void)pencilInteractionDidTap:(UIPencilInteraction *)interaction API_AVAILABLE(ios(12.1)) {
    // Double-tap on pencil body (2nd gen and Pro)
    // This should trigger right-click at current cursor position
    g_pending_gesture = PENCIL_GESTURE_DOUBLE_TAP;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 175000
- (void)pencilInteraction:(UIPencilInteraction *)interaction 
       didReceiveSqueeze:(UIPencilInteractionSqueeze *)squeeze API_AVAILABLE(ios(17.5)) {
    // Squeeze gesture (Pro only)
    // This should trigger right-click at current cursor position
    g_pending_gesture = PENCIL_GESTURE_SQUEEZE;
}
#endif

@end

// =============================================================================
// Static objects
// =============================================================================

static PencilObserver *g_pencil_observer = nil;
static PencilInteractionHandler *g_interaction_handler API_AVAILABLE(ios(12.1)) = nil;
static UIPencilInteraction *g_pencil_interaction API_AVAILABLE(ios(12.1)) = nil;

// =============================================================================
// Public C API Implementation
// =============================================================================

bool pencil_init(void* sdl_window) {
    if (!sdl_window) {
        return false;
    }
    
    // SDL3: Use properties to get native window
    SDL_PropertiesID props = SDL_GetWindowProperties((SDL_Window*)sdl_window);
    if (props == 0) {
        return false;
    }
    
    UIWindow *window = (__bridge UIWindow*)SDL_GetPointerProperty(props, SDL_PROP_WINDOW_UIKIT_WINDOW_POINTER, NULL);
    if (!window) {
        return false;
    }
    
    UIView *view = window.rootViewController.view;
    if (!view) {
        return false;
    }
    
    g_tracked_view = view;
    
    // Add our pencil observer gesture recognizer
    g_pencil_observer = [[PencilObserver alloc] init];
    [view addGestureRecognizer:g_pencil_observer];
    
    // Add UIPencilInteraction for double-tap and squeeze gestures (iOS 12.1+)
    if (@available(iOS 12.1, *)) {
        g_interaction_handler = [[PencilInteractionHandler alloc] init];
        g_pencil_interaction = [[UIPencilInteraction alloc] init];
        g_pencil_interaction.delegate = g_interaction_handler;
        [view addInteraction:g_pencil_interaction];
    }
    
    return true;
}

void pencil_shutdown(void) {
    // UIKit operations must be performed on the main thread
    // This function may be called from background threads during app termination
    void (^shutdownBlock)(void) = ^{
        // Remove UIPencilInteraction
        if (@available(iOS 12.1, *)) {
            if (g_pencil_interaction && g_tracked_view) {
                [g_tracked_view removeInteraction:g_pencil_interaction];
            }
            g_pencil_interaction = nil;
            g_interaction_handler = nil;
        }
        
        // Remove gesture recognizer
        if (g_pencil_observer && g_tracked_view) {
            [g_tracked_view removeGestureRecognizer:g_pencil_observer];
        }
        g_pencil_observer = nil;
        g_tracked_view = nil;
        
        // Reset state
        g_pencil_touching = NO;
        g_last_touch_was_pencil = NO;
        g_pencil_position = CGPointZero;
        g_pencil_pressure = 0.0;
        g_pending_gesture = PENCIL_GESTURE_NONE;
    };
    
    if ([NSThread isMainThread]) {
        shutdownBlock();
    } else {
        // During app termination, we can't use dispatch_sync as it may deadlock
        // Use dispatch_async and don't wait - the app is terminating anyway
        dispatch_async(dispatch_get_main_queue(), shutdownBlock);
    }
}

bool pencil_is_active(void) {
    return g_last_touch_was_pencil;
}

bool pencil_is_touching(void) {
    return g_pencil_touching;
}

bool pencil_get_position(int* x, int* y) {
    if (!g_pencil_touching) {
        return false;
    }
    if (x) *x = (int)g_pencil_position.x;
    if (y) *y = (int)g_pencil_position.y;
    return true;
}

float pencil_get_pressure(void) {
    return (float)g_pencil_pressure;
}

PencilGestureType pencil_poll_gesture(void) {
    PencilGestureType gesture = g_pending_gesture;
    g_pending_gesture = PENCIL_GESTURE_NONE;
    return gesture;
}

void pencil_update_position(float x, float y) {
    g_pencil_position = CGPointMake(x, y);
}

#else // Not iOS

// =============================================================================
// Stub implementations for non-iOS platforms
// =============================================================================

bool pencil_init(void* sdl_window) {
    (void)sdl_window;
    return false;
}

void pencil_shutdown(void) {
}

bool pencil_is_active(void) {
    return false;
}

bool pencil_is_touching(void) {
    return false;
}

bool pencil_get_position(int* x, int* y) {
    (void)x;
    (void)y;
    return false;
}

float pencil_get_pressure(void) {
    return 0.0f;
}

PencilGestureType pencil_poll_gesture(void) {
    return PENCIL_GESTURE_NONE;
}

void pencil_update_position(float x, float y) {
    (void)x;
    (void)y;
}

#endif // TARGET_OS_IOS
// clang-format on
