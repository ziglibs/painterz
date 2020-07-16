# painterz
The idea of this library is to provide platform-independent, embedded-feasible implementations of several drawing primitives.

The library exports a generic `Canvas` type which is specialized on a `setPixel` function that will put pixels of type `Color` onto a `Framebuffer`.
It's currently not possible or planned to do blending, but alpha test could be implemented by ignoring certain color values in the `setPixel` function.

## Usage Example
```zig
const Pixel = packed struct {
    r: u8, g: u8, b: u8, a: u8
};

const Framebuffer = struct {
    buffer: []Pixel,

    fn setPixel(fb: @This(), x: isize, y: isize, c: Pixel) void {
        if (x < 0 or y < 0) return;
        if (x >= 100 or y >= 100) return;
        fb.buffer[100 * std.math.absCast(y) + std.math.absCast(x)] = c;
    }
};

var canvas = painterz.Canvas(Framebuffer, Pixel, Framebuffer.setPixel).init(Framebuffer{
    .buffer = …,
});

canvas.drawLine(100, 120, 110, 90, Pixel{
    .r = 0xFF,
    .g = 0x00,
    .b = 0xFF,
    .a = 0xFF,
});
```