const zmath = @import("zmath");
const gl = @import("gl");

pub fn getPerspectiveMatrix(fov: f32, aspectRatio: f32, nearPlane: f32, farPlane: f32) zmath.Mat {
    _ = farPlane;
    _ = nearPlane;
    _ = aspectRatio;
    _ = fov;

}

