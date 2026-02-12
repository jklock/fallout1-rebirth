#include "plib/gnw/gnw.h"

#include <algorithm>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "game/map.h"
#include "game/palette.h"
#include "plib/color/color.h"
#include "plib/db/db.h"
#include "plib/db/patchlog.h"
#include "plib/gnw/button.h"
#include "plib/gnw/debug.h"
#include "plib/gnw/grbuf.h"
#include "plib/gnw/input.h"
#include "plib/gnw/intrface.h"
#include "plib/gnw/memory.h"
#include "plib/gnw/svga.h"
#include "plib/gnw/text.h"
#include "plib/gnw/vcr.h"
#include "plib/gnw/winmain.h"

namespace fallout {

#define MAX_WINDOW_COUNT 50

static void win_free(int win);
static void win_clip(Window* window, RectPtr* rectListNodePtr, unsigned char* a3);
static void refresh_all(Rect* rect, unsigned char* a2);
static void* colorOpen(const char* path);
static int colorRead(void* handle, void* buf, size_t count);
static int colorClose(void* handle);

// 0x53A22C
static bool GNW95_already_running = false;

// 0x53A234
bool GNW_win_init_flag = false;

// 0x53A238
int GNW_wcolor[6] = {
    0,
    0,
    0,
    0,
    0,
static unsigned char* screen_buffer = NULL;

// 0x6AC120
static int window_index[MAX_WINDOW_COUNT];

// 0x6AC1E8
static Window* window[MAX_WINDOW_COUNT];

// 0x6AC2B4
static int num_windows;

// 0x6AC2B8
static int window_flags;

// 0x6AC2BC
static bool buffering;

// 0x6AC2C0
static int bk_color;

// 0x6AC2C8
static int doing_refresh_all;

// 0x6AC2CC
void* GNW_texture;

// 0x4C1CF0
int win_init(VideoOptions* video_options, int flags)
{
    if (GNW95_already_running) {
        return WINDOW_MANAGER_ERR_ALREADY_RUNNING;
    }

    if (GNW_win_init_flag) {
        return WINDOW_MANAGER_ERR_WINDOW_SYSTEM_ALREADY_INITIALIZED;
    }

    for (int index = 0; index < MAX_WINDOW_COUNT; index++) {
        window_index[index] = -1;
    }

    if (db_total() == 0) {
        if (db_init(NULL, NULL, "", 1) == INVALID_DATABASE_HANDLE) {
            return WINDOW_MANAGER_ERR_INITIALIZING_DEFAULT_DATABASE;
        }
    }

    if (GNW_text_init() == -1) {
        return WINDOW_MANAGER_ERR_INITIALIZING_TEXT_FONTS;
    }

    if (!svga_init(video_options)) {
        svga_exit();

        return WINDOW_MANAGER_ERR_INITIALIZING_VIDEO_MODE;
    }

    if ((flags & 1) != 0) {
        screen_buffer = (unsigned char*)mem_malloc((scr_size.lry - scr_size.uly + 1) * (scr_size.lrx - scr_size.ulx + 1));
        if (screen_buffer == NULL) {
            svga_exit();

            return WINDOW_MANAGER_ERR_NO_MEMORY;
        }
    }

    buffering = false;
    doing_refresh_all = 0;

    colorInitIO(colorOpen, colorRead, colorClose);
    colorRegisterAlloc(mem_malloc, mem_realloc, mem_free);

    if (!initColors()) {
        unsigned char* palette = (unsigned char*)mem_malloc(768);
        if (palette == NULL) {
            svga_exit();

            if (screen_buffer != NULL) {
                mem_free(screen_buffer);
            }

            return WINDOW_MANAGER_ERR_NO_MEMORY;
        }

        buf_fill(palette, 768, 1, 768, 0);

        // TODO: Incomplete.
        // _colorBuildColorTable(getSystemPalette(), palette);

        mem_free(palette);
    }

    GNW_debug_init();

    if (GNW_input_init(flags) == -1) {
        return WINDOW_MANAGER_ERR_INITIALIZING_INPUT;
    }

    GNW_intr_init();

    Window* w = window[0] = (Window*)mem_malloc(sizeof(*w));
    if (w == NULL) {
        svga_exit();

        if (screen_buffer != NULL) {
            mem_free(screen_buffer);
        }

        return WINDOW_MANAGER_ERR_NO_MEMORY;
    }

    w->id = 0;
    w->flags = 0;
    w->rect.ulx = scr_size.ulx;
    w->rect.uly = scr_size.uly;
    w->rect.lrx = scr_size.lrx;
    w->rect.lry = scr_size.lry;
    w->width = scr_size.lrx - scr_size.ulx + 1;
    w->height = scr_size.lry - scr_size.uly + 1;
    w->tx = 0;
    w->ty = 0;
    w->buffer = NULL;
    w->buttonListHead = NULL;
    w->hoveredButton = NULL;
    w->clickedButton = 0;
    w->menuBar = NULL;

    num_windows = 1;
    GNW_win_init_flag = 1;
    window_index[0] = 0;
    bk_color = 0;
    window_flags = flags;

    // NOTE: Uninline.
    win_no_texture();

    atexit(win_exit);

    return WINDOW_MANAGER_OK;
}

// 0x4C2224
int win_active()
{
    return GNW_win_init_flag;
}

// 0x4C222C
void win_exit(void)
{
    // 0x53A254
    static bool insideWinExit = false;

    if (!insideWinExit) {
        insideWinExit = true;
        if (GNW_win_init_flag) {
            GNW_intr_exit();

            for (int index = num_windows - 1; index >= 0; index--) {
                win_free(window[index]->id);
            }

            if (GNW_texture != NULL) {
                mem_free(GNW_texture);
            }

            if (screen_buffer != NULL) {
                mem_free(screen_buffer);
            }

            svga_exit();

            GNW_input_exit();
            GNW_rect_exit();
            GNW_text_exit();
            colorsClose();

            GNW_win_init_flag = false;
        }
        insideWinExit = false;
    }
}

// 0x4C22F8
int win_add(int x, int y, int width, int height, int color, int flags)
{
    int v23;
    int v25, v26;
    Window* tmp;

    if (!GNW_win_init_flag) {
        return -1;
    }

    if (num_windows == MAX_WINDOW_COUNT) {
        return -1;
    }

    if (width > rectGetWidth(&scr_size)) {
        return -1;
    }

    if (height > rectGetHeight(&scr_size)) {
        return -1;
    }

    Window* w = window[num_windows] = (Window*)mem_malloc(sizeof(*w));
    if (w == NULL) {
        return -1;
    }

    w->buffer = (unsigned char*)mem_malloc(width * height);
    if (w->buffer == NULL) {
        mem_free(w);
        return -1;
    }

    int index = 1;
    while (GNW_find(index) != NULL) {
        index++;
    }

    w->id = index;

    if ((flags & WINDOW_USE_DEFAULTS) != 0) {
        flags |= window_flags;
    }

    w->width = width;
    w->height = height;
    w->flags = flags;
    w->tx = rand() & 0xFFFE;
    w->ty = rand() & 0xFFFE;

    if (color == 256) {
        if (GNW_texture == NULL) {
            color = colorTable[GNW_wcolor[0]];
        }
    } else if ((color & 0xFF00) != 0) {
        int colorIndex = (color & 0xFF) - 1;
        color = (color & ~0xFFFF) | colorTable[GNW_wcolor[colorIndex]];
    }

    w->buttonListHead = 0;
    w->hoveredButton = 0;
    w->clickedButton = 0;
    w->menuBar = NULL;
    w->blitProc = trans_buf_to_buf;
    w->color = color;
    window_index[index] = num_windows;
    num_windows++;

    win_fill(index, 0, 0, width, height, color);

    w->flags |= WINDOW_HIDDEN;
    win_move(index, x, y);
    w->flags = flags;

    if ((flags & WINDOW_MOVE_ON_TOP) == 0) {
        v23 = num_windows - 2;
        while (v23 > 0) {
            if (!(window[v23]->flags & WINDOW_MOVE_ON_TOP)) {
                break;
            }
            v23--;
        }

        if (v23 != num_windows - 2) {
            v25 = v23 + 1;
            v26 = num_windows - 1;
            while (v26 > v25) {
                tmp = window[v26 - 1];
                window[v26] = tmp;
                window_index[tmp->id] = v26;
                v26--;
            }

            window[v25] = w;
            window_index[index] = v25;
        }
    }

    return index;
}

// 0x4C2524
void win_delete(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    Rect rect;
    rectCopy(&rect, &(w->rect));

    int v1 = window_index[w->id];
    win_free(win);

    window_index[win] = -1;

    for (int index = v1; index < num_windows - 1; index++) {
        window[index] = window[index + 1];
        window_index[window[index]->id] = index;
    }

    num_windows--;

    // NOTE: Uninline.
    win_refresh_all(&rect);
}

// 0x4C25C8
static void win_free(int win)
{
    Window* w = GNW_find(win);
    if (w == NULL) {
        return;
    }

    if (w->buffer != NULL) {
        mem_free(w->buffer);
    }

    if (w->menuBar != NULL) {
        mem_free(w->menuBar);
    }

    Button* curr = w->buttonListHead;
    while (curr != NULL) {
        Button* next = curr->next;
        GNW_delete_button(curr);
        curr = next;
    }

    mem_free(w);
}

// 0x4C2614
void win_buffering(bool state)
{
    if (screen_buffer != NULL) {
        buffering = state;
    }
}

// 0x4C2624
void win_border(int win)
{
    if (!GNW_win_init_flag) {
        return;
    }

    Window* w = GNW_find(win);
    if (w == NULL) {
        return;
    }

    lighten_buf(w->buffer + 5, w->width - 10, 5, w->width);
    lighten_buf(w->buffer, 5, w->height, w->width);
    lighten_buf(w->buffer + w->width - 5, 5, w->height, w->width);
    lighten_buf(w->buffer + w->width * (w->height - 5) + 5, w->width - 10, 5, w->width);

    draw_box(w->buffer, w->width, 0, 0, w->width - 1, w->height - 1, colorTable[0]);

    draw_shaded_box(w->buffer, w->width, 1, 1, w->width - 2, w->height - 2, colorTable[GNW_wcolor[1]], colorTable[GNW_wcolor[2]]);
    draw_shaded_box(w->buffer, w->width, 5, 5, w->width - 6, w->height - 6, colorTable[GNW_wcolor[2]], colorTable[GNW_wcolor[1]]);
}

// 0x4C2754
void win_no_texture()
{
    if (GNW_win_init_flag) {
        if (GNW_texture != NULL) {
            mem_free(GNW_texture);
            GNW_texture = NULL;
        }

        GNW_wcolor[0] = 10570;
        GNW_wcolor[1] = 15855;
        GNW_wcolor[2] = 8456;
        GNW_wcolor[3] = 21140;
        GNW_wcolor[4] = 32747;
        GNW_wcolor[5] = 31744;
    }
}

// 0x4C28D4
void win_set_bk_color(int color)
{
    if (GNW_win_init_flag) {
        bk_color = color;
        win_draw(0);
    }
}

// 0x4C2908
void win_print(int win, const char* str, int width, int x, int y, int color)
{
    unsigned char* buf;
    int textColor;

    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if (width == 0) {
        if (color & 0x040000) {
            width = text_mono_width(str);
        } else {
            width = text_width(str);
        }
    }

    if (width + x > w->width) {
        if (!(color & 0x04000000)) {
            return;
        }

        width = w->width - x;
    }

    buf = w->buffer + x + y * w->width;

    if (text_height() + y > w->height) {
        return;
    }

    if (!(color & 0x02000000)) {
        if (w->color == 256 && GNW_texture != NULL) {
            buf_texture(buf, width, text_height(), w->width, GNW_texture, w->tx + x, w->ty + y);
        } else {
            buf_fill(buf, width, text_height(), w->width, w->color);
        }
    }

    if ((color & 0xFF00) != 0) {
        int colorIndex = (color & 0xFF) - 1;
        textColor = (color & ~0xFFFF) | colorTable[GNW_wcolor[colorIndex]];
    } else {
        textColor = color;
    }

    text_to_buf(buf, str, width, w->width, textColor);

    if (color & 0x01000000) {
        // TODO: Check.
        Rect rect;
        rect.ulx = w->rect.ulx + x;
        rect.uly = w->rect.uly + y;
        rect.lrx = rect.ulx + width;
        rect.lry = rect.uly + text_height();
        GNW_win_refresh(w, &rect, NULL);
    }
}

// 0x4C2A98
void win_text(int win, char** fileNameList, int fileNameListLength, int maxWidth, int x, int y, int color)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    int width = w->width;
    unsigned char* ptr = w->buffer + y * width + x;
    int lineHeight = text_height();

    int step = width * lineHeight;
    int v1 = lineHeight / 2;
    int v2 = v1 + 1;
    int v3 = maxWidth - 1;

    for (int index = 0; index < fileNameListLength; index++) {
        char* fileName = fileNameList[index];
        if (*fileName != '\0') {
            win_print(win, fileName, maxWidth, x, y, color);
        } else {
            if (maxWidth != 0) {
                draw_line(ptr, width, 0, v1, v3, v1, colorTable[GNW_wcolor[2]]);
                draw_line(ptr, width, 0, v2, v3, v2, colorTable[GNW_wcolor[1]]);
            }
        }

        ptr += step;
        y += lineHeight;
    }
}

// 0x4C2BE0
void win_line(int win, int left, int top, int right, int bottom, int color)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if ((color & 0xFF00) != 0) {
        int colorIndex = (color & 0xFF) - 1;
        color = (color & ~0xFFFF) | colorTable[GNW_wcolor[colorIndex]];
    }

    draw_line(w->buffer, w->width, left, top, right, bottom, color);
}

// 0x4C2C44
void win_box(int win, int left, int top, int right, int bottom, int color)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if ((color & 0xFF00) != 0) {
        int colorIndex = (color & 0xFF) - 1;
        color = (color & ~0xFFFF) | colorTable[GNW_wcolor[colorIndex]];
    }

    if (right < left) {
        int tmp = left;
        left = right;
        right = tmp;
    }

    if (bottom < top) {
        int tmp = top;
        top = bottom;
        bottom = tmp;
    }

    draw_box(w->buffer, w->width, left, top, right, bottom, color);
}

// 0x4C2CD4
void win_shaded_box(int id, int ulx, int uly, int lrx, int lry, int color1, int color2)
{
    Window* w = GNW_find(id);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if ((color1 & 0xFF00) != 0) {
        color1 = (color1 & 0xFFFF0000) | colorTable[GNW_wcolor[(color1 & 0xFFFF) - 257]];
    }

    if ((color2 & 0xFF00) != 0) {
        color2 = (color2 & 0xFFFF0000) | colorTable[GNW_wcolor[(color2 & 0xFFFF) - 257]];
    }

    draw_shaded_box(w->buffer, w->width, ulx, uly, lrx, lry, color1, color2);
}

// 0x4C2D84
void win_fill(int win, int x, int y, int width, int height, int color)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if (color == 256) {
        if (GNW_texture != NULL) {
            buf_texture(w->buffer + w->width * y + x, width, height, w->width, GNW_texture, x + w->tx, y + w->ty);
        } else {
            color = colorTable[GNW_wcolor[0]] & 0xFF;
        }
    } else if ((color & 0xFF00) != 0) {
        int colorIndex = (color & 0xFF) - 1;
        color = (color & ~0xFFFF) | colorTable[GNW_wcolor[colorIndex]];
    }

    if (color < 256) {
        buf_fill(w->buffer + w->width * y + x, width, height, w->width, color);
    }
}

// 0x4C2E68
void win_show(int win)
{
    Window* w;
    int v3;
    int v5;
    int v7;
    Window* v6;

    w = GNW_find(win);
    v3 = window_index[w->id];

    if (!GNW_win_init_flag) {
        return;
    }

    if (w->flags & WINDOW_HIDDEN) {
        w->flags &= ~WINDOW_HIDDEN;
        if (v3 == num_windows - 1) {
            GNW_win_refresh(w, &(w->rect), NULL);
        }
    }

    v5 = num_windows - 1;
    if (v3 < v5 && !(w->flags & WINDOW_DONT_MOVE_TOP)) {
        v7 = v3;
        while (v3 < v5 && ((w->flags & WINDOW_MOVE_ON_TOP) || !(window[v7 + 1]->flags & WINDOW_MOVE_ON_TOP))) {
            v6 = window[v7 + 1];
            window[v7] = v6;
            v7++;
            window_index[v6->id] = v3++;
        }

        window[v3] = w;
        window_index[w->id] = v3;
        GNW_win_refresh(w, &(w->rect), NULL);
    }
}

// 0x4C2F20
void win_hide(int win)
{
    if (!GNW_win_init_flag) {
        return;
    }

    Window* w = GNW_find(win);
    if (w == NULL) {
        return;
    }

    if ((w->flags & WINDOW_HIDDEN) == 0) {
        w->flags |= WINDOW_HIDDEN;
        refresh_all(&(w->rect), NULL);
    }
}

// 0x4C2F5C
void win_move(int win, int x, int y)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    Rect rect;
    rectCopy(&rect, &(w->rect));

    if (x < 0) {
        x = 0;
    }

    if (y < 0) {
        y = 0;
    }

    if ((w->flags & WINDOW_MANAGED) != 0) {
        x += 2;
    }

    if (x + w->width - 1 > scr_size.lrx) {
        x = scr_size.lrx - w->width + 1;
    }

    if (y + w->height - 1 > scr_size.lry) {
        y = scr_size.lry - w->height + 1;
    }

    if ((w->flags & WINDOW_MANAGED) != 0) {
        // TODO: Not sure what this means.
        x &= ~0x03;
    }

    w->rect.ulx = x;
    w->rect.uly = y;
    w->rect.lrx = w->width + x - 1;
    w->rect.lry = w->height + y - 1;

    if ((w->flags & WINDOW_HIDDEN) == 0) {
        GNW_win_refresh(w, &(w->rect), NULL);

        if (GNW_win_init_flag) {
            refresh_all(&rect, NULL);
        }
    }
}

// 0x4C3018
void win_draw(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    GNW_win_refresh(w, &(w->rect), NULL);
}

// 0x4C303C
void win_draw_rect(int win, const Rect* rect)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    Rect newRect;
    rectCopy(&newRect, rect);
    rectOffset(&newRect, w->rect.ulx, w->rect.uly);

    GNW_win_refresh(w, &newRect, NULL);
}

// 0x4C3094
static bool merge_fill_group_and_blit(rectdata* group_start, rectdata* group_end, int bk_color)
{
    int group_ulx = group_start->rect.ulx;
    int group_uly = group_start->rect.uly;
    int group_lrx = group_end->rect.lrx;
    int group_lry = group_end->rect.lry;
    int compW = group_lrx - group_ulx + 1;
    int compH = group_lry - group_uly + 1;

    unsigned char* compBuf = (unsigned char*)mem_malloc((size_t)compW * (size_t)compH);
    if (compBuf == NULL) {
        return false;
    }

    for (int r = 0; r < compH; r++) {
        memset(compBuf + r * compW, (unsigned char)bk_color, compW);
    }

    rectdata* g = group_start;
    while (true) {
        int w = g->rect.lrx - g->rect.ulx + 1;
        int h = g->rect.lry - g->rect.uly + 1;
        unsigned char* gbuf = (unsigned char*)mem_malloc(w * h);
        if (gbuf == NULL) {
            mem_free(compBuf);
            return false;
        }
        buf_fill(gbuf, w, h, w, bk_color);

        int dx = g->rect.ulx - group_ulx;
        int dy = g->rect.uly - group_uly;
        for (int r = 0; r < h; r++) {
            memcpy(compBuf + (dy + r) * compW + dx, gbuf + r * w, w);
        }

        patchlog_write("DEBUG_MEM", "merged buf=%p w=%d h=%d into compBuf at dx=%d dy=%d", gbuf, w, h, dx, dy);
        mem_free(gbuf);

        if (g == group_end) {
            break;
        }
        g = g->next;
    }

    Rect mapRect;
    if (win_get_rect(display_win, &mapRect) == 0) {
        int inter_ulx = std::max(mapRect.ulx, group_ulx);
        int inter_uly = std::max(mapRect.uly, group_uly);
        int inter_lrx = std::min(mapRect.lrx, group_lrx);
        int inter_lry = std::min(mapRect.lry, group_lry);

        if (inter_lrx >= inter_ulx && inter_lry >= inter_uly) {
            unsigned char* mapBuf = win_get_buf(display_win);
            if (mapBuf != NULL) {
                int mapPitch = mapRect.lrx - mapRect.ulx + 1;
                int inter_w = inter_lrx - inter_ulx + 1;
                int inter_h = inter_lry - inter_uly + 1;
                for (int r = 0; r < inter_h; r++) {
                    unsigned char* srcRow = mapBuf + (inter_uly + r) * mapPitch + inter_ulx;
                    unsigned char* dstRow = compBuf + (inter_uly - group_uly + r) * compW + (inter_ulx - group_ulx);
                    patchlog_write("DEBUG_COPY_ROW", "r=%d srcRow=%p dstRow=%p", r, srcRow, dstRow);
                    memcpy(dstRow, srcRow, inter_w);
                }
            }
        }
    }

    scr_blit(compBuf, compW, compH, 0, 0, compW, compH, group_ulx, group_uly);
    patchlog_write("DEBUG_MEM", "merged compBuf=%p compW=%d compH=%d group_ulx=%d group_uly=%d", compBuf, compW, compH, group_ulx, group_uly);
    mem_free(compBuf);

    return true;
}

