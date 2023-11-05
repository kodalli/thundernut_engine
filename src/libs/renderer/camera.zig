const zmath = @import("zmath");

pub const Camera = struct {
    cameraPos: zmath.Vec,
    targetPos: zmath.Vec,
    upDirection: zmath.Vec,
    fov: f32,
    nearPlane: f32,
    farPlane: f32,

    pub fn init(x: f32, y: f32, z: f32) Camera {
        return .{
            .cameraPos = zmath.f32x4(x, y, z, 1),
            .targetPos = zmath.f32x4(0, 0, 0, 1),
            .upDirection = zmath.f32x4(0, 1, 0, 1),
            .fov = 70,
            .nearPlane = 1.0,
            .farPlane = 1000,
        };
    }

    pub fn perspectiveMatrix(self: *Camera, size: [2]i32) [16]f32 {
        const width = @as(f32, @floatFromInt(size[0]));
        const height = @as(f32, @floatFromInt(size[1]));
        const aspect = width / height;
        const perspective = zmath.perspectiveFovRh(self.fov, aspect, self.nearPlane, self.farPlane);
        const perspectiveMat = zmath.matToArr(perspective);
        return perspectiveMat;
    }

    pub fn viewMatrix(self: *Camera) [16]f32 {
        const view = zmath.lookAtRh(self.cameraPos, self.targetPos, self.upDirection);
        const viewMat = zmath.matToArr(view);
        return viewMat;
    }
};