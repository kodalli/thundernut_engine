const std = @import("std");
const zmath = @import("zmath");

const Cube = struct {
    // vertices (x, y, z), normals (nx, ny, nz), texture coordinates (u, v)
    // 3 consecutive floats give a 3D vertex, 3 consecutive vertices give a triangle
    // A cube has 6 face w/ 2 triangle each -> 6 * 2 = 12 triangles, and 12 * 3 = 36 vertices
    // 8 values per vertex * 36 = 288, not shared
    vertices: [288]f32,

    // 4 vertices per face * 6 faces = 24 indices, not shared
    indices: [24]u32,
};

const Transform = struct {
    position: zmath.Vec,
    rotation: zmath.Quat,
    scale: zmath.Vec,
};

const Renderable = struct {
    mesh: Mesh,
    material: Material,
};
