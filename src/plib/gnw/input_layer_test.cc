#include "plib/gnw/input_mapping.h"
#include "plib/gnw/input_state_machine.h"
#include "plib/gnw/mouse.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

namespace {

using fallout::InputAction;
using fallout::InputActionKind;
using fallout::InputLayoutRect;
using fallout::InputStateMachine;
using fallout::PointerDeviceKind;

int gFailures = 0;

void expect_true(bool condition, const std::string& message)
{
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
        gFailures++;
    }
}

void expect_int(int actual, int expected, const std::string& message)
{
    if (actual != expected) {
        std::cerr << "FAIL: " << message << " (actual=" << actual << " expected=" << expected << ")\n";
        gFailures++;
    }
}

void expect_float_close(float actual, float expected, float epsilon, const std::string& message)
{
    if (std::fabs(actual - expected) > epsilon) {
        std::cerr << "FAIL: " << message << " (actual=" << actual << " expected=" << expected << ")\n";
        gFailures++;
    }
}

std::vector<InputAction> drain_actions(InputStateMachine* stateMachine)
{
    std::vector<InputAction> actions;
    InputAction action{};
    while (stateMachine->popAction(&action)) {
        actions.push_back(action);
    }
    return actions;
}

void test_single_finger_click_and_drag()
{
    InputStateMachine machine;

    machine.onFingerDown(1, 100, 120, true, PointerDeviceKind::kFinger);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "single finger down should emit one action");
    expect_true(actions[0].kind == InputActionKind::kPointer, "single finger down should emit pointer action");
    expect_int(actions[0].x, 100, "single finger down x");
    expect_int(actions[0].y, 120, "single finger down y");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "single finger down buttons");

    machine.onFingerMove(1, 130, 140, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "single finger move should emit one action");
    expect_int(actions[0].x, 130, "single finger move x");
    expect_int(actions[0].y, 140, "single finger move y");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "single finger move buttons");

    machine.onFingerUp(1, 130, 140, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "single finger up should defer release");

    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "release should still be deferred one frame");

    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "release should emit on second frame");
    expect_int(actions[0].x, 130, "single finger release x");
    expect_int(actions[0].y, 140, "single finger release y");
    expect_int(actions[0].buttons, 0, "single finger release buttons");
}

void test_single_finger_drag_stability_heartbeat()
{
    InputStateMachine machine;

    machine.onFingerDown(2, 220, 180, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.endFrame();
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "drag heartbeat should emit one action");
    expect_int(actions[0].x, 220, "drag heartbeat x remains stable");
    expect_int(actions[0].y, 180, "drag heartbeat y remains stable");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "drag heartbeat keeps left button");

    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "second drag heartbeat should emit one action");
    expect_int(actions[0].x, 220, "second drag heartbeat x remains stable");
    expect_int(actions[0].y, 180, "second drag heartbeat y remains stable");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "second drag heartbeat keeps left button");
}

void test_two_finger_right_drag()
{
    InputStateMachine machine;

    machine.onFingerDown(10, 10, 10, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.onFingerDown(11, 30, 10, true, PointerDeviceKind::kFinger);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "second finger down should emit one action");
    expect_int(actions[0].x, 20, "right drag starts at centroid x");
    expect_int(actions[0].y, 10, "right drag starts at centroid y");
    expect_int(actions[0].buttons, MOUSE_STATE_RIGHT_BUTTON_DOWN, "second finger switches to right button");

    machine.onFingerMove(11, 50, 10, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "two finger move should emit one action");
    expect_int(actions[0].x, 30, "two finger move updates centroid x");
    expect_int(actions[0].buttons, MOUSE_STATE_RIGHT_BUTTON_DOWN, "two finger move keeps right button");

    machine.onFingerUp(11, 50, 10, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "lifting second finger should emit transition action");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "remaining finger returns to left button");
    expect_int(actions[0].x, 10, "remaining finger x after right drag");
    expect_int(actions[0].y, 10, "remaining finger y after right drag");

    machine.onFingerUp(10, 10, 10, true);
    drain_actions(&machine);
    machine.endFrame();
    drain_actions(&machine);
    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "final release after two-finger sequence");
    expect_int(actions[0].buttons, 0, "final release buttons");
}

