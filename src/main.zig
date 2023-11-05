const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const utils = @import("libs/utils.zig");
const zmath = @import("zmath");
const zmesh = @import("zmesh");
const renderer = @import("libs/renderer/mesh_renderer.zig");
const shader = @import("libs/renderer/shaders.zig");

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

    return window;
}

pub fn main() !void {
    try run();
}

const Camera = struct {
    cameraPos: zmath.Vec,
    targetPos: zmath.Vec,
    upDirection: zmath.Vec,
    fov: f32,
    nearPlane: f32,
    farPlane: f32,

    pub fn init(x: f32, y: f32, z: f32) Camera {
        return .{
            .cameraPos = zmath.f32x4(x, y, z, 1),
            .targetPos = zmath.f32x4(0, 0, 0, 1),
            .upDirection = zmath.f32x4(0, 1, 0, 1),
            .fov = 70,
            .nearPlane = 1.0,
            .farPlane = 1000,
        };
    }

    pub fn perspectiveMatrix(self: *Camera, size: [2]i32) [16]f32 {
        const width = @as(f32, @floatFromInt(size[0]));
        const height = @as(f32, @floatFromInt(size[1]));
        const aspect = width / height;
        const perspective = zmath.perspectiveFovRh(self.fov, aspect, self.nearPlane, self.farPlane);
        const perspectiveMat = zmath.matToArr(perspective);
        return perspectiveMat;
    }

    pub fn viewMatrix(self: *Camera) [16]f32 {
        const view = zmath.lookAtRh(self.cameraPos, self.targetPos, self.upDirection);
        const viewMat = zmath.matToArr(view);
        return viewMat;
    }
};

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

    var mesh = try renderer.createMesh(allocator);
    defer mesh.deinit();

    var camera = Camera.init(0, 0, -10);

    const projectionMat = camera.perspectiveMatrix(window.getSize());
    const viewMat = camera.viewMatrix();

    std.log.debug("projectionMat: {any}\nviewMat: {any}\n", .{ projectionMat, viewMat });

    const modelLoc = gl.getUniformLocation(shaderProgram, "model");
    const viewLoc = gl.getUniformLocation(shaderProgram, "view");
    const projectionLoc = gl.getUniformLocation(shaderProgram, "projection");

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        //if (window.getKey(.space) == .press) {
        const angle = @as(f32, @floatCast(glfw.getTime()));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotXY = zmath.mul(rotY, rotX);
        const translate = zmath.translation(2, 2, 2);
        const res = zmath.mul(rotXY, translate);
        const modelMat = zmath.matToArr(res);
        gl.uniformMatrix4fv(modelLoc, 1, gl.FALSE, &modelMat);
        gl.uniformMatrix4fv(viewLoc, 1, gl.FALSE, &viewMat);
        gl.uniformMatrix4fv(projectionLoc, 1, gl.FALSE, &projectionMat);

        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
