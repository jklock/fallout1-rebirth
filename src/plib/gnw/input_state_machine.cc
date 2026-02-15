#include "plib/gnw/input_state_machine.h"

#include <algorithm>

#include "plib/gnw/mouse.h"

namespace fallout {

void InputStateMachine::reset()
{
    _actions.clear();

    if (_currentButtons != 0) {
        _actions.push_back({ InputActionKind::kPointer, _currentX, _currentY, 0, 0, 0 });
    }

    _touches = {};
    _currentButtons = 0;
    _currentX = 0;
    _currentY = 0;
    _hasCurrentPointer = false;
    _pendingRelease = false;
    _pendingReleaseArmed = false;
    _pendingReleaseX = 0;
    _pendingReleaseY = 0;
}

void InputStateMachine::onFingerDown(std::int64_t fingerId, int x, int y, bool inBounds, PointerDeviceKind deviceKind)
{
    if (!inBounds) {
        return;
    }

    if (_pendingRelease) {
        emitPendingReleaseNow();
    }

    int index = findTouchIndex(fingerId);
    if (index == -1) {
        index = findUnusedTouchIndex();
    }
    if (index == -1) {
        return;
    }

    TouchContact& touch = _touches[index];
    touch.used = true;
    touch.fingerId = fingerId;
    touch.x = x;
    touch.y = y;
    touch.deviceKind = deviceKind;

    emitCurrentPointerState(true);
}

void InputStateMachine::onFingerMove(std::int64_t fingerId, int x, int y, bool inBounds)
{
    int index = findTouchIndex(fingerId);
    if (index == -1) {
        return;
    }

    TouchContact& touch = _touches[index];
    if (inBounds) {
        touch.x = x;
        touch.y = y;
    }

    emitCurrentPointerState(false);
}

void InputStateMachine::onFingerUp(std::int64_t fingerId, int x, int y, bool inBounds)
{
    int index = findTouchIndex(fingerId);
    if (index == -1) {
        return;
    }

    if (inBounds) {
        _touches[index].x = x;
        _touches[index].y = y;
    }

    const int releaseX = _touches[index].x;
    const int releaseY = _touches[index].y;
    removeTouchAtIndex(index);

    if (getActiveTouchCount() == 0) {
        if (_currentButtons != 0) {
            _pendingRelease = true;
            _pendingReleaseArmed = false;
            _pendingReleaseX = releaseX;
            _pendingReleaseY = releaseY;
            _currentX = releaseX;
            _currentY = releaseY;
            _hasCurrentPointer = true;
        }
        return;
    }

    emitCurrentPointerState(true);
}

void InputStateMachine::onSecondaryClick(int x, int y)
{
    if (hasActivePointer()) {
        return;
    }

    _actions.push_back({ InputActionKind::kPointer, x, y, MOUSE_STATE_RIGHT_BUTTON_DOWN, 0, 0 });
    _actions.push_back({ InputActionKind::kPointer, x, y, 0, 0, 0 });
}

void InputStateMachine::onMouseAbsolute(int x, int y, int buttons, int wheelX, int wheelY)
{
    if (hasActivePointer()) {
        return;
    }

    emitPointerState(x, y, buttons, true);

    if (wheelX != 0 || wheelY != 0) {
        _actions.push_back({ InputActionKind::kWheel, 0, 0, 0, wheelX, wheelY });
    }
}

void InputStateMachine::endFrame()
{
    if (_pendingRelease) {
        if (_pendingReleaseArmed) {
            emitPointerState(_pendingReleaseX, _pendingReleaseY, 0, true);
            _pendingRelease = false;
            _pendingReleaseArmed = false;
            return;
        }

        _pendingReleaseArmed = true;
        return;
    }

    if (getActiveTouchCount() > 0) {
        // Keep legacy mouse repeat semantics deterministic while dragging.
        emitCurrentPointerState(true);
    }
}

bool InputStateMachine::popAction(InputAction* action)
{
    if (_actions.empty()) {
        return false;
    }

    *action = _actions.front();
    _actions.pop_front();
    return true;
}

bool InputStateMachine::hasActivePointer() const
{
    return getActiveTouchCount() > 0 || _pendingRelease;
}

int InputStateMachine::getActiveTouchCount() const
{
    int count = 0;
    for (const TouchContact& touch : _touches) {
        if (touch.used) {
            count++;
        }
    }
    return count;
}

void InputStateMachine::emitCurrentPointerState(bool force)
{
    int x = 0;
    int y = 0;
    int buttons = 0;
    getCurrentTarget(&x, &y, &buttons);
    emitPointerState(x, y, buttons, force);
}

void InputStateMachine::emitPointerState(int x, int y, int buttons, bool force)
{
    if (!force && _hasCurrentPointer && x == _currentX && y == _currentY && buttons == _currentButtons) {
        return;
    }

    _currentX = x;
    _currentY = y;
    _currentButtons = buttons;
    _hasCurrentPointer = true;

    _actions.push_back({ InputActionKind::kPointer, x, y, buttons, 0, 0 });
}

void InputStateMachine::emitPendingReleaseNow()
{
    if (!_pendingRelease) {
        return;
    }

    emitPointerState(_pendingReleaseX, _pendingReleaseY, 0, true);
    _pendingRelease = false;
    _pendingReleaseArmed = false;
}

void InputStateMachine::getCurrentTarget(int* x, int* y, int* buttons) const
{
    std::array<int, kMaxTouches> active{};
    int activeCount = collectActiveTouchIndices(&active);

    if (activeCount <= 0) {
        *x = _currentX;
        *y = _currentY;
        *buttons = 0;
        return;
    }

    if (activeCount == 1) {
        const TouchContact& touch = _touches[active[0]];
        *x = touch.x;
        *y = touch.y;
        *buttons = MOUSE_STATE_LEFT_BUTTON_DOWN;
        return;
    }

    const TouchContact& first = _touches[active[0]];
    const TouchContact& second = _touches[active[1]];
    *x = (first.x + second.x) / 2;
    *y = (first.y + second.y) / 2;
    *buttons = MOUSE_STATE_RIGHT_BUTTON_DOWN;
}

int InputStateMachine::findTouchIndex(std::int64_t fingerId) const
{
    for (int index = 0; index < kMaxTouches; index++) {
        if (_touches[index].used && _touches[index].fingerId == fingerId) {
            return index;
        }
    }

    return -1;
}

int InputStateMachine::findUnusedTouchIndex() const
{
    for (int index = 0; index < kMaxTouches; index++) {
        if (!_touches[index].used) {
            return index;
        }
    }

    return -1;
}

int InputStateMachine::collectActiveTouchIndices(std::array<int, kMaxTouches>* indices) const
{
    int count = 0;
    for (int index = 0; index < kMaxTouches; index++) {
        if (_touches[index].used) {
            (*indices)[count++] = index;
        }
    }

    return count;
}

void InputStateMachine::removeTouchAtIndex(int index)
{
    _touches[index].used = false;
    _touches[index].fingerId = 0;
    _touches[index].x = 0;
    _touches[index].y = 0;
    _touches[index].deviceKind = PointerDeviceKind::kFinger;
}

} // namespace fallout