// 0x4C3094
void GNW_win_refresh(Window* w, Rect* rect, unsigned char* a3)
{
    RectPtr v26, v20, v23, v24;
    int dest_pitch;

    // TODO: Get rid of this.
    dest_pitch = 0;

    if ((w->flags & WINDOW_HIDDEN) != 0) {
        return;
    }

    if ((w->flags & WINDOW_TRANSPARENT) && buffering && !doing_refresh_all) {
        // TODO: Incomplete.
    } else {
        v26 = rect_malloc();
        if (v26 == NULL) {
            return;
        }

        v26->next = NULL;

        v26->rect.ulx = std::max(w->rect.ulx, rect->ulx);
        v26->rect.uly = std::max(w->rect.uly, rect->uly);
        v26->rect.lrx = std::min(w->rect.lrx, rect->lrx);
        v26->rect.lry = std::min(w->rect.lry, rect->lry);

        if (v26->rect.lrx >= v26->rect.ulx && v26->rect.lry >= v26->rect.uly) {
            if (a3) {
                dest_pitch = rect->lrx - rect->ulx + 1;
            }

            win_clip(w, &v26, a3);

            if (w->id) {
                v20 = v26;
                while (v20) {
                    GNW_button_refresh(w, &(v20->rect));

                    if (a3) {
                        if (buffering && (w->flags & WINDOW_TRANSPARENT)) {
                            w->blitProc(w->buffer + v20->rect.ulx - w->rect.ulx + (v20->rect.uly - w->rect.uly) * w->width,
                                v20->rect.lrx - v20->rect.ulx + 1,
                                v20->rect.lry - v20->rect.uly + 1,
                                w->width,
                                a3 + dest_pitch * (v20->rect.uly - rect->uly) + v20->rect.ulx - rect->ulx,
                                dest_pitch);
                        } else {
                            buf_to_buf(
                                w->buffer + v20->rect.ulx - w->rect.ulx + (v20->rect.uly - w->rect.uly) * w->width,
                                v20->rect.lrx - v20->rect.ulx + 1,
                                v20->rect.lry - v20->rect.uly + 1,
                                w->width,
                                a3 + dest_pitch * (v20->rect.uly - rect->uly) + v20->rect.ulx - rect->ulx,
                                dest_pitch);
                        }
                    } else {
                        if (buffering) {
                            if (w->flags & WINDOW_TRANSPARENT) {
                                w->blitProc(
                                    w->buffer + v20->rect.ulx - w->rect.ulx + (v20->rect.uly - w->rect.uly) * w->width,
                                    v20->rect.lrx - v20->rect.ulx + 1,
                                    v20->rect.lry - v20->rect.uly + 1,
                                    w->width,
                                    screen_buffer + v20->rect.uly * (scr_size.lrx - scr_size.ulx + 1) + v20->rect.ulx,
                                    scr_size.lrx - scr_size.ulx + 1);
                            } else {
                                buf_to_buf(
                                    w->buffer + v20->rect.ulx - w->rect.ulx + (v20->rect.uly - w->rect.uly) * w->width,
                                    v20->rect.lrx - v20->rect.ulx + 1,
                                    v20->rect.lry - v20->rect.uly + 1,
                                    w->width,
                                    screen_buffer + v20->rect.uly * (scr_size.lrx - scr_size.ulx + 1) + v20->rect.ulx,
                                    scr_size.lrx - scr_size.ulx + 1);
                            }
                        } else {
                            scr_blit(
                                w->buffer + v20->rect.ulx - w->rect.ulx + (v20->rect.uly - w->rect.uly) * w->width,
                                w->width,
                                v20->rect.lry - v20->rect.uly + 1,
                                0,
                                0,
                                v20->rect.lrx - v20->rect.ulx + 1,
                                v20->rect.lry - v20->rect.uly + 1,
                                v20->rect.ulx,
                                v20->rect.uly);
                        }
                    }

                    v20 = v20->next;
                }
            } else {
                rectdata* v16 = v26;
                while (v16 != NULL) {
                    int width = v16->rect.lrx - v16->rect.ulx + 1;
                    int height = v16->rect.lry - v16->rect.uly + 1;
                    unsigned char* buf = (unsigned char*)mem_malloc(width * height);
                    if (buf != NULL) {
                        buf_fill(buf, width, height, width, bk_color);

                        if (patchlog_verbose()) {
                            patchlog_write("WIN_FILL_RECT", "dest=%d,%d w=%d h=%d bk_color=%d srcPtr=%p",
                                v16->rect.ulx, v16->rect.uly, width, height, bk_color, buf);
                        }
                        if (dest_pitch != 0) {
                            buf_to_buf(
                                buf,
                                width,
                                height,
                                width,
                                a3 + dest_pitch * (v16->rect.uly - rect->uly) + v16->rect.ulx - rect->ulx,
                                dest_pitch);
                        } else {
                            if (buffering) {
                                if (patchlog_verbose()) {
                                    patchlog_write("WIN_FILL_RECT_SCREENBUF", "dest=%d,%d w=%d h=%d bk_color=%d srcPtr=%p screenPtr=%p",
                                        v16->rect.ulx, v16->rect.uly, width, height, bk_color, buf, screen_buffer + v16->rect.uly * (scr_size.lrx - scr_size.ulx + 1) + v16->rect.ulx);
                                }
                                buf_to_buf(buf,
                                    width,
                                    height,
                                    width,
                                    screen_buffer + v16->rect.uly * (scr_size.lrx - scr_size.ulx + 1) + v16->rect.ulx,
                                    scr_size.lrx - scr_size.ulx + 1);
                            } else {
                                // To avoid a window into which a background fill briefly
                                // overwrites map content (which can be presented to the
                                // screen in the middle of the operation), build a single
                                // composite buffer that contains the fill and any
                                // overlapping map pixels, and perform exactly one scr_blit
                                // to apply the final content atomically.
                                Rect mapRect;
                                if (win_get_rect(display_win, &mapRect) == 0) {
                                    int inter_ulx = std::max(mapRect.ulx, v16->rect.ulx);
                                    int inter_uly = std::max(mapRect.uly, v16->rect.uly);
                                    int inter_lrx = std::min(mapRect.lrx, v16->rect.lrx);
                                    int inter_lry = std::min(mapRect.lry, v16->rect.lry);

                                    if (inter_lrx >= inter_ulx && inter_lry >= inter_uly) {
                                        // Overlap exists - create a composite buffer
                                        int compW = width;
                                        int compH = height;
                                        unsigned char* compBuf = (unsigned char*)mem_malloc((size_t)compW * (size_t)compH);
                                        if (compBuf != NULL) {
                                            // Copy the fill into the composite buffer
                                            for (int r = 0; r < compH; r++) {
                                                memcpy(compBuf + r * compW, buf + r * width, compW);
                                            }

                                            // Overlay the overlapping portion from the display buffer
                                            int inter_w = inter_lrx - inter_ulx + 1;
                                            int inter_h = inter_lry - inter_uly + 1;
                                            unsigned char* mapBuf = win_get_buf(display_win);
                                            if (mapBuf != NULL) {
                                                int mapPitch = mapRect.lrx - mapRect.ulx + 1;
                                                patchlog_write("DEBUG_COPY", "mapPitch=%d mapRect=(%d,%d,%d,%d) vRect=(%d,%d,%d,%d) inter=(%d,%d,%d,%d) compW=%d compH=%d src=%p comp=%p", mapPitch, mapRect.ulx, mapRect.uly, mapRect.lrx, mapRect.lry, v16->rect.ulx, v16->rect.uly, v16->rect.lrx, v16->rect.lry, inter_ulx, inter_uly, inter_lrx, inter_lry, compW, compH, mapBuf, compBuf);
                                                for (int r = 0; r < inter_h; r++) {
                                                    unsigned char* srcRow = mapBuf + (inter_uly + r) * mapPitch + inter_ulx;
                                                    unsigned char* dstRow = compBuf + (inter_uly - v16->rect.uly + r) * compW + (inter_ulx - v16->rect.ulx);
                                                    patchlog_write("DEBUG_COPY_ROW", "r=%d srcRow=%p dstRow=%p", r, srcRow, dstRow);
                                                    memcpy(dstRow, srcRow, inter_w);
                                                }
                                            }

                                            // Apply composite in a single blit so there is no window
                                            // where the fill exists without the restored map content.
                                            scr_blit(compBuf, compW, compH, 0, 0, compW, compH, v16->rect.ulx, v16->rect.uly);
                                            patchlog_write("DEBUG_MEM", "compBuf=%p compW=%d compH=%d buf=%p", compBuf, compW, compH, buf);
                                            mem_free(compBuf);
                                        } else {
                                            // Fallback to original behavior if allocation fails
                                            patchlog_write("DEBUG_MEM", "fallback buf=%p width=%d height=%d", buf, width, height);
                                            scr_blit(buf, width, height, 0, 0, width, height, v16->rect.ulx, v16->rect.uly);
                                            unsigned char* mapBuf = win_get_buf(display_win);
                                            if (mapBuf != NULL) {
                                                int inter_w = inter_lrx - inter_ulx + 1;
                                                int inter_h = inter_lry - inter_uly + 1;
                                                unsigned char* src = mapBuf + inter_uly * (mapRect.lrx - mapRect.ulx + 1) + inter_ulx;
                                                scr_blit(src, mapRect.lrx - mapRect.ulx + 1, 0, inter_ulx, inter_uly, inter_w, inter_h, inter_ulx, inter_uly);
                                            }
                                        }
                                    } else {
                                        // No overlap - try merging adjacent rects with the same vertical span
                                        rectdata* group_start = v16;
                                        rectdata* group_end = v16;
                                        int group_lrx = v16->rect.lrx;
                                        rectdata* probe = v16->next;
                                        while (probe != NULL && probe->rect.uly == v16->rect.uly && probe->rect.lry == v16->rect.lry && probe->rect.ulx <= group_lrx + 1) {
                                            group_lrx = std::max(group_lrx, probe->rect.lrx);
                                            group_end = probe;
                                            probe = probe->next;
                                        }

                                        if (group_start == group_end) {
                                            patchlog_write("DEBUG_MEM", "no-overlap buf=%p width=%d height=%d", buf, width, height);
                                            scr_blit(buf, width, height, 0, 0, width, height, v16->rect.ulx, v16->rect.uly);
                                        } else {
                                            // Attempt merged composite blit for the whole group
                                            if (!merge_fill_group_and_blit(group_start, group_end, bk_color)) {
                                                // Fallback: process each rect in the group individually
                                                rectdata* g = group_start;
                                                while (true) {
                                                    int gw = g->rect.lrx - g->rect.ulx + 1;
                                                    int gh = g->rect.lry - g->rect.uly + 1;
                                                    unsigned char* gbuf = (unsigned char*)mem_malloc(gw * gh);
                                                    if (gbuf != NULL) {
                                                        buf_fill(gbuf, gw, gh, gw, bk_color);
                                                        if (patchlog_verbose()) {
                                                            patchlog_write("WIN_FILL_RECT", "dest=%d,%d w=%d h=%d bk_color=%d srcPtr=%p", g->rect.ulx, g->rect.uly, gw, gh, bk_color, gbuf);
                                                        }
                                                        scr_blit(gbuf, gw, gh, 0, 0, gw, gh, g->rect.ulx, g->rect.uly);
                                                        mem_free(gbuf);
                                                    }

                                                    if (g == group_end) break;
                                                    g = g->next;
                                                }
                                            }

                                            // Advance v16 to the end of the group; the loop bottom will advance to group_end->next
                                            v16 = group_end;
                                        }
                                    }
                                } else {
                                    // Couldn't get display rect - fall back to simple blit
                                    patchlog_write("DEBUG_MEM", "no-map-rect buf=%p width=%d height=%d", buf, width, height);
                                    scr_blit(buf, width, height, 0, 0, width, height, v16->rect.ulx, v16->rect.uly);
                                }

                                /* deferred free - moved to end of block */
                            }
                        }

                        patchlog_write("DEBUG_MEM", "freeing buf=%p", buf);
                        mem_free(buf);
                    }
                    v16 = v16->next;
                }
            }

            v23 = v26;
            while (v23) {
                v24 = v23->next;

                if (buffering && !a3) {
                    if (patchlog_verbose()) {
                        patchlog_write("WIN_SCRBLIT", "dest=%d,%d w=%d h=%d srcPtr=%p",
                            v23->rect.ulx, v23->rect.uly, v23->rect.lrx - v23->rect.ulx + 1, v23->rect.lry - v23->rect.uly + 1,
                            screen_buffer + v23->rect.ulx + (scr_size.lrx - scr_size.ulx + 1) * v23->rect.uly);
                    }
                    scr_blit(
                        screen_buffer + v23->rect.ulx + (scr_size.lrx - scr_size.ulx + 1) * v23->rect.uly,
                        scr_size.lrx - scr_size.ulx + 1,
                        v23->rect.lry - v23->rect.uly + 1,
                        0,
                        0,
                        v23->rect.lrx - v23->rect.ulx + 1,
                        v23->rect.lry - v23->rect.uly + 1,
                        v23->rect.ulx,
                        v23->rect.uly);
                }

                rect_free(v23);

                v23 = v24;
            }

            if (!doing_refresh_all && a3 == NULL && mouse_hidden() == 0) {
                if (mouse_in(rect->ulx, rect->uly, rect->lrx, rect->lry)) {
                    mouse_show();
                }
            }
        } else {
            rect_free(v26);
        }
    }
}

