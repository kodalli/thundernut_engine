const glfw = @import("zglfw");
const std = @import("std");
const gl = @import("gl");
const utils = @import("libs/utils.zig");
const zmath = @import("zmath");
const zmesh = @import("zmesh");
const renderer = @import("libs/renderer/mesh_renderer.zig");
const shader = @import("libs/renderer/shaders.zig");
const cam = @import("libs/renderer/camera.zig");
const callbacks = @import("libs/callbacks.zig");
const zstbi = @import("zstbi");
const skybox = @import("libs/renderer/skybox.zig");

const print = std.debug.print;
pub const GLProc = *const fn () callconv(.C) void;

fn getProcAddress(load_ctx: GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = load_ctx;
    return glfw.getProcAddress(proc);
}

fn setupWindow(width: i32, height: i32) !*glfw.Window {
    const gl_major = 4;
    const gl_minor = 0;

    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const window = try glfw.Window.create(width, height, "ThunderNut Engine", null);
    glfw.makeContextCurrent(window);

    window.setInputMode(.cursor, .disabled);

    return window;
}

pub fn main() !void {
    try run();
}

pub const World = struct {
    deltaTime: f64 = 0,
    lastTime: f64 = 0,

    pub fn updateDeltaTime(self: *World, time: f64) void {
        self.deltaTime = time - self.lastTime;
        self.lastTime = time;
    }
};

inline fn modelViewProjectionMat(translation: zmath.Mat, rotation: zmath.Mat, viewProjMat: zmath.Mat) zmath.Mat {
    const transformMat = zmath.mul(rotation, translation);
    const res = zmath.mul(transformMat, viewProjMat);
    return res;
}

fn loadSkybox(allocator: std.mem.Allocator) !skybox.Cubemap {
    var files = [_][:0]const u8{
        "../assets/skybox/right.jpg",
        "../assets/skybox/left.jpg",
        "../assets/skybox/top.jpg",
        "../assets/skybox/bottom.jpg",
        "../assets/skybox/front.jpg",
        "../assets/skybox/back.jpg",
    };

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    for (files, 0..files.len) |file, i| {
        const str = try std.fs.cwd().realpathAlloc(alloc, file);
        const as_slice = @as([:0]const u8, @ptrCast(str));
        std.log.debug("path: {s}", .{as_slice});
        files[i] = as_slice;
    }

    const cubemap = try skybox.Cubemap.init(files);
    return cubemap;
}

fn partialViewMat(viewMat: zmath.Mat) zmath.Mat {
    var partialView = viewMat;
    partialView[0][3] = 0;
    partialView[1][3] = 0;
    partialView[2][3] = 0;
    partialView[3] = zmath.splat(zmath.Vec, 0);
    return partialView;
}

fn run() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const width = 1280;
    const height = 720;
    const window = try setupWindow(width, height);
    defer window.destroy();

    const load_ctx: GLProc = undefined;
    try gl.load(load_ctx, getProcAddress);

    gl.viewport(0, 0, width, height);
    gl.enable(gl.DEPTH_TEST);

    const shaderProgram = shader.loadShaders(utils.vertexShaderSource, utils.fragmentShaderSource);
    defer shader.unloadShaders(shaderProgram);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    zstbi.init(allocator);
    defer zstbi.deinit();

    var mesh = try renderer.createMesh(allocator);
    const meshes = [_]renderer.Mesh{ mesh, mesh };
    defer mesh.deinit();

    var skyboxMesh = try loadSkybox(allocator);
    defer skyboxMesh.deinit();

    callbacks.initCallbackHandler(window, allocator);
    defer callbacks.deinitCallbackHandler();
    //try callbacks.input.addCallback(updateCamera);

    var world: World = .{};
    var camera = cam.Camera.init(0, 1.5, -7);
    const projectionMat = camera.perspectiveMatrix(window.getSize());
    var viewMat = camera.viewMatrix();

    std.log.debug("projectionMat: {any}\nviewMat: {any}\n", .{ projectionMat, viewMat });

    const modelLoc = gl.getUniformLocation(shaderProgram, "modelViewProjection");

    const translationMat1 = zmath.translation(2, 2, 2);
    const translationMat2 = zmath.translation(0, 0, 0);

    var modelArrays = std.ArrayList([*c]const f32).init(allocator);
    defer modelArrays.deinit();

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const time = glfw.getTime();
        world.updateDeltaTime(time);
        callbacks.input.updateInput(window);
        viewMat = camera.updateCamera(&callbacks.input, &world);
        const partialView = partialViewMat(viewMat);

        const angle = @as(f32, @floatCast(time));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotationMat = zmath.mul(rotY, rotX);

        const viewProjMat = zmath.mul(viewMat, projectionMat);
        const modelMat1 = modelViewProjectionMat(translationMat1, rotationMat, viewProjMat);
        const modelMat2 = modelViewProjectionMat(translationMat2, rotationMat, viewProjMat);
        try modelArrays.append(zmath.arrNPtr(&modelMat1));
        try modelArrays.append(zmath.arrNPtr(&modelMat2));

        renderer.renderMeshes(&meshes, modelArrays, modelLoc, shaderProgram);
        modelArrays.clearAndFree();

        skyboxMesh.render(projectionMat, partialView);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