void test_two_finger_right_click()
{
    InputStateMachine machine;

    machine.onFingerDown(101, 300, 400, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.onFingerDown(102, 340, 420, true, PointerDeviceKind::kFinger);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "two-finger press should emit one action");
    expect_int(actions[0].x, 320, "two-finger press centroid x");
    expect_int(actions[0].y, 410, "two-finger press centroid y");
    expect_int(actions[0].buttons, MOUSE_STATE_RIGHT_BUTTON_DOWN, "two-finger press uses right button");

    machine.onFingerUp(102, 340, 420, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "lifting one finger should transition back to left");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "remaining finger keeps left down");

    machine.onFingerUp(101, 300, 400, true);
    drain_actions(&machine);
    machine.endFrame();
    drain_actions(&machine);
    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "two-finger click should end with one release action");
    expect_int(actions[0].buttons, 0, "two-finger click release buttons");
}

void test_out_of_bounds_move_does_not_jump()
{
    InputStateMachine machine;

    machine.onFingerDown(20, 200, 200, true, PointerDeviceKind::kPencil);
    drain_actions(&machine);

    machine.onFingerMove(20, 0, 0, false);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "out-of-bounds move should not emit immediate jump");

    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "active pointer heartbeat should emit one action");
    expect_int(actions[0].x, 200, "out-of-bounds heartbeat x stays stable");
    expect_int(actions[0].y, 200, "out-of-bounds heartbeat y stays stable");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "out-of-bounds heartbeat keeps left button");
}

void test_stale_position_click_prevention()
{
    InputStateMachine machine;

    machine.onFingerDown(200, 40, 50, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.onFingerMove(200, 80, 90, true);
    drain_actions(&machine);

    machine.onFingerUp(200, 80, 90, true);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "finger up should defer release for stale-click protection");

    machine.onMouseAbsolute(500, 500, 0, 0, 0);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "mouse handoff blocked until deferred release completes");

    machine.endFrame();
    drain_actions(&machine);
    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "deferred touch release should emit exactly once");
    expect_int(actions[0].x, 80, "deferred release uses latest touch x");
    expect_int(actions[0].y, 90, "deferred release uses latest touch y");
    expect_int(actions[0].buttons, 0, "deferred release buttons");
}

void test_mouse_path_is_blocked_while_touch_active()
{
    InputStateMachine machine;

    machine.onFingerDown(30, 50, 60, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.onMouseAbsolute(500, 500, 0, 1, 2);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "mouse events ignored while touch stream is active");

    machine.onFingerUp(30, 50, 60, true);
    drain_actions(&machine);
    machine.endFrame();
    drain_actions(&machine);
    machine.endFrame();
    drain_actions(&machine);

    machine.onMouseAbsolute(500, 500, 0, 1, 2);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 2, "mouse should emit pointer and wheel once touch is inactive");
    expect_true(actions[0].kind == InputActionKind::kPointer, "first post-touch action should be pointer");
    expect_int(actions[0].x, 500, "mouse absolute x");
    expect_int(actions[0].y, 500, "mouse absolute y");
    expect_true(actions[1].kind == InputActionKind::kWheel, "second post-touch action should be wheel");
    expect_int(actions[1].wheelX, 1, "mouse wheel x");
    expect_int(actions[1].wheelY, 2, "mouse wheel y");
}

