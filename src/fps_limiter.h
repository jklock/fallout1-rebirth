#ifndef FALLOUT_FPS_LIMITER_H_
#define FALLOUT_FPS_LIMITER_H_

namespace fallout {

class FpsLimiter {
public:
    FpsLimiter(unsigned int fps = 60);
    void mark();
    void throttle() const;
    void setFps(unsigned int fps);
    unsigned int getFps() const { return _fps; }
    void setEnabled(bool enabled);
    bool isEnabled() const { return _enabled; }

private:
    unsigned int _fps;
    unsigned int _ticks;
    bool _enabled;
};

} // namespace fallout

#endif /* FALLOUT_FPS_LIMITER_H_ */
