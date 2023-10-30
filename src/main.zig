const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("zopengl");
const print = std.debug.print;

pub fn main() !void {
    try glfw.init();
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

    // sync rendering loop iwth refresh rate
    // when the entire frame has been rendered, we have to swap the back and front swapBuffers
    // to render the new frame
    // swapInterval is the minimum number of monitor refreshes the driver should wait from the 21:25
    // swapBuffers was called before swapping
    glfw.swapInterval(1);

    window.setAttribute(.resizable, true);

    _ = window.setContentScaleCallback(contentScaleCallback);
    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);
    _ = window.setSizeCallback(sizeCallback);
    _ = window.setPosCallback(posCallback);
    _ = window.setCursorPosCallback(cursorPosCallback);
    _ = window.setMouseButtonCallback(mouseButtonCallback);
    _ = window.setKeyCallback(keyCallback);
    _ = window.setScrollCallback(scrollCallback);
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

fn contentScaleCallback(window: *glfw.Window, xscale: f32, yscale: f32) callconv(.C) void {
    _ = window;
    _ = xscale;
    _ = yscale;
}

fn framebufferSizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    _ = height;
    _ = width;
    _ = window;
}

fn sizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    _ = window;
    _ = width;
    _ = height;
}

fn posCallback(window: *glfw.Window, xpos: i32, ypos: i32) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
}

fn cursorPosCallback(window: *glfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
}

fn mouseButtonCallback(window: *glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = button;
    _ = mods;
    print("mouse action {}\n", .{action});
}

fn scrollCallback(window: *glfw.Window, xoffset: f64, yoffset: f64) callconv(.C) void {
    _ = window;
    _ = xoffset;
    _ = yoffset;
}

fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = scancode;
    _ = mods;

    print("{} {}\n", .{ key, action });
}
