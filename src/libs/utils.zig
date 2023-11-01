const std = @import("std");
const sin = std.math.sin;
const cos = std.math.cos;

pub fn generateRotationMatrix(angle: f32, matrix: *[4][4]f32) void {
    const cosAx = cos(angle);
    const sinAx = sin(angle);
    const cosAy = cos(angle * 0.5);
    const sinAy = sin(angle * 0.5);

    const rotationX = [_][4]f32{
        [_]f32{1.0, 0.0, 0.0, 0.0},
        [_]f32{0.0, cosAx, -sinAx, 0.0},
        [_]f32{0.0, sinAx, cosAx, 0.0},
        [_]f32{0.0, 0.0, 0.0, 1.0},
    };

    const rotationY = [_][4]f32{
        [_]f32{cosAy, 0.0, sinAy, 0.0},
        [_]f32{0.0, 1.0, 0.0, 0.0},
        [_]f32{-sinAy, 0.0, cosAy, 0.0},
        [_]f32{0.0, 0.0, 0.0, 1.0},
    };

    for (0..4) |i| {
        for (0..4) |j| {
            matrix[i][j] = 0.0;
            for (0..4) |k| {
                matrix[i][j] += rotationX[i][k] * rotationY[k][j];
            }
        }
    }
}

pub const vertexShaderSource =
\\#version 330 core
\\layout (location = 0) in vec3 aPos;
\\uniform mat4 transform;
\\out vec3 vertexColor;
\\void main() {
\\    gl_Position = transform * vec4(aPos, 1.0);
\\    vertexColor = aPos;
\\}
;

pub const fragmentShaderSource =
\\#version 330 core
\\in vec3 vertexColor;
\\out vec4 FragColor;
\\void main() {
\\    FragColor = vec4(abs(vertexColor), 1.0);
\\}
;