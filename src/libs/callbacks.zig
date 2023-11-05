const std = @import("std");
const glfw = @import("zglfw");
const log = std.log.scoped(.input);
const gl = @import("gl");

pub fn initCallbackHandler(window: *glfw.Window) void {
    _ = window.setContentScaleCallback(contentScaleCallback);
    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);
    _ = window.setSizeCallback(sizeCallback);
    _ = window.setPosCallback(posCallback);
    _ = window.setCursorPosCallback(cursorPosCallback);
    _ = window.setMouseButtonCallback(mouseButtonCallback);
    _ = window.setKeyCallback(keyCallback);
    _ = window.setScrollCallback(scrollCallback);
}

pub fn contentScaleCallback(window: *glfw.Window, xscale: f32, yscale: f32) callconv(.C) void {
    _ = window;
    _ = xscale;
    _ = yscale;
}

pub fn framebufferSizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    _ = window;

    gl.viewport(0, 0, width, height);
}

pub fn sizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    _ = window;
    _ = width;
    _ = height;
}

pub fn posCallback(window: *glfw.Window, xpos: i32, ypos: i32) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
}

pub fn cursorPosCallback(window: *glfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
}

pub fn mouseButtonCallback(window: *glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = button;
    _ = mods;
    log.debug("mouse action {}\n", .{action});
}

pub fn scrollCallback(window: *glfw.Window, xoffset: f64, yoffset: f64) callconv(.C) void {
    _ = window;
    log.debug("scroll action xoffset:{} yoffset:{}\n", .{ xoffset, yoffset });
}

pub const InputActions = struct {
    movement: [2]f32 = .{ 0, 0 },
};

pub var input = InputActions{};

fn handleInput(key: glfw.Key, action: glfw.Action) void {
    const isPressedOrRepeated = action == .press or action == .repeat;

    switch (key) {
        .w => input.movement[1] = if (isPressedOrRepeated) 1 else 0,
        .s => input.movement[1] = if (isPressedOrRepeated) -1 else 0,
        .a => input.movement[0] = if (isPressedOrRepeated) -1 else 0,
        .d => input.movement[0] = if (isPressedOrRepeated) 1 else 0,
        else => {}, // No action for other keys
    }

    std.log.debug("input: {any}", .{input.movement});
}

pub fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = scancode;
    _ = mods;
    handleInput(key, action);
    log.debug("{} {}\n", .{ key, action });
}
