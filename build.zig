const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const painterz_mod = b.addModule("painterz", .{
        .root_source_file = b.path("src/painterz.zig"),
    });

    {
        const demo_exe = b.addExecutable(.{
            .name = "painterz-demo",
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
        });
        demo_exe.root_module.addImport("painterz", painterz_mod);
        b.installArtifact(demo_exe);
    }

    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addImport("painterz", painterz_mod);

        const test_run = b.addRunArtifact(test_exe);
        b.getInstallStep().dependOn(&test_run.step);
    }
}
