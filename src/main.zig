const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const utils = @import("libs/utils.zig");
const zmath = @import("zmath");
const zmesh = @import("zmesh");
const renderer = @import("libs/renderer/mesh_renderer.zig");
const shader = @import("libs/renderer/shaders.zig");
const cam = @import("libs/renderer/camera.zig");
const callbacks = @import("libs/callbacks.zig");

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

var camera = cam.Camera.init(0, 0, -10);
var viewMat: zmath.Mat = undefined;
var deltaTime: f64 = 0;
var lastTime: f64 = 0;
const cameraSpeed = 15;
const playerSpeed = 100;

pub inline fn updateCamera(inputActions: *callbacks.InputActions) void {
    const timeScale = @as(f32, @floatCast(deltaTime));
    const speedScale = timeScale * playerSpeed;
    const x = -(inputActions.movement[0] * speedScale) + camera.cameraPos[0];
    const y = (inputActions.movement[1] * speedScale) + camera.cameraPos[1];
    const z = camera.cameraPos[2];
    const w = camera.cameraPos[3];
    const prev = camera.cameraPos;
    const newPos: zmath.Vec = .{ x, y, z, w };
    camera.cameraPos = zmath.lerp(prev, newPos, timeScale * cameraSpeed);
    viewMat = camera.viewMatrix();
    //std.log.debug("delta time: {}", .{deltaTime});
    //std.log.debug("cameraPos: {any}", .{camera.cameraPos});
}

inline fn updateDeltaTime(time: f64) void {
    deltaTime = time - lastTime;
    lastTime = time;
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

    var mesh = try renderer.createMesh(allocator);
    defer mesh.deinit();

    callbacks.initCallbackHandler(window, allocator);
    defer callbacks.deinitCallbackHandler();
    //try callbacks.input.addCallback(updateCamera);

    const projectionMat = camera.perspectiveMatrix(window.getSize());
    viewMat = camera.viewMatrix();

    std.log.debug("projectionMat: {any}\nviewMat: {any}\n", .{ projectionMat, viewMat });

    const modelLoc = gl.getUniformLocation(shaderProgram, "modelViewProjection");

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const time = glfw.getTime();
        updateDeltaTime(time);
        updateCamera(&callbacks.input);

        const angle = @as(f32, @floatCast(time));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotXY = zmath.mul(rotY, rotX);
        const translate = zmath.translation(2, 2, 2);
        const transformMat = zmath.mul(rotXY, translate);
        const res = zmath.mul(transformMat, zmath.mul(viewMat, projectionMat));
        const modelMat = zmath.matToArr(res);
        gl.uniformMatrix4fv(modelLoc, 1, gl.FALSE, &modelMat);

        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
