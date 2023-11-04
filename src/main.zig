const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const utils = @import("libs/utils.zig");
const zmath = @import("zmath");
const zmesh = @import("zmesh");
const renderer = @import("libs/renderer/mesh_renderer.zig");

const print = std.debug.print;
pub const GLProc = *const fn () callconv(.C) void;

fn getProcAddress(load_ctx: GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = load_ctx;
    return glfw.getProcAddress(proc);
}

fn loadShaders() gl.GLuint {
    const vert: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.vertexShaderSource.ptr)};
    const frag: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.fragmentShaderSource.ptr)};

    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(vertexShader, 1, vert, null);
    gl.compileShader(vertexShader);

    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(fragmentShader, 1, frag, null);
    gl.compileShader(fragmentShader);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    return shaderProgram;
}

fn setupWindow() !*glfw.Window {
    const gl_major = 4;
    const gl_minor = 0;

    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    return try glfw.Window.create(640, 480, "ThunderNut Engine", null);
}

pub fn main() !void {
    try run();
}

fn run() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const window = try setupWindow();
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const load_ctx: GLProc = undefined;
    try gl.load(load_ctx, getProcAddress);

    gl.viewport(0, 0, 640, 480);
    gl.enable(gl.DEPTH_TEST);

    const shaderProgram = loadShaders();
    defer gl.deleteProgram(shaderProgram);

    gl.useProgram(shaderProgram);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var mesh = try renderer.createMesh(allocator);
    defer mesh.deinit();

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        //if (window.getKey(.space) == .press) {
        const angle = @as(f32, @floatCast(glfw.getTime()));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotMatrix = zmath.matToArr(zmath.mul(rotY, rotX));
        gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "transform"), 1, gl.FALSE, &rotMatrix);
        //}

        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
