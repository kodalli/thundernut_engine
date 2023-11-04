const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Add your executable and configure with
    // target and optimize, specify your root file (ex. main.zig)
    const exe = b.addExecutable(.{
        .name = "tmp",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zglfw = @import("libs/zig-gamedev/libs/zglfw/build.zig");
    const zglfw_pkg = zglfw.package(b, target, optimize, .{});
    zglfw_pkg.link(exe);

    const zmath = @import("libs/zig-gamedev/libs/zmath/build.zig");
    const zmath_pkg = zmath.package(b, target, optimize, .{
        .options = .{ .enable_cross_platform_determinism = true },
    });
    zmath_pkg.link(exe);

    const zmesh = @import("libs/zig-gamedev/libs/zmesh/build.zig");
    const zmesh_pkg = zmesh.package(b, target, optimize, .{});
    zmesh_pkg.link(exe);

    const zphysics = @import("libs/zig-gamedev/libs/zphysics/build.zig");
    const zphysics_pkg = zphysics.package(b, target, optimize, .{
        .options = .{
            .use_double_precision = false,
            .enable_debug_renderer = true,
            .enable_asserts = true,
        },
    });
    zphysics_pkg.link(exe);

    // Same as above for our GL module,
    // because we copied the GL code into the project
    // we instead just create the module inline
    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "libs/gl41.zig" },
    }));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(b.getInstallStep());
    test_step.dependOn(&run_unit_tests.step);
}
