const std = @import("std");

pub fn build(b: *std.Build) void {
    const painterz_mod = b.addModule("painterz", .{
        .root_source_file = b.path("src/painterz.zig"),
    });

    const test_exe = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
    });
    test_exe.root_module.addImport("painterz", painterz_mod);

    const test_run = b.addRunArtifact(test_exe);

    b.getInstallStep().dependOn(&test_run.step);
}
