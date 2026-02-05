# Build static lib only
set(BUILD_SHARED_LIBS OFF)
set(SDL_SHARED OFF)
set(SDL_STATIC ON)

# Fixes _ftol2_sse already defined
set(SDL_LIBC ON)

include(FetchContent)

FetchContent_Declare(sdl3
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL"
    GIT_TAG "release-3.2.4"
)

FetchContent_MakeAvailable(sdl3)

set(SDL3_INCLUDE_DIRS ${sdl3_SOURCE_DIR}/include PARENT_SCOPE)
set(SDL3_LIBRARIES SDL3::SDL3-static PARENT_SCOPE)
