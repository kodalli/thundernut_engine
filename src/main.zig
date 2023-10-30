const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("zopengl");
const callbacks = @import("libs/callbacks.zig");
const print = std.debug.print;

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
    // front buffer is the one being displayed
    // back buffer is the one you render to
    glfw.windowHintTyped(.doublebuffer, true);

    const window = try glfw.Window.create(640, 480, "ThunderNut Engine", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);

    try gl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

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

    const cursor = try glfw.Cursor.createStandard(.hand);
    defer cursor.destroy();
    window.setCursor(cursor);

    while (!window.shouldClose()) {
        glfw.pollEvents();

        if (window.getKey(.a) == .press) {
            print("Yeehaw\n", .{});
        }
        if (window.getMouseButton(.right) == .press) {
            print("Amazin\n", .{});
        }
        if (window.getKey(.escape) == .press) {
            break;
        }

        const cursor_pos = window.getCursorPos();
        const x = cursor_pos[0];
        _ = x;
        const y = cursor_pos[1];
        _ = y;

        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.6, 0.4, 1.0 });
        window.swapBuffers();

        try glfw.maybeError();
    }
}
