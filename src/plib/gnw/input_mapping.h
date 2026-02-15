#ifndef FALLOUT_PLIB_GNW_INPUT_MAPPING_H
#define FALLOUT_PLIB_GNW_INPUT_MAPPING_H

namespace fallout {

struct InputLayoutRect {
    float x;
    float y;
    float w;
    float h;
    bool valid;
};

InputLayoutRect input_compute_letterbox_rect(int containerX, int containerY, int containerW, int containerH, int gameW, int gameH);
bool input_map_screen_to_game(const InputLayoutRect& rect, int gameW, int gameH, float screenX, float screenY, int* gameX, int* gameY);

} // namespace fallout

#endif /* FALLOUT_PLIB_GNW_INPUT_MAPPING_H */