void test_mouse_absolute_sync_no_touch()
{
    InputStateMachine machine;

    machine.onMouseAbsolute(10, 20, 0, 0, 0);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "mouse absolute should emit pointer action");
    expect_int(actions[0].x, 10, "mouse absolute first x");
    expect_int(actions[0].y, 20, "mouse absolute first y");
    expect_int(actions[0].buttons, 0, "mouse absolute first buttons");

    machine.onMouseAbsolute(640, 479, MOUSE_STATE_LEFT_BUTTON_DOWN, 0, 0);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "mouse absolute second action count");
    expect_int(actions[0].x, 640, "mouse absolute second x");
    expect_int(actions[0].y, 479, "mouse absolute second y");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "mouse absolute second buttons");
}

void test_secondary_click_sequence()
{
    InputStateMachine machine;
    machine.onSecondaryClick(300, 301);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 2, "secondary click emits down and up");
    expect_int(actions[0].buttons, MOUSE_STATE_RIGHT_BUTTON_DOWN, "secondary click down");
    expect_int(actions[1].buttons, 0, "secondary click up");
    expect_int(actions[0].x, 300, "secondary click x");
    expect_int(actions[0].y, 301, "secondary click y");
}

void test_secondary_click_ignored_while_pointer_active()
{
    InputStateMachine machine;

    machine.onFingerDown(500, 120, 130, true, PointerDeviceKind::kFinger);
    drain_actions(&machine);

    machine.onSecondaryClick(600, 600);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 0, "secondary click should be ignored while pointer stream active");
}

void test_pencil_precise_down_move_up()
{
    InputStateMachine machine;

    machine.onFingerDown(700, 123, 234, true, PointerDeviceKind::kPencil);
    auto actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "pencil down emits one action");
    expect_int(actions[0].x, 123, "pencil down x");
    expect_int(actions[0].y, 234, "pencil down y");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "pencil down uses left button");

    machine.onFingerMove(700, 124, 236, true);
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "pencil move emits one action");
    expect_int(actions[0].x, 124, "pencil move x");
    expect_int(actions[0].y, 236, "pencil move y");
    expect_int(actions[0].buttons, MOUSE_STATE_LEFT_BUTTON_DOWN, "pencil move keeps left button");

    machine.onFingerUp(700, 124, 236, true);
    drain_actions(&machine);
    machine.endFrame();
    drain_actions(&machine);
    machine.endFrame();
    actions = drain_actions(&machine);
    expect_int(static_cast<int>(actions.size()), 1, "pencil up emits one deferred release");
    expect_int(actions[0].x, 124, "pencil release x");
    expect_int(actions[0].y, 236, "pencil release y");
    expect_int(actions[0].buttons, 0, "pencil release buttons");
}

void test_mapping_portrait_fullscreen()
{
    InputLayoutRect rect = fallout::input_compute_letterbox_rect(0, 0, 1000, 1400, 640, 480);
    expect_true(rect.valid, "portrait rect should be valid");
    expect_float_close(rect.x, 0.0f, 0.01f, "portrait rect x");
    expect_float_close(rect.w, 1000.0f, 0.01f, "portrait rect w");
    expect_float_close(rect.h, 750.0f, 0.01f, "portrait rect h");
    expect_float_close(rect.y, 325.0f, 0.01f, "portrait rect y");

    int gx = 0;
    int gy = 0;
    bool inBounds = fallout::input_map_screen_to_game(rect, 640, 480, 500.0f, 700.0f, &gx, &gy);
    expect_true(inBounds, "portrait center should map in bounds");
    expect_int(gx, 320, "portrait center maps x");
    expect_int(gy, 240, "portrait center maps y");

    inBounds = fallout::input_map_screen_to_game(rect, 640, 480, 500.0f, 100.0f, &gx, &gy);
    expect_true(!inBounds, "portrait top bar should map out of bounds");
    expect_int(gy, 0, "portrait top bar clamp y");
}

