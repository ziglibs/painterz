const std = @import("std");

fn sign(v: anytype) @TypeOf(v) {
    if (v < 0) return -1;
    if (v > 0) return 1;
    return 0;
}

pub const Point = struct {
    x: isize,
    y: isize,

    pub fn new(x: isize, y: isize) Point {
        return .{ .x = x, .y = y };
    }
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
        pub fn setPixel(self: Self, x: isize, y: isize, color: Pixel) void {
            setPixelImpl(self.framebuffer, x, y, color);
        }

        /// Draws a line from (x0, y0) to (x1, y1).
        pub fn drawLine(self: Self, x0: isize, y0: isize, x1: isize, y1: isize, color: Pixel) void {
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
        pub fn drawCircle(self: Self, x0: isize, y0: isize, radius: usize, color: Pixel) void {
            // taken from https://de.wikipedia.org/wiki/Bresenham-Algorithmus
            const iradius: isize = @intCast(radius);

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
        pub fn drawRectangle(self: Self, x: isize, y: isize, width: usize, height: usize, color: Pixel) void {
            var i: isize = undefined;

            const iwidth = @as(isize, @intCast(width)) - 1;
            const iheight = @as(isize, @intCast(height)) - 1;

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
        pub fn fillRectangle(self: Self, x: isize, y: isize, width: usize, height: usize, color: Pixel) void {
            const xlimit = x + @as(isize, @intCast(width));
            const ylimit = y + @as(isize, @intCast(height));

            var py = y;
            while (py < ylimit) : (py += 1) {
                var px = x;
                while (px < xlimit) : (px += 1) {
                    self.setPixel(px, py, color);
                }
            }
        }

        pub fn drawPolygon(self: Self, offset_x: isize, offset_y: isize, color: Pixel, comptime PointType: type, points: []const PointType) void {
            std.debug.assert(points.len >= 3);

            var j = points.len - 1;
            for (points, 0..) |pt0, i| {
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

        pub fn fillPolygon(self: Self, offset_x: isize, offset_y: isize, color: Pixel, comptime PointType: type, points: []const PointType) void {
            std.debug.assert(points.len >= 3);

            var min_x: isize = std.math.maxInt(isize);
            var min_y: isize = std.math.maxInt(isize);
            var max_x: isize = std.math.minInt(isize);
            var max_y: isize = std.math.minInt(isize);

            for (points) |pt| {
                min_x = @min(min_x, pt.x);
                min_y = @min(min_y, pt.y);
                max_x = @max(max_x, pt.x);
                max_y = @max(max_y, pt.y);
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
                    for (points, 0..) |p0, i| {
                        defer j = i;
                        const p1 = points[j];

                        const fpx: f32 = @floatFromInt(p.x);

                        const fdx: f32 = @floatFromInt((p1.x - p0.x) * (p.y - p0.y));
                        const fdy: f32 = @floatFromInt((p1.y - p0.y));
                        const fp0x: f32 = @floatFromInt(p0.x);

                        if ((p0.y > p.y) != (p1.y > p.y) and fpx < fdx / fdy + fp0x) {
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
            self: Self,
            dest_x: isize,
            dest_y: isize,
            src_x: isize,
            src_y: isize,
            width: usize,
            height: usize,
            comptime enable_transparency: bool,
            source: anytype,
            comptime getPixelImpl: fn (@TypeOf(source), x: isize, y: isize) if (enable_transparency) ?Pixel else Pixel,
        ) void {
            const iwidth: isize = @intCast(width);
            const iheight: isize = @intCast(height);

            _ = iwidth;

            var dy: isize = 0;
            while (dy < iheight) : (dy += 1) {
                var dx: isize = 0;
                while (dx < width) : (dx += 1) {
                    const pixel = getPixelImpl(source, src_x + dx, src_y + dy);
                    if (enable_transparency) {
                        if (pixel) |pix| {
                            self.setPixel(dest_x + dx, dest_y + dy, pix);
                        }
                    } else {
                        self.setPixel(dest_x + dx, dest_y + dy, pixel);
                    }
                }
            }
        }

        /// Copies pixels from a source rectangle into the framebuffer with the destination rectangle.
        /// No pixel interpolation is done
        pub fn copyRectangleStretched(
            self: Self,
            dest_x: isize,
            dest_y: isize,
            dest_width: usize,
            dest_height: usize,
            src_x: isize,
            src_y: isize,
            src_width: usize,
            src_height: usize,
            comptime enable_transparency: bool,
            bitmap: anytype,
            comptime getPixelImpl: fn (@TypeOf(bitmap), x: isize, y: isize) if (enable_transparency) ?Pixel else Pixel,
        ) void {
            const iwidth: isize = @intCast(dest_width);
            const iheight: isize = @intCast(dest_height);

            _ = src_y;

            var dy: isize = 0;
            while (dy < iheight) : (dy += 1) {
                var dx: isize = 0;
                while (dx < iwidth) : (dx += 1) {
                    const sx = src_x + @as(isize, @intFromFloat(std.math.round(@as(f32, @floatFromInt(src_width - 1)) * @as(f32, @floatFromInt(dx)) / @as(f32, @floatFromInt(dest_width - 1)))));
                    const sy = src_x + @as(isize, @intFromFloat(std.math.round(@as(f32, @floatFromInt(src_height - 1)) * @as(f32, @floatFromInt(dy)) / @as(f32, @floatFromInt(dest_height - 1)))));

                    const pixel = getPixelImpl(bitmap, sx, sy);
                    if (enable_transparency) {
                        if (pixel) |pix| {
                            self.setPixel(dest_x + dx, dest_y + dy, pix);
                        }
                    } else {
                        self.setPixel(dest_x + dx, dest_y + dy, pixel);
                    }
                }
            }
        }
    };
}
