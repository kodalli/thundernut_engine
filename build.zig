const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tmp",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zmath = @import("libs/zig-gamedev/libs/zmath/build.zig");
    const zmath_pkg = zmath.package(b, target, optimize, .{
        .options = .{ .enable_cross_platform_determinism = true },
    });

    const zglfw = @import("libs/zig-gamedev/libs/zglfw/build.zig");
    const zglfw_pkg = zglfw.package(b, target, optimize, .{});

    const zopengl = @import("libs/zig-gamedev/libs/zopengl/build.zig");
    const zopengl_pkg = zopengl.package(b, target, optimize, .{
        .options = .{
            .api = .raw_bindings,
        },
    });

    zmath_pkg.link(exe);
    zglfw_pkg.link(exe);
    zopengl_pkg.link(exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