// 0x4C3654
void win_refresh_all(Rect* rect)
{
    if (GNW_win_init_flag) {
        refresh_all(rect, NULL);
    }
}

// 0x4C3668
static void win_clip(Window* w, RectPtr* rectListNodePtr, unsigned char* a3)
{
    int win;

    for (win = window_index[w->id] + 1; win < num_windows; win++) {
        if (*rectListNodePtr == NULL) {
            break;
        }

        // TODO: Review.
        Window* w = window[win];
        if (!(w->flags & WINDOW_HIDDEN)) {
            if (!buffering || !(w->flags & WINDOW_TRANSPARENT)) {
                rect_clip_list(rectListNodePtr, &(w->rect));
            } else {
                if (!doing_refresh_all) {
                    GNW_win_refresh(w, &(w->rect), NULL);
                    rect_clip_list(rectListNodePtr, &(w->rect));
                }
            }
        }
    }

    if (a3 == screen_buffer || a3 == NULL) {
        if (mouse_hidden() == 0) {
            Rect rect;
            mouse_get_rect(&rect);
            rect_clip_list(rectListNodePtr, &rect);
        }
    }
}

// 0x4C3714
void win_drag(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    win_show(win);

    Rect rect;
    rectCopy(&rect, &(w->rect));

    GNW_do_bk_process();

    if (vcr_update() != 3) {
        mouse_info();
    }

    if ((w->flags & WINDOW_MANAGED) && (w->rect.ulx & 3)) {
        win_move(w->id, w->rect.ulx, w->rect.uly);
    }
}

