const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const utils = @import("libs/utils.zig");

const print = std.debug.print;
pub const GLProc = *const fn () callconv(.C) void;

fn getProcAddress(load_ctx: GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = load_ctx;
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const gl_major = 4;
    const gl_minor = 0;

    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const window = try glfw.Window.create(640, 480, "test", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const load_ctx: GLProc = undefined;
    try gl.load(load_ctx, getProcAddress);

    gl.viewport(0, 0, 640, 480);
    gl.enable(gl.DEPTH_TEST);

    const vert: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.vertexShaderSource.ptr)};
    const frag: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.fragmentShaderSource.ptr)};

    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, 1, vert, null);
    gl.compileShader(vertexShader);

    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, frag, null);
    gl.compileShader(fragmentShader);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    var vertices = [_]gl.GLfloat{
        -0.5, -0.5, -0.5,
        0.5,  -0.5, -0.5,
        0.5,  0.5,  -0.5,
        -0.5, 0.5,  -0.5,
        -0.5, -0.5, 0.5,
        0.5,  -0.5, 0.5,
        0.5,  0.5,  0.5,
        -0.5, 0.5,  0.5,
    };

    var indices = [_]gl.GLuint{
        0, 1, 2, 2, 3, 0,
        4, 5, 6, 6, 7, 4,
        0, 1, 5, 5, 4, 0,
        1, 2, 6, 6, 5, 1,
        2, 3, 7, 7, 6, 2,
        0, 3, 7, 7, 4, 0,
    };

    var VBO: gl.GLuint = undefined;
    var VAO: gl.GLuint = undefined;
    var EBO: gl.GLuint = undefined;

    gl.genVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);
    gl.genBuffers(1, &EBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(gl.GLfloat) * vertices.len, &vertices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(gl.GLuint) * indices.len, &indices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(gl.GLfloat), null);
    gl.enableVertexAttribArray(0);

    var rotationMatrix: [4][4]f32 = undefined;

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        utils.generateRotationMatrix(@as(f32, @floatCast(glfw.getTime())), &rotationMatrix);

        gl.useProgram(shaderProgram);
        gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "transform"), 1, gl.FALSE, &rotationMatrix[0][0]);
        gl.bindVertexArray(VAO);
        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

// fn init_window(width: i32, height: i32, title: [:0]const u8, monitor: ?*glfw.Monitor) !*glfw.Window {
//     const gl_major = 4;
//     const gl_minor = 0;
//     glfw.windowHintTyped(.context_version_major, gl_major);
//     glfw.windowHintTyped(.context_version_minor, gl_minor);
//     glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
//     glfw.windowHintTyped(.opengl_forward_compat, true);
//     glfw.windowHintTyped(.client_api, .opengl_api);
//     // front buffer is the one being displayed
//     // back buffer is the one you render to
//     glfw.windowHintTyped(.doublebuffer, true);
//     const window = try glfw.Window.create(width, height, title, monitor);
//     glfw.makeContextCurrent(window);

//     try gl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
//     gl.viewport(0, 0, width, height);
//     gl.enable(glw.Capability.depth_test);

//     // sync rendering loop with refresh rate
//     // when the entire frame has been rendered, we have to swap the back and front swapBuffers
//     // to render the new frame
//     // swapInterval is the minimum number of monitor refreshes the driver should wait from the 21:25
//     // swapBuffers was called before swapping
//     glfw.swapInterval(1);

//     window.setAttribute(.resizable, true);

//     return window;
// }

// fn shader(comptime vertexShaderSource: [:0]const u8, comptime fragmentShaderSource: [:0]const u8) glw.Program {
//     const vertexShader = glw.createShader(glw.ShaderType.vertex);
//     defer glw.deleteShader(vertexShader);
//     glw.shaderSource(vertexShader, vertexShaderSource);
//     glw.compileShader(vertexShader);

//     const fragmentShader = glw.createShader(glw.ShaderType.fragment);
//     defer glw.deleteShader(fragmentShader);
//     glw.shaderSource(fragmentShader, fragmentShaderSource);
//     glw.compileShader(fragmentShader);

