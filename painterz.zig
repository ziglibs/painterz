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

        /// Draws a line from (x0, y0) to (x1, y1).
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

        /// Draws a circle at local (x0, y0) with the given radius.
        pub fn drawCircle(self: *Self, x0: isize, y0: isize, radius: usize, color: Pixel) void {
            // taken from https://de.wikipedia.org/wiki/Bresenham-Algorithmus
            const iradius = @intCast(isize, radius);

            var f = 1 - iradius;
            var ddF_x: isize = 0;
            var ddF_y: isize = -2 * iradius;
            var x: isize = 0;
            var y: isize = iradius;

            self.setPixel(x0, y0 + iradius, color);
            self.setPixel(x0, y0 - iradius, color);
            self.setPixel(x0 + iradius, y0, color);
            self.setPixel(x0 - iradius, y0, color);

            while (x < y) {
                if (f >= 0) {
                    y -= 1;
                    ddF_y += 2;
                    f += ddF_y;
                }
                x += 1;
                ddF_x += 2;
                f += ddF_x + 1;

                self.setPixel(x0 + x, y0 + y, color);
                self.setPixel(x0 - x, y0 + y, color);
                self.setPixel(x0 + x, y0 - y, color);
                self.setPixel(x0 - x, y0 - y, color);
                self.setPixel(x0 + y, y0 + x, color);
                self.setPixel(x0 - y, y0 + x, color);
                self.setPixel(x0 + y, y0 - x, color);
                self.setPixel(x0 - y, y0 - x, color);
            }
        }

        /// Draws the outline of a rectangle.
        pub fn drawRectangle(self: *Self, x: isize, y: isize, width: usize, height: usize, color: Pixel) void {
            var i: isize = undefined;

            const iwidth = @intCast(isize, width) - 1;
            const iheight = @intCast(isize, height) - 1;

            // top
            i = 0;
            while (i <= iwidth) : (i += 1) {
                self.setPixel(x + i, y, color);
            }

            // bottom
            i = 0;
            while (i <= iwidth) : (i += 1) {
                self.setPixel(x + i, y + iheight, color);
            }

            // left
            i = 1;
            while (i < iheight) : (i += 1) {
                self.setPixel(x, y + i, color);
            }

            // right
            i = 1;
            while (i < iheight) : (i += 1) {
                self.setPixel(x + iwidth, y + i, color);
            }
        }

        /// Fills a rectangle area.
        pub fn fillRectangle(self: *Self, x: isize, y: isize, width: usize, height: usize, color: Pixel) void {
            const xlimit = x + @intCast(isize, width);
            const ylimit = y + @intCast(isize, height);

            var py = y;
            while (py < ylimit) : (py += 1) {
                var px = x;
                while (px < xlimit) : (px += 1) {
                    self.setPixel(px, py, color);
                }
            }
        }

        /// Copies pixels from a source rectangle (src_x, src_y, width, height) into the framebuffer at (dest_x, dest_y, width, height).
        pub fn copyRectangle(
            self: *Self,
            dest_x: isize,
            dest_y: isize,
            src_x: isize,
            src_y: isize,
            width: usize,
            height: usize,
            source: anytype,
            comptime getPixelImpl: fn (@TypeOf(source), x: isize, y: isize) Pixel,
        ) void {
            const iwidth = @intCast(isize, width);
            const iheight = @intCast(isize, height);

            var dy: isize = 0;
            while (dy < iheight) : (dy += 1) {
                var dx: isize = 0;
                while (dx < width) : (dx += 1) {
                    self.setPixel(
                        dest_x + dx,
                        dest_y + dy,
                        getPixelImpl(source, src_x + dx, src_y + dy),
                    );
                }
            }
        }
    };
}

comptime {
    const T = Canvas(void, void, struct {
        fn h(fb: void, x: isize, y: isize, pix: void) void {}
    }.h);

    std.meta.refAllDecls(T);
}
