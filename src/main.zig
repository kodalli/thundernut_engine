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

    window.setInputMode(.cursor, .disabled);

    return window;
}

pub fn main() !void {
    try run();
}

var camera = cam.Camera.init(0, 2, -7);
var viewMat: zmath.Mat = undefined;
var deltaTime: f64 = 0;
var lastTime: f64 = 0;
const cameraSpeed = 15;
const mouseSpeed = 0.001;
const playerSpeed: f32 = 5;
const mouseSensitivity = zmath.splat(zmath.Vec, 10.0);
var pitch: f32 = 0.0;
var yaw: f32 = 0.0;

pub inline fn updateCamera(inputActions: *callbacks.InputActions) void {
    const timeScale = @as(f32, @floatCast(deltaTime));
    const speedScale = timeScale * playerSpeed;

    // Camera orientation
    pitch += inputActions.mouseDelta[1] * mouseSpeed;
    yaw += inputActions.mouseDelta[0] * mouseSpeed;
    const rotation = zmath.quatFromRollPitchYawV(.{ pitch, yaw, 0, 0 });
    camera.cameraOrientation = rotation;

    // Camera movement
    const x = inputActions.movement[0];
    const z = inputActions.movement[1];
    const y = 0;
    const w = 0;
    const input: zmath.Vec = .{ x, y, z, w };

    const rotatedMovement = zmath.rotate(rotation, input);
    const movementVec = rotatedMovement * zmath.splat(zmath.Vec, speedScale);
    const prevPos = camera.cameraPos;

    std.log.debug("input: {any}", .{rotation});
    camera.cameraPos = prevPos + movementVec;

    viewMat = camera.viewMatrix();
}

inline fn updateDeltaTime(time: f64) void {
    deltaTime = time - lastTime;
    lastTime = time;
}

inline fn modelViewProjectionArr(translation: zmath.Mat, rotation: zmath.Mat, viewProjMat: zmath.Mat) [16]f32 {
    _ = rotation;
    // const transformMat = zmath.mul(rotation, translation);
    const transformMat = translation;
    const res = zmath.mul(transformMat, viewProjMat);
    const modelArray = zmath.matToArr(res);
    return modelArray;
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
    const meshes = [_]renderer.Mesh{ mesh, mesh };
    defer mesh.deinit();

    callbacks.initCallbackHandler(window, allocator);
    defer callbacks.deinitCallbackHandler();
    //try callbacks.input.addCallback(updateCamera);

    const projectionMat = camera.perspectiveMatrix(window.getSize());
    viewMat = camera.viewMatrix();

    std.log.debug("projectionMat: {any}\nviewMat: {any}\n", .{ projectionMat, viewMat });

    const modelLoc = gl.getUniformLocation(shaderProgram, "modelViewProjection");

    const translationMat1 = zmath.translation(2, 2, 2);
    const translationMat2 = zmath.translation(0, 0, 0);

    var modelArrays = std.ArrayList([16]f32).init(allocator);
    defer modelArrays.deinit();

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const time = glfw.getTime();
        updateDeltaTime(time);
        callbacks.input.updateInput(window);
        updateCamera(&callbacks.input);

        const angle = @as(f32, @floatCast(time));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotationMat = zmath.mul(rotY, rotX);

        const viewProjMat = zmath.mul(viewMat, projectionMat);
        const modelArray1 = modelViewProjectionArr(translationMat1, rotationMat, viewProjMat);
        const modelArray2 = modelViewProjectionArr(translationMat2, rotationMat, viewProjMat);
        try modelArrays.append(modelArray1);
        try modelArrays.append(modelArray2);

        //gl.uniformMatrix4fv(modelLoc, 1, gl.FALSE, &modelArray);

        renderer.render(&meshes, modelArrays, modelLoc);
        modelArrays.clearAndFree();
        //gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
