const std = @import("std");
const painterz = @import("painterz");

const TestColor = enum {
    red,
    black,
};

const TestFramebuffer = struct {
    fn set_pixel(fb: TestFramebuffer, x: isize, y: isize, pix: TestColor) void {
        _ = fb;
        _ = x;
        _ = y;
        _ = pix;
    }
};

const TestBitmap = struct {
    fn get_opaque_pixel(bmp: TestBitmap, x: isize, y: isize) TestColor {
        _ = bmp;
        return switch (@mod(x ^ y, 2)) {
            0 => .black,
            1 => .red,
            else => unreachable,
        };
    }

    fn get_transparent_pixel(bmp: TestBitmap, x: isize, y: isize) ?TestColor {
        _ = bmp;
        return switch (@mod(x ^ y, 4)) {
            0, 2 => return null,
            1 => .black,
            3 => .red,
            else => unreachable,
        };
    }
};

const TestCanvas = painterz.Canvas(TestFramebuffer, TestColor, TestFramebuffer.set_pixel);

test {
    std.testing.refAllDeclsRecursive(TestCanvas);
}

test "TestCanvas.setPixel" {
    const fb = TestCanvas.init(.{});
    fb.setPixel(10, 20, .red);
}

test "TestCanvas.drawLine" {
    const fb = TestCanvas.init(.{});
    fb.drawLine(10, 20, 30, 40, .red);
}

test "TestCanvas.drawPolygon" {
    const fb = TestCanvas.init(.{});
    fb.drawPolygon(
        10,
        20,
        .black,
        painterz.Point,
        &.{
            painterz.Point{ .x = 10, .y = 40 },
            painterz.Point{ .x = 50, .y = 20 },
            painterz.Point{ .x = 100, .y = 80 },
            painterz.Point{ .x = 70, .y = 100 },
        },
    );
}

test "TestCanvas.drawCircle" {
    const fb = TestCanvas.init(.{});
    fb.drawCircle(100, 100, 45, .red);
}

test "TestCanvas.drawRectangle" {
    const fb = TestCanvas.init(.{});
    fb.drawRectangle(100, 100, 45, 20, .red);
}

test "TestCanvas.fillRectangle" {
    const fb = TestCanvas.init(.{});
    fb.fillRectangle(100, 100, 45, 20, .red);
}

test "TestCanvas.fillPolygon" {
    const fb = TestCanvas.init(.{});
    fb.fillPolygon(
        10,
        20,
        .black,
        painterz.Point,
        &.{
            painterz.Point{ .x = 10, .y = 40 },
            painterz.Point{ .x = 50, .y = 20 },
            painterz.Point{ .x = 100, .y = 80 },
            painterz.Point{ .x = 70, .y = 100 },
        },
    );
}

test "TestCanvas.copyRectangle(without transparency)" {
    const fb = TestCanvas.init(.{});
    fb.copyRectangle(
        10,
        20,
        11,
        12,
        30,
        40,
        false,
        TestBitmap{},
        TestBitmap.get_opaque_pixel,
    );
}

test "TestCanvas.copyRectangle(with transparency)" {
    const fb = TestCanvas.init(.{});
    fb.copyRectangle(
        10,
        20,
        11,
        12,
        30,
        40,
        true,
        TestBitmap{},
        TestBitmap.get_transparent_pixel,
    );
}

test "TestCanvas.copyRectangleStretched(without transparency)" {
    const fb = TestCanvas.init(.{});
    fb.copyRectangleStretched(
        10,
        20,
        40,
        30,
        11,
        12,
        30,
        40,
        false,
        TestBitmap{},
        TestBitmap.get_opaque_pixel,
    );
}

test "TestCanvas.copyRectangleStretched(with transparency)" {
    const fb = TestCanvas.init(.{});
    fb.copyRectangleStretched(
        10,
        20,
        40,
        30,
        11,
        12,
        30,
        40,
        true,
        TestBitmap{},
        TestBitmap.get_transparent_pixel,
    );
}