// 0x4C38B0
void win_get_mouse_buf(unsigned char* a1)
{
    Rect rect;
    mouse_get_rect(&rect);
    refresh_all(&rect, a1);
}

// 0x4C38CC
static void refresh_all(Rect* rect, unsigned char* a2)
{
    doing_refresh_all = 1;

    for (int index = 0; index < num_windows; index++) {
        GNW_win_refresh(window[index], rect, a2);
    }

    doing_refresh_all = 0;

    if (a2 == NULL) {
        if (!mouse_hidden()) {
            if (mouse_in(rect->ulx, rect->uly, rect->lrx, rect->lry)) {
                mouse_show();
            }
        }
    }
}

// 0x4C3940
Window* GNW_find(int win)
{
    int v0;

    if (win == -1) {
        return NULL;
    }

    v0 = window_index[win];
    if (v0 == -1) {
        return NULL;
    }

    return window[v0];
}

// 0x4C3968
unsigned char* win_get_buf(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return NULL;
    }

    if (w == NULL) {
        return NULL;
    }

    return w->buffer;
}

// 0x4C3984
int win_get_top_win(int x, int y)
{
    for (int index = num_windows - 1; index >= 0; index--) {
        Window* w = window[index];
        if (x >= w->rect.ulx && x <= w->rect.lrx
            && y >= w->rect.uly && y <= w->rect.lry) {
            return w->id;
        }
    }

    return -1;
}

