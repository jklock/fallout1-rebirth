#ifndef FALLOUT_PLIB_GNW_INPUT_STATE_MACHINE_H
#define FALLOUT_PLIB_GNW_INPUT_STATE_MACHINE_H

#include <array>
#include <cstdint>
#include <deque>

namespace fallout {

enum class PointerDeviceKind {
    kFinger,
    kPencil,
};

enum class InputActionKind {
    kPointer,
    kWheel,
};

struct InputAction {
    InputActionKind kind;
    int x;
    int y;
    int buttons;
    int wheelX;
    int wheelY;
};

class InputStateMachine {
public:
    void reset();

    void onFingerDown(std::int64_t fingerId, int x, int y, bool inBounds, PointerDeviceKind deviceKind);
    void onFingerMove(std::int64_t fingerId, int x, int y, bool inBounds);
    void onFingerUp(std::int64_t fingerId, int x, int y, bool inBounds);

    void onSecondaryClick(int x, int y);
    void onMouseAbsolute(int x, int y, int buttons, int wheelX, int wheelY);
    void endFrame();

    bool popAction(InputAction* action);
    bool hasActivePointer() const;
    int getActiveTouchCount() const;

private:
    struct TouchContact {
        bool used = false;
        std::int64_t fingerId = 0;
        int x = 0;
        int y = 0;
        PointerDeviceKind deviceKind = PointerDeviceKind::kFinger;
    };

    static constexpr int kMaxTouches = 10;

    void emitCurrentPointerState(bool force);
    void emitPointerState(int x, int y, int buttons, bool force);
    void emitPendingReleaseNow();
    void getCurrentTarget(int* x, int* y, int* buttons) const;
    int findTouchIndex(std::int64_t fingerId) const;
    int findUnusedTouchIndex() const;
    int collectActiveTouchIndices(std::array<int, kMaxTouches>* indices) const;
    void removeTouchAtIndex(int index);

    std::array<TouchContact, kMaxTouches> _touches;
    std::deque<InputAction> _actions;

    int _currentX = 0;
    int _currentY = 0;
    int _currentButtons = 0;
    bool _hasCurrentPointer = false;

    bool _pendingRelease = false;
    bool _pendingReleaseArmed = false;
    int _pendingReleaseX = 0;
    int _pendingReleaseY = 0;
};

} // namespace fallout

#endif /* FALLOUT_PLIB_GNW_INPUT_STATE_MACHINE_H */