void test_mapping_safe_area_insets()
{
    InputLayoutRect rect = fallout::input_compute_letterbox_rect(100, 50, 1000, 800, 640, 480);
    expect_true(rect.valid, "safe area rect should be valid");
    expect_float_close(rect.x, 100.0f, 0.01f, "safe area rect x");
    expect_float_close(rect.w, 1000.0f, 0.01f, "safe area rect w");
    expect_float_close(rect.h, 750.0f, 0.01f, "safe area rect h");
    expect_float_close(rect.y, 75.0f, 0.01f, "safe area rect y");

    int gx = 0;
    int gy = 0;
    bool inBounds = fallout::input_map_screen_to_game(rect, 640, 480, 1099.0f, 824.0f, &gx, &gy);
    expect_true(inBounds, "safe area bottom-right should map in bounds");
    expect_true(gx >= 638, "safe area bottom-right x should reach high logical range");
    expect_true(gy >= 478, "safe area bottom-right y should reach high logical range");
}

void test_mapping_landscape_fullscreen()
{
    InputLayoutRect rect = fallout::input_compute_letterbox_rect(0, 0, 1366, 1024, 640, 480);
    expect_true(rect.valid, "landscape rect should be valid");
    expect_float_close(rect.x, 0.5f, 1.0f, "landscape rect x near centered");
    expect_float_close(rect.y, 0.0f, 0.01f, "landscape rect y");
    expect_float_close(rect.h, 1024.0f, 0.01f, "landscape rect h");

    int gx = 0;
    int gy = 0;
    bool inBounds = fallout::input_map_screen_to_game(rect, 640, 480, rect.x + rect.w * 0.5f, 512.0f, &gx, &gy);
    expect_true(inBounds, "landscape center should map in bounds");
    expect_int(gx, 320, "landscape center maps x");
    expect_int(gy, 240, "landscape center maps y");
}

void test_mapping_windowed_and_dynamic_bounds()
{
    InputLayoutRect windowed = fallout::input_compute_letterbox_rect(200, 120, 900, 700, 640, 480);
    expect_true(windowed.valid, "windowed rect should be valid");

    int gx = 0;
    int gy = 0;
    bool inBounds = fallout::input_map_screen_to_game(windowed, 640, 480, 650.0f, 470.0f, &gx, &gy);
    expect_true(inBounds, "windowed center point in bounds");
    expect_true(gx >= 319 && gx <= 321, "windowed center maps around x midpoint");
    expect_true(gy >= 239 && gy <= 241, "windowed center maps around y midpoint");

    InputLayoutRect resized = fallout::input_compute_letterbox_rect(200, 120, 700, 900, 640, 480);
    expect_true(resized.valid, "resized rect should be valid");

    inBounds = fallout::input_map_screen_to_game(resized, 640, 480, 210.0f, 130.0f, &gx, &gy);
    expect_true(!inBounds, "resized top-left margin should be out of bounds");
    expect_true(gx >= 0 && gx <= 16, "resized out-of-bounds clamp x remains near low edge");
    expect_int(gy, 0, "resized out-of-bounds clamp y");
}

} // namespace

int main()
{
    test_single_finger_click_and_drag();
    test_single_finger_drag_stability_heartbeat();
    test_two_finger_right_drag();
    test_two_finger_right_click();
    test_out_of_bounds_move_does_not_jump();
    test_stale_position_click_prevention();
    test_mouse_path_is_blocked_while_touch_active();
    test_mouse_absolute_sync_no_touch();
    test_secondary_click_sequence();
    test_secondary_click_ignored_while_pointer_active();
    test_pencil_precise_down_move_up();
    test_mapping_portrait_fullscreen();
    test_mapping_safe_area_insets();
    test_mapping_landscape_fullscreen();
    test_mapping_windowed_and_dynamic_bounds();

    if (gFailures != 0) {
        std::cerr << "Input layer tests failed: " << gFailures << '\n';
        return 1;
    }

    std::cout << "Input layer tests passed\n";
    return 0;
}
