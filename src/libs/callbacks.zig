const std = @import("std");
const glfw = @import("zglfw");
const log = std.log.scoped(.input);
const gl = @import("gl");
const zmath = @import("zmath");

pub fn initCallbackHandler(window: *glfw.Window, allocator: std.mem.Allocator) void {
    _ = window.setContentScaleCallback(contentScaleCallback);
    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);
    _ = window.setSizeCallback(sizeCallback);
    _ = window.setPosCallback(posCallback);
    _ = window.setCursorPosCallback(cursorPosCallback);
    _ = window.setMouseButtonCallback(mouseButtonCallback);
    _ = window.setKeyCallback(keyCallback);
    _ = window.setScrollCallback(scrollCallback);

    input = InputActions{
        .callbacks = std.ArrayList(InputActionCallback).init(allocator),
    };
}

pub fn deinitCallbackHandler() void {
    input.callbacks.deinit();
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

pub const InputActionCallback = *const fn (input: *InputActions) void;

inline fn enumToFloat(window: *glfw.Window, key: glfw.Key) f32 {
    return @as(f32, @floatFromInt(@intFromEnum(window.getKey(key))));
}

inline fn i32ToF64(x: i32) f64 {
    return @as(f64, @floatFromInt(x));
}

pub const InputActions = struct {
    movement: @Vector(2, f32) = @splat(0),
    mouseDirection: zmath.Vec = @splat(0),
    callbacks: std.ArrayList(InputActionCallback),
    isMouseCenter: bool = true,

    pub fn updateMovement(self: *InputActions, window: *glfw.Window) void {
        const w = enumToFloat(window, glfw.Key.w);
        const a = enumToFloat(window, glfw.Key.a);
        const s = enumToFloat(window, glfw.Key.s);
        const d = enumToFloat(window, glfw.Key.d);
        const inputVector: zmath.Vec = .{w, a, s, d};
        const axisX: zmath.Vec = .{0, -1, 0, 1};
        const axisY: zmath.Vec = .{1, 0, -1, 0};
        const dotX = zmath.dot4(inputVector, axisX);
        const dotY = zmath.dot4(inputVector, axisY);
        const mask = @Vector(2, f32){ 0, -1 };
        const axis = @shuffle(f32, dotX, dotY, mask);
        const min = @Vector(2, f32){ -1, -1 };
        const max = @Vector(2, f32){ 1, 1 };
        self.movement = zmath.clampFast(axis, min, max);

        //std.log.debug("input: {any}", .{input.movement});

        const windowSize = window.getSize();
        const centerX = i32ToF64(windowSize[0]) / 2.0;
        const centerY = i32ToF64(windowSize[1]) / 2.0;
        const cursorPos = window.getCursorPos();
        // mouse x, y from center of window
        // yaw: x, pitch: y, roll: z
        const dirX = cursorPos[0] - centerX;
        const dirY = centerY - cursorPos[1];
        const mouseDir: zmath.Vec = .{@as(f32, @floatCast(dirX)), @as(f32, @floatCast(dirY)), 0, 0};
        const strength: f32 = zmath.length2(mouseDir)[0];
        const windowScale = 0.05 * std.math.sqrt(@as(f32, @floatFromInt(windowSize[0] * windowSize[0] + windowSize[1] * windowSize[1])));
        if (strength > windowScale) {
            self.mouseDirection = zmath.normalize2(mouseDir);
            self.isMouseCenter = false;
        } else {
            //self.mouseDirection = @splat(0);
            self.isMouseCenter = true;
        }

        // std.log.debug("dirX: {}, dirY: {}", .{ self.mouseDirection[0], self.mouseDirection[1] });
        std.log.debug("mouse strength {}", .{strength});

        //for (self.callbacks.items) |callback| {
        //    callback(self);
        //    std.log.debug("callback!", .{});
        //}
    }

    pub fn addCallback(self: *InputActions, callback: InputActionCallback) !void {
        try self.callbacks.append(callback);
    }
};

pub var input: InputActions = undefined;

pub fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = scancode;
    _ = mods;
    //input.updateMovement(key, action);
    log.debug("{} {}\n", .{ key, action });
}
