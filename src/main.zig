const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("zopengl");
const glw = @import("libs/glwrapper.zig");
const callbacks = @import("libs/callbacks.zig");

const print = std.debug.print;

fn init_window(width: i32, height: i32, title: [:0]const u8, monitor: ?*glfw.Monitor) !*glfw.Window {
    const gl_major = 4;
    const gl_minor = 0;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    // front buffer is the one being displayed
    // back buffer is the one you render to
    glfw.windowHintTyped(.doublebuffer, true);
    const window = try glfw.Window.create(width, height, title, monitor);
    glfw.makeContextCurrent(window);

    try gl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    glw.viewport(0, 0, width, height);
    glw.enable(glw.Capability.depth_test);

    // sync rendering loop with refresh rate
    // when the entire frame has been rendered, we have to swap the back and front swapBuffers
    // to render the new frame
    // swapInterval is the minimum number of monitor refreshes the driver should wait from the 21:25
    // swapBuffers was called before swapping
    glfw.swapInterval(1);

    window.setAttribute(.resizable, true);

    _ = window.setContentScaleCallback(callbacks.contentScaleCallback);
    _ = window.setFramebufferSizeCallback(callbacks.framebufferSizeCallback);
    _ = window.setSizeCallback(callbacks.sizeCallback);
    _ = window.setPosCallback(callbacks.posCallback);
    _ = window.setCursorPosCallback(callbacks.cursorPosCallback);
    _ = window.setMouseButtonCallback(callbacks.mouseButtonCallback);
    _ = window.setKeyCallback(callbacks.keyCallback);
    _ = window.setScrollCallback(callbacks.scrollCallback);
    _ = window.setKeyCallback(null);

    return window;
}

fn shader(comptime vertexShaderSource: [:0]const u8, comptime fragmentShaderSource: [:0]const u8) glw.Program {
    const vertexShader = glw.createShader(glw.ShaderType.vertex);
    defer glw.deleteShader(vertexShader);
    glw.shaderSource(vertexShader, vertexShaderSource);
    glw.compileShader(vertexShader);

    const fragmentShader = glw.createShader(glw.ShaderType.fragment);
    defer glw.deleteShader(fragmentShader);
    glw.shaderSource(fragmentShader, fragmentShaderSource);
    glw.compileShader(fragmentShader);

    const shaderProgram = glw.createProgram();
    // defer gl.deleteProgram(shaderProgram);
    glw.attachShader(shaderProgram, vertexShader);
    glw.attachShader(shaderProgram, fragmentShader);
    glw.linkProgram(shaderProgram);
    return shaderProgram;
}

fn loadVertexData(vertices: []const f32, indices: []const u32) void {
    _ = indices;
    _ = vertices;
}

pub fn main() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const window = try init_window(640, 480, "ThunderNut Engine", null);
    defer window.destroy();

    const cursor = try glfw.Cursor.createStandard(.hand);
    defer cursor.destroy();
    window.setCursor(cursor);

    // opengl stuff
    const vertexShaderSource =
        \\#version 330 core
        \\layout (location = 0) in vec3 aPos;
        \\void main() {
        \\  gl_Position = vec4(aPos, 1.0);
        \\}
    ;

    const fragmentShaderSource =
        \\#version 330 core
        \\out vec4 FragColor;
        \\void main() {
        \\  FragColor = vec4(1.0, 0.5, 0.2, 1.0); // Orange color
        \\}
    ;

    const shaderProgram = shader(vertexShaderSource, fragmentShaderSource);
    defer glw.deleteProgram(shaderProgram);

    const vertices = [_]f32{
        -0.5, -0.5, -0.5,
        0.5,  -0.5, -0.5,
        0.5,  0.5,  -0.5,
        -0.5, 0.5,  -0.5,
        -0.5, -0.5, 0.5,
        0.5,  -0.5, 0.5,
        0.5,  0.5,  0.5,
        -0.5, 0.5,  0.5,
    };

    const indices = [_]u32{
        0, 1, 2, 2, 3, 0,
        4, 5, 6, 6, 7, 4,
        0, 1, 5, 5, 4, 0,
        1, 2, 6, 6, 5, 1,
        2, 3, 7, 7, 6, 2,
        0, 3, 7, 7, 4, 0,
    };

    var VBO = glw.Buffer{};
    var VAO = glw.VertexArrayObject{};
    var EBO = glw.Buffer{};

    glw.genVertexArray(&VAO);
    glw.genBuffer(&VBO);
    glw.genBuffer(&EBO);

    glw.bindVertexArray(VAO);
    glw.bindBuffer(glw.BufferTarget.array_buffer, VBO);
    glw.bufferData(glw.BufferTarget.array_buffer, vertices.len * @sizeOf(f32), &vertices[0], glw.BufferUsage.static_draw);
    glw.bindBuffer(glw.BufferTarget.element_array_buffer, EBO);
    glw.bufferData(glw.BufferTarget.element_array_buffer, indices.len * @sizeOf(u32), &indices[0], glw.BufferUsage.static_draw);

    glw.vertexAttribPointer(.{ .location = 0 }, 3, glw.VertexAttribType.float, gl.FALSE, 3 * @sizeOf(f32), 0);
    glw.enableVertexAttribArray(.{ .location = 0 });

    //loadVertexData(vertices, indices);

    while (!window.shouldClose()) {
        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.6, 0.4, 1.0 });

        glw.useProgram(shaderProgram);
        glw.bindVertexArray(VAO);
        glw.drawElements(glw.PrimitiveType.triangles, indices.len, glw.VertexAttribType.unsigned_int, &indices[0]);

        if (window.getKey(.escape) == .press) {
            break;
        }

        window.swapBuffers();
        glfw.pollEvents();
        try glfw.maybeError();
    }
}
