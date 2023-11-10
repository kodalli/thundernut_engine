const zmath = @import("zmath");
const callbacks = @import("../callbacks.zig");
const World = @import("../../main.zig").World;

pub const Camera = struct {
    cameraPos: zmath.Vec,
    //targetPos: zmath.Vec,
    upDirection: zmath.Vec,
    cameraOrientation: zmath.Quat,
    fov: f32,
    nearPlane: f32,
    farPlane: f32,
    pitch: f32 = 0.0,
    yaw: f32 = 0.0,
    mouseSpeed: f32 = 0.001,
    playerSpeed: f32 = 5,
    freeCamera: bool = false,

    pub fn init(x: f32, y: f32, z: f32) Camera {
        return .{
            .cameraPos = zmath.f32x4(x, y, z, 1),
            //.targetPos = zmath.f32x4(0, 0, 0, 1),
            .upDirection = zmath.f32x4(0, 1, 0, 1),
            .cameraOrientation = zmath.qidentity(),
            .fov = 70,
            .nearPlane = 0.3,
            .farPlane = 1000,
        };
    }

    pub fn perspectiveMatrix(self: *Camera, size: [2]i32) zmath.Mat {
        const width = @as(f32, @floatFromInt(size[0]));
        const height = @as(f32, @floatFromInt(size[1]));
        const aspect = width / height;
        const perspectiveMat = zmath.perspectiveFovLh(self.fov, aspect, self.nearPlane, self.farPlane);
        return perspectiveMat;
    }

    pub fn forwardDir(self: *Camera) zmath.Vec {
        const viewRotationMatrix = zmath.matFromQuat(self.cameraOrientation);
        var forward = viewRotationMatrix[2];
        forward[3] = 1;
        return forward;
    }

    pub fn viewMatrix(self: *Camera) zmath.Mat {
        return zmath.lookToLh(self.cameraPos, self.forwardDir(), self.upDirection);
    }

    pub fn updateCamera(self: *Camera, inputActions: *callbacks.InputActions, world: *World) zmath.Mat {
        const timeScale = @as(f32, @floatCast(world.deltaTime));
        const speedScale = timeScale * self.playerSpeed;

        // Camera orientation
        self.pitch += inputActions.mouseDelta[1] * self.mouseSpeed;
        self.yaw += inputActions.mouseDelta[0] * self.mouseSpeed;
        const rotation = zmath.quatFromRollPitchYawV(.{ self.pitch, self.yaw, 0, 0 });
        self.cameraOrientation = rotation;

        // Camera movement
        const x = inputActions.movement[0];
        const z = inputActions.movement[1];
        const y = 0;
        const w = 0;
        const input: zmath.Vec = .{ x, y, z, w };

        const rotatedMovement = zmath.rotate(rotation, input);
        const movementVec = blk: {
            if (self.freeCamera) {
                break :blk rotatedMovement * zmath.splat(zmath.Vec, speedScale);
            } else {
                break :blk rotatedMovement * zmath.f32x4(speedScale, 0, speedScale, 0);
            }
        };
        const prevPos = self.cameraPos;

        self.cameraPos = prevPos + movementVec;

        return self.viewMatrix();
    }
};
