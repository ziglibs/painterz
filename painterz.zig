const std = @import("std");

fn sign(v: anytype) @TypeOf(v) {
    if (v < 0) return -1;
    if (v > 0) return 1;
    return 0;
}

pub fn Canvas(
    comptime Framebuffer: type,
    comptime Pixel: type,
    comptime setPixelImpl: fn (Framebuffer, x: isize, y: isize, col: Pixel) void,
) type {
    return struct {
        const Self = @This();

        framebuffer: Framebuffer,

        pub fn init(fb: Framebuffer) Self {
            return Self{
                .framebuffer = fb,
            };
        }

        /// Sets a pixel on the framebuffer.
        pub fn setPixel(self: *Self, x: isize, y: isize, color: Pixel) void {
            setPixelImpl(self.framebuffer, x, y, color);
        }

        pub fn drawLine(self: *Self, x0: isize, y0: isize, x1: isize, y1: isize, color: Pixel) void {
            // taken from https://de.wikipedia.org/wiki/Bresenham-Algorithmus
            var dx = x1 - x0;
            var dy = y1 - y0;

            const incx = sign(dx);
            const incy = sign(dy);
            if (dx < 0) {
                dx = -dx;
            }
            if (dy < 0) {
                dy = -dy;
            }

            var deltaslowdirection: isize = undefined;
            var deltafastdirection: isize = undefined;
            var pdx: isize = undefined;
            var pdy: isize = undefined;
            var ddx: isize = undefined;
            var ddy: isize = undefined;

            if (dx > dy) {
                pdx = incx;
                pdy = 0;
                ddx = incx;
                ddy = incy;
                deltaslowdirection = dy;
                deltafastdirection = dx;
            } else {
                pdx = 0;
                pdy = incy;
                ddx = incx;
                ddy = incy;
                deltaslowdirection = dx;
                deltafastdirection = dy;
            }

            var x = x0;
            var y = y0;
            var err = @divTrunc(deltafastdirection, 2);
            self.setPixel(x, y, color);

            var t: isize = 0;
            while (t < deltafastdirection) : (t += 1) {
                err -= deltaslowdirection;
                if (err < 0) {
                    err += deltafastdirection;
                    x += ddx;
                    y += ddy;
                } else {
                    x += pdx;
                    y += pdy;
                }
                self.setPixel(x, y, color);
            }
        }
    };
}
