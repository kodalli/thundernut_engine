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
const zstbi = @import("zstbi");

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

var camera = cam.Camera.init(0, 1.5, -7);
var deltaTime: f64 = 0;
var lastTime: f64 = 0;
const mouseSpeed = 0.001;
const playerSpeed: f32 = 5;
var pitch: f32 = 0.0;
var yaw: f32 = 0.0;

pub fn updateCamera(inputActions: *callbacks.InputActions) zmath.Mat {
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
    // Use for free movement
    //const movementVec = rotatedMovement * zmath.splat(zmath.Vec, speedScale);
    const movementVec = rotatedMovement * zmath.f32x4(speedScale, 0, speedScale, 0);
    const prevPos = camera.cameraPos;

    camera.cameraPos = prevPos + movementVec;

    return camera.viewMatrix();
}

inline fn updateDeltaTime(time: f64) void {
    deltaTime = time - lastTime;
    lastTime = time;
}

inline fn modelViewProjectionMat(translation: zmath.Mat, rotation: zmath.Mat, viewProjMat: zmath.Mat) zmath.Mat {
    const transformMat = zmath.mul(rotation, translation);
    //const transformMat = translation;
    const res = zmath.mul(transformMat, viewProjMat);
    return res;
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

    callbacks.initCallbackHandler(window, allocator);
    defer callbacks.deinitCallbackHandler();
    //try callbacks.input.addCallback(updateCamera);

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
        updateDeltaTime(time);
        callbacks.input.updateInput(window);
        viewMat = updateCamera(&callbacks.input);

        const angle = @as(f32, @floatCast(time));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotationMat = zmath.mul(rotY, rotX);

        const viewProjMat = zmath.mul(viewMat, projectionMat);
        const modelMat1 = modelViewProjectionMat(translationMat1, rotationMat, viewProjMat);
        const modelMat2 = modelViewProjectionMat(translationMat2, rotationMat, viewProjMat);
        try modelArrays.append(zmath.arrNPtr(&modelMat1));
        try modelArrays.append(zmath.arrNPtr(&modelMat2));

        //gl.uniformMatrix4fv(modelLoc, 1, gl.FALSE, &modelArray);

        renderer.render(&meshes, modelArrays, modelLoc);
        modelArrays.clearAndFree();
        //gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