// 0x4C39D0
int win_width(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return -1;
    }

    if (w == NULL) {
        return -1;
    }

    return w->width;
}

// 0x4C39EC
int win_height(int win)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return -1;
    }

    if (w == NULL) {
        return -1;
    }

    return w->height;
}

// 0x4C3A08
int win_get_rect(int win, Rect* rect)
{
    Window* w = GNW_find(win);

    if (!GNW_win_init_flag) {
        return -1;
    }

    if (w == NULL) {
        return -1;
    }

    rectCopy(rect, &(w->rect));

    return 0;
}

// 0x4C3A34
int win_check_all_buttons()
{
    if (!GNW_win_init_flag) {
        return -1;
    }

    int v1 = -1;
    for (int index = num_windows - 1; index >= 1; index--) {
        if (GNW_check_buttons(window[index], &v1) == 0) {
            break;
        }

        if ((window[index]->flags & WINDOW_MODAL) != 0) {
            break;
        }
    }

    return v1;
}

// 0x4C3A94
Button* GNW_find_button(int btn, Window** windowPtr)
{
    for (int index = 0; index < num_windows; index++) {
        Window* w = window[index];
        Button* button = w->buttonListHead;
        while (button != NULL) {
            if (button->id == btn) {
                if (windowPtr != NULL) {
                    *windowPtr = w;
                }

                return button;
            }
            button = button->next;
        }
    }

    return NULL;
}

// 0x4C3AEC
int GNW_check_menu_bars(int a1)
{
    if (!GNW_win_init_flag) {
        return -1;
    }

    int v1 = a1;
    for (int index = num_windows - 1; index >= 1; index--) {
        Window* w = window[index];
        if (w->menuBar != NULL) {
            for (int pulldownIndex = 0; pulldownIndex < w->menuBar->pulldownsLength; pulldownIndex++) {
                if (v1 == w->menuBar->pulldowns[pulldownIndex].keyCode) {
                    v1 = GNW_process_menu(w->menuBar, pulldownIndex);
                    break;
                }
            }
        }

        if ((w->flags & 0x10) != 0) {
            break;
        }
    }

    return v1;
}

// 0x4C4190
void win_set_minimized_title(const char* title)
{
    if (title == NULL) {
        return;
    }

    strncpy(GNW95_title, title, 256);
    GNW95_title[256 - 1] = '\0';

    if (gSdlWindow != nullptr) {
        SDL_SetWindowTitle(gSdlWindow, GNW95_title);
    }
}

// 0x4C4204
void win_set_trans_b2b(int id, WindowBlitProc* trans_b2b)
{
    Window* w = GNW_find(id);

    if (!GNW_win_init_flag) {
        return;
    }

    if (w == NULL) {
        return;
    }

    if ((w->flags & WINDOW_TRANSPARENT) == 0) {
        return;
    }

    if (trans_b2b != NULL) {
        w->blitProc = trans_b2b;
    } else {
        w->blitProc = trans_buf_to_buf;
    }
}

// 0x4C422C
static void* colorOpen(const char* path)
{
    return db_fopen(path, "rb");
}

// 0x4C4298
static int colorRead(void* handle, void* buf, size_t count)
{
    return db_fread(buf, 1, count, reinterpret_cast<DB_FILE*>(handle));
}

// 0x4C42A0
static int colorClose(void* handle)
{
    return db_fclose(reinterpret_cast<DB_FILE*>(handle));
}

// 0x4C42B8
bool GNWSystemError(const char* text)
{
#if defined(__APPLE__) && TARGET_OS_IOS
    // On iOS, modal dialogs block the main thread and cause watchdog timeout (0x8BADF00D).
    // Just log the error and return - the caller should handle the failure.
    SDL_Log("FATAL ERROR: %s", text);
    return true;
#else
    SDL_Cursor* prev = SDL_GetCursor();
    SDL_Cursor* cursor = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
    SDL_SetCursor(cursor);
    SDL_ShowCursor();
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, NULL, text, NULL);
    SDL_HideCursor();
    SDL_SetCursor(prev);
    SDL_DestroyCursor(cursor);
    return true;
#endif
}

} // namespace fallout
