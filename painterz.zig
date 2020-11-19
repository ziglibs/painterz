const std = @import("std");

fn sign(v: anytype) @TypeOf(v) {
    if (v < 0) return -1;
    if (v > 0) return 1;
    return 0;
}

pub const Point = struct {
    x: isize,
    y: isize,
};

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

        pub fn drawPolygon(self: *Self, offset_x: isize, offset_y: isize, color: Pixel, points: []const Point) void {
            std.debug.assert(points.len >= 3);

            var j = points.len - 1;
            for (points) |pt0, i| {
                defer j = i;
                const pt1 = points[j];
                self.drawLine(
                    offset_x + pt0.x,
                    offset_y + pt0.y,
                    offset_x + pt1.x,
                    offset_y + pt1.y,
                    color,
                );
            }
        }

        pub fn fillPolygon(self: *Self, offset_x: isize, offset_y: isize, color: Pixel, points: []const Point) void {
            std.debug.assert(points.len >= 3);

            var min_x: isize = std.math.maxInt(isize);
            var min_y: isize = std.math.maxInt(isize);
            var max_x: isize = std.math.minInt(isize);
            var max_y: isize = std.math.minInt(isize);

            for (points) |pt| {
                min_x = std.math.min(min_x, pt.x);
                min_y = std.math.min(min_y, pt.y);
                max_x = std.math.max(max_x, pt.x);
                max_y = std.math.max(max_y, pt.y);
            }

            // std.debug.print("limits: {} {} {} {}\n", .{ min_x, min_y, max_x, max_y });
            // std.time.sleep(1_000_000_000);

            var y: isize = min_y;
            while (y <= max_y) : (y += 1) {
                var x: isize = min_x;
                while (x <= max_x) : (x += 1) {
                    var inside = false;

                    const p = Point{ .x = x, .y = y };

                    // free after https://stackoverflow.com/a/17490923

                    var j = points.len - 1;
                    for (points) |p0, i| {
                        defer j = i;
                        const p1 = points[j];

                        if ((p0.y > p.y) != (p1.y > p.y) and
                            @intToFloat(f32, p.x) < @intToFloat(f32, (p1.x - p0.x) * (p.y - p0.y)) / @intToFloat(f32, (p1.y - p0.y)) + @intToFloat(f32, p0.x))
                        {
                            inside = !inside;
                        }
                    }
                    if (inside) {
                        self.setPixel(offset_x + x, offset_y + y, color);
                    }
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

        /// Copies pixels from a source rectangle into the framebuffer with the destination rectangle.
        /// No pixel interpolation is done
        pub fn copyRectangleStretched(
            self: *Self,
            dest_x: isize,
            dest_y: isize,
            dest_width: usize,
            dest_height: usize,
            src_x: isize,
            src_y: isize,
            src_width: usize,
            src_height: usize,
            bitmap: anytype,
            comptime getPixelImpl: fn (@TypeOf(bitmap), x: isize, y: isize) Pixel,
        ) void {
            const iwidth = @intCast(isize, dest_width);
            const iheight = @intCast(isize, dest_height);

            var dy: isize = 0;
            while (dy < iheight) : (dy += 1) {
                var dx: isize = 0;
                while (dx < iwidth) : (dx += 1) {
                    var sx = src_x + @floatToInt(isize, std.math.round(@intToFloat(f32, src_width - 1) * @intToFloat(f32, dx) / @intToFloat(f32, dest_width - 1)));
                    var sy = src_x + @floatToInt(isize, std.math.round(@intToFloat(f32, src_height - 1) * @intToFloat(f32, dy) / @intToFloat(f32, dest_height - 1)));

                    self.setPixel(
                        dest_x + dx,
                        dest_y + dy,
                        getPixelImpl(bitmap, sx, sy),
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

    std.testing.refAllDecls(T);
}
