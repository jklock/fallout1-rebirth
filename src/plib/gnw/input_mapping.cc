#include "plib/gnw/input_mapping.h"

#include <algorithm>

namespace fallout {

InputLayoutRect input_compute_letterbox_rect(int containerX, int containerY, int containerW, int containerH, int gameW, int gameH)
{
    InputLayoutRect rect{};
    rect.x = static_cast<float>(containerX);
    rect.y = static_cast<float>(containerY);
    rect.w = 0.0f;
    rect.h = 0.0f;
    rect.valid = false;

    if (containerW <= 0 || containerH <= 0 || gameW <= 0 || gameH <= 0) {
        return rect;
    }

    float gameAspect = static_cast<float>(gameW) / static_cast<float>(gameH);
    float containerAspect = static_cast<float>(containerW) / static_cast<float>(containerH);

    if (containerAspect > gameAspect) {
        float contentW = static_cast<float>(containerH) * gameAspect;
        rect.x = static_cast<float>(containerX) + (static_cast<float>(containerW) - contentW) * 0.5f;
        rect.y = static_cast<float>(containerY);
        rect.w = contentW;
        rect.h = static_cast<float>(containerH);
    } else {
        float contentH = static_cast<float>(containerW) / gameAspect;
        rect.x = static_cast<float>(containerX);
        rect.y = static_cast<float>(containerY) + (static_cast<float>(containerH) - contentH) * 0.5f;
        rect.w = static_cast<float>(containerW);
        rect.h = contentH;
    }

    rect.valid = rect.w > 0.0f && rect.h > 0.0f;
    return rect;
}

bool input_map_screen_to_game(const InputLayoutRect& rect, int gameW, int gameH, float screenX, float screenY, int* gameX, int* gameY)
{
    if (gameX == nullptr || gameY == nullptr || gameW <= 0 || gameH <= 0 || !rect.valid || rect.w <= 0.0f || rect.h <= 0.0f) {
        if (gameX != nullptr) {
            *gameX = 0;
        }
        if (gameY != nullptr) {
            *gameY = 0;
        }
        return false;
    }

    float localX = screenX - rect.x;
    float localY = screenY - rect.y;

    float scaleX = static_cast<float>(gameW) / rect.w;
    float scaleY = static_cast<float>(gameH) / rect.h;

    int mappedX = static_cast<int>(localX * scaleX);
    int mappedY = static_cast<int>(localY * scaleY);

    mappedX = std::clamp(mappedX, 0, gameW - 1);
    mappedY = std::clamp(mappedY, 0, gameH - 1);

    *gameX = mappedX;
    *gameY = mappedY;

    return localX >= 0.0f && localX < rect.w && localY >= 0.0f && localY < rect.h;
}

} // namespace fallout
