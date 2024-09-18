const std = @import("std");
const painterz = @import("painterz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const width = 110;
    const height = 120;

    const framebuffer = Framebuffer{
        .width = width,
        .height = height,
        .data = try allocator.alloc(Color, width * height),
    };
    defer allocator.free(framebuffer.data);

    @memset(framebuffer.data, Color.white);

    const canvas = Canvas.init(framebuffer);

    canvas.drawLine(10, 10, 50, 50, Color.red);
    canvas.drawLine(10, 10, 50, 30, Color.red);
    canvas.drawLine(10, 10, 30, 50, Color.red);

    canvas.drawLine(50, 10, 10, 50, Color.blue);
    canvas.drawLine(50, 10, 30, 50, Color.blue);
    canvas.drawLine(50, 10, 10, 30, Color.blue);

    canvas.drawRectangle(5, 5, 50, 50, Color.black);

    canvas.drawCircle(80, 30, 20, Color.green);

    canvas.fillRectangle(70, 20, 20, 20, Color.black);

    canvas.drawPolygon(
        5,
        60,
        Color.magenta,
        painterz.Point,
        &.{
            painterz.Point.new(20, 0),
            painterz.Point.new(30, 0),
            painterz.Point.new(45, 10),
            painterz.Point.new(35, 30),
            painterz.Point.new(35, 40),
            painterz.Point.new(20, 35),
            painterz.Point.new(15, 15),
            painterz.Point.new(0, 5),
        },
    );

    canvas.fillPolygon(
        5,
        60,
        Color.cyan,
        painterz.Point,
        &.{
            painterz.Point.new(22, 2),
            painterz.Point.new(30, 2),
            painterz.Point.new(42, 12),
            painterz.Point.new(33, 30),
            painterz.Point.new(33, 38),
            painterz.Point.new(22, 33),
            painterz.Point.new(17, 13),
            painterz.Point.new(5, 6),
        },
    );

    canvas.copyRectangle(
        60,
        60,
        0,
        0,
        20,
        20,
        false,
        PatternGenerator{},
        PatternGenerator.get_opaque_pixel,
    );

    canvas.copyRectangle(
        85,
        60,
        0,
        0,
        20,
        20,
        true,
        PatternGenerator{},
        PatternGenerator.get_transparent_pixel,
    );

    canvas.copyRectangleStretched(
        60,
        85,
        45,
        12,
        0,
        0,
        20,
        20,
        false,
        PatternGenerator{},
        PatternGenerator.get_opaque_pixel,
    );

    canvas.copyRectangleStretched(
        60,
        100,
        45,
        12,
        0,
        0,
        20,
        20,
        true,
        PatternGenerator{},
        PatternGenerator.get_transparent_pixel,
    );

    var out = try std.fs.cwd().createFile("result.pgm", .{});
    defer out.close();

    try out.writer().print("P6 {} {} 255\n", .{ framebuffer.width, framebuffer.height });
    try out.writeAll(std.mem.sliceAsBytes(framebuffer.data));
}

const Canvas = painterz.Canvas(Framebuffer, Color, Framebuffer.set_pixel);

const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,

    fn from_int(rgb: u24) Color {
        return .{
            .r = @truncate(rgb >> 16),
            .g = @truncate(rgb >> 8),
            .b = @truncate(rgb >> 0),
        };
    }

    const black: Color = from_int(0x000000);
    const red: Color = from_int(0xFF0000);
    const green: Color = from_int(0x00FF00);
    const blue: Color = from_int(0x0000FF);
    const magenta: Color = from_int(0xFF00FF);
    const yellow: Color = from_int(0xFFFF00);
    const cyan: Color = from_int(0x00FFFF);
    const white: Color = from_int(0xFFFFFF);
};

const Framebuffer = struct {
    data: []Color,
    width: usize,
    height: usize,

    fn set_pixel(fb: Framebuffer, x: isize, y: isize, color: Color) void {
        if (x < 0 or x >= fb.width)
            return;
        if (y < 0 or y >= fb.height)
            return;

        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);

        fb.data[fb.width * uy + ux] = color;
    }
};

const PatternGenerator = struct {
    fn get_opaque_pixel(bmp: PatternGenerator, x: isize, y: isize) Color {
        _ = bmp;
        return switch (@mod(x ^ y, 2)) {
            0 => Color.black,
            1 => Color.red,
            else => unreachable,
        };
    }

    fn get_transparent_pixel(bmp: PatternGenerator, x: isize, y: isize) ?Color {
        _ = bmp;
        return switch (@mod(x ^ y, 4)) {
            0, 2 => return null,
            1 => Color.black,
            3 => Color.red,
            else => unreachable,
        };
    }
};
