const std = @import("std");
const zmath = @import("zmath");
const gl = @import("gl");

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

const Vertex = struct {
    // vertices (x, y, z), normals (nx, ny, nz), texture coordinates (u, v)
    vertices: []f32,
    // every 3 is a triangle
    indices: []gl.GLuint,
};

pub const Mesh = struct {
    vao: gl.GLuint,
    vbo: gl.GLuint,
    ebo: gl.GLuint,
    vertexCount: usize,
    indexCount: usize,

    pub fn init(allocator: std.mem.Allocator, vertices: []const f32, indices: []const gl.GLuint) !Mesh {
        var mesh = Mesh{
            .vao = undefined,
            .vbo = undefined,
            .ebo = undefined,
            .vertexCount = vertices.len,
            .indexCount = indices.len,
        };

        var mutVertices = try allocator.alloc(f32, vertices.len);
        defer allocator.free(mutVertices);
        std.mem.copyForwards(f32, mutVertices, vertices);

        var mutIndices = try allocator.alloc(gl.GLuint, indices.len);
        defer allocator.free(mutIndices);
        std.mem.copyForwards(gl.GLuint, mutIndices, indices);

        const floatSize = @sizeOf(gl.GLfloat);
        const vertexBufferSize = @as(gl.GLsizeiptr, @intCast(floatSize * vertices.len));
        const indexBufferSize = @as(gl.GLsizeiptr, @intCast(@sizeOf(gl.GLuint) * indices.len));
        const vertexSize = 8 * floatSize;
        const positionOffset = 0 * floatSize;
        _ = positionOffset;
        const normalOffset = 3 * floatSize;
        const uvOffset = 6 * floatSize;

        gl.genVertexArrays(1, &mesh.vao);
        gl.genBuffers(1, &mesh.vbo);
        gl.genBuffers(1, &mesh.ebo);

        gl.bindVertexArray(mesh.vao);
        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, vertexBufferSize, mutVertices.ptr, gl.STATIC_DRAW);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexBufferSize, mutIndices.ptr, gl.STATIC_DRAW);

        // Position
        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, vertexSize, null);
        gl.enableVertexAttribArray(0);

        // Normal
        gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, vertexSize, @as(*const anyopaque, @ptrFromInt(normalOffset)));
        gl.enableVertexAttribArray(1);

        // UV
        gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, vertexSize, @as(*const anyopaque, @ptrFromInt(uvOffset)));
        gl.enableVertexAttribArray(2);

        return mesh;
    }

    pub fn deinit(self: *Mesh) void {
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ebo);
        gl.deleteVertexArrays(1, &self.vao);
    }
};

const Texture = struct {
    id: gl.GLuint,
    type: gl.GLenum,
};

const Material = struct {
    shader: gl.GLuint,
    texture: Texture,
};

const Renderable = struct {
    mesh: Mesh,
    material: Material,
};