//     const shaderProgram = glw.createProgram();
//     // defer gl.deleteProgram(shaderProgram);
//     glw.attachShader(shaderProgram, vertexShader);
//     glw.attachShader(shaderProgram, fragmentShader);
//     glw.linkProgram(shaderProgram);
//     return shaderProgram;
// }

// fn loadVertexData(vertices: []const f32, indices: []const u32) void {
//     _ = indices;
//     _ = vertices;
// }

// pub fn main() !void {
//     glfw.init() catch {
//         std.log.err("Failed to initialize GLFW library.", .{});
//         return;
//     };
//     defer glfw.terminate();

//     const window = try init_window(640, 480, "ThunderNut Engine", null);
//     defer window.destroy();

//     const cursor = try glfw.Cursor.createStandard(.hand);
//     defer cursor.destroy();
//     window.setCursor(cursor);

//     // opengl stuff
//     const vertexShaderSource =
//         \\#version 330 core
//         \\layout (location = 0) in vec3 aPos;
//         \\void main() {
//         \\  gl_Position = vec4(aPos, 1.0);
//         \\}
//     ;

//     const fragmentShaderSource =
//         \\#version 330 core
//         \\out vec4 FragColor;
//         \\void main() {
//         \\  FragColor = vec4(1.0, 0.5, 0.2, 1.0); // Orange color
//         \\}
//     ;

//     const shaderProgram = shader(vertexShaderSource, fragmentShaderSource);
//     defer glw.deleteProgram(shaderProgram);

//     const vertices = [_]f32{
//         -0.5, -0.5, -0.5,
//         0.5,  -0.5, -0.5,
//         0.5,  0.5,  -0.5,
//         -0.5, 0.5,  -0.5,
//         -0.5, -0.5, 0.5,
//         0.5,  -0.5, 0.5,
//         0.5,  0.5,  0.5,
//         -0.5, 0.5,  0.5,
//     };

//     const indices = [_]u32{
//         0, 1, 2, 2, 3, 0,
//         4, 5, 6, 6, 7, 4,
//         0, 1, 5, 5, 4, 0,
//         1, 2, 6, 6, 5, 1,
//         2, 3, 7, 7, 6, 2,
//         0, 3, 7, 7, 4, 0,
//     };

//     var VBO = glw.Buffer{};
//     var VAO = glw.VertexArrayObject{};
//     var EBO = glw.Buffer{};

//     glw.genVertexArray(&VAO);
//     glw.genBuffer(&VBO);
//     glw.genBuffer(&EBO);

//     glw.bindVertexArray(VAO);
//     glw.bindBuffer(glw.BufferTarget.array_buffer, VBO);
//     glw.bufferData(glw.BufferTarget.array_buffer, vertices.len * @sizeOf(f32), &vertices[0], glw.BufferUsage.static_draw);
//     glw.bindBuffer(glw.BufferTarget.element_array_buffer, EBO);
//     glw.bufferData(glw.BufferTarget.element_array_buffer, indices.len * @sizeOf(u32), &indices[0], glw.BufferUsage.static_draw);

//     glw.vertexAttribPointer(.{ .location = 0 }, 3, glw.VertexAttribType.float, gl.FALSE, 3 * @sizeOf(f32), 0);
//     glw.enableVertexAttribArray(.{ .location = 0 });

//     //loadVertexData(vertices, indices);

//     while (!window.shouldClose()) {
//         gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.6, 0.4, 1.0 });

//         glw.useProgram(shaderProgram);
//         glw.bindVertexArray(VAO);
//         glw.drawElements(glw.PrimitiveType.triangles, indices.len, glw.VertexAttribType.unsigned_int, &indices[0]);

//         if (window.getKey(.escape) == .press) {
//             break;
//         }

//         window.swapBuffers();
//         glfw.pollEvents();
//         try glfw.maybeError();
//     }
// }
