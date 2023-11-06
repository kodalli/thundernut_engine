const std = @import("std");
const zmath = @import("zmath");
const gl = @import("gl");
const zmesh = @import("zmesh");

pub const Transform = struct {
    position: zmath.Vec,
    rotation: zmath.Quat,
    scale: zmath.Vec,
};

pub const Texture = struct {
    id: gl.GLuint,
    type: gl.GLenum,
};

pub const Material = struct {
    shader: gl.GLuint,
    texture: Texture,
};

pub const Renderable = struct {
    mesh: Mesh,
    material: Material,
};

pub const MeshInfo = struct {
    index_offset: u32,
    vertex_offset: i32,
    num_indices: u32,
    num_vertices: u32,

    const IndexType = zmesh.Shape.IndexType;
};

pub const Mesh = struct {
    vao: gl.GLuint,
    vbo: gl.GLuint,
    ebo: gl.GLuint,
    vertexCount: gl.GLsizei,
    indexCount: gl.GLsizei,

    pub fn init(allocator: std.mem.Allocator, vertices: []const f32, indices: []const gl.GLuint) !Mesh {
        std.debug.assert(vertices.len < std.math.maxInt(gl.GLsizei));
        std.debug.assert(indices.len < std.math.maxInt(gl.GLsizei));

        var mesh = Mesh{
            .vao = undefined,
            .vbo = undefined,
            .ebo = undefined,
            .vertexCount = @as(gl.GLsizei, @intCast(vertices.len)),
            .indexCount = @as(gl.GLsizei, @intCast(indices.len)),
        };

        var mutVertices = try allocator.alloc(f32, vertices.len);
        defer allocator.free(mutVertices);
        std.mem.copyForwards(f32, mutVertices, vertices);

        var mutIndices = try allocator.alloc(gl.GLuint, indices.len);
        defer allocator.free(mutIndices);
        std.mem.copyForwards(gl.GLuint, mutIndices, indices);

        const floatSize = @sizeOf(gl.GLfloat);
        const vertexBufferSize = @as(gl.GLsizeiptr, @intCast(floatSize * mesh.vertexCount));
        const indexBufferSize = @as(gl.GLsizeiptr, @intCast(@sizeOf(gl.GLuint) * mesh.indexCount));
        const vertexSize = 8 * floatSize;
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

pub fn appendMesh(
    mesh: zmesh.Shape,
    meshes: *std.ArrayList(MeshInfo),
    meshes_indices: *std.ArrayList(MeshInfo.IndexType),
    meshes_positions: *std.ArrayList([3]f32),
    meshes_normals: *std.ArrayList([3]f32),
    meshes_texcoords: *std.ArrayList([2]f32),
) void {
    meshes.append(.{
        .index_offset = @as(u32, @intCast(meshes_indices.items.len)),
        .vertex_offset = @as(i32, @intCast(meshes_positions.items.len)),
        .num_indices = @as(u32, @intCast(mesh.indices.len)),
        .num_vertices = @as(u32, @intCast(mesh.positions.len)),
    }) catch unreachable;

    meshes_indices.appendSlice(mesh.indices) catch unreachable;
    meshes_positions.appendSlice(mesh.positions) catch unreachable;
    meshes_normals.appendSlice(mesh.normals.?) catch unreachable;

    if (mesh.texcoords) |uv| {
        meshes_texcoords.appendSlice(uv) catch unreachable;
    } else {
        std.log.info("No texcoords to add to mesh", .{});
        meshes_texcoords.appendNTimes([_]f32{ 0, 0 }, meshes_positions.items.len) catch unreachable;
    }
}

pub fn generateMeshes(
    allocator: std.mem.Allocator,
    meshes: *std.ArrayList(MeshInfo),
    meshes_indices: *std.ArrayList(MeshInfo.IndexType),
    meshes_positions: *std.ArrayList([3]f32),
    meshes_normals: *std.ArrayList([3]f32),
    meshes_texcoords: *std.ArrayList([2]f32),
) void {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    zmesh.init(arena);
    defer zmesh.deinit();

    {
        var cube = zmesh.Shape.initCube();
        defer cube.deinit();
        cube.translate(-0.5, -0.5, -0.5);
        cube.unweld();
        cube.computeNormals();

        std.log.info("cube has texcoords: {}", .{cube.texcoords != null});

        appendMesh(cube, meshes, meshes_indices, meshes_positions, meshes_normals, meshes_texcoords);
    }
}

pub fn createMesh(allocator: std.mem.Allocator) !Mesh {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var meshes = std.ArrayList(MeshInfo).init(allocator);
    defer meshes.deinit();

    var meshes_indices = std.ArrayList(MeshInfo.IndexType).init(arena);
    defer meshes_indices.deinit();

    var meshes_positions = std.ArrayList([3]f32).init(arena);
    defer meshes_positions.deinit();

    var meshes_normals = std.ArrayList([3]f32).init(arena);
    defer meshes_normals.deinit();

    var meshes_texcoords = std.ArrayList([2]f32).init(arena);
    defer meshes_texcoords.deinit();

    generateMeshes(allocator, &meshes, &meshes_indices, &meshes_positions, &meshes_normals, &meshes_texcoords);

    std.log.info("meshes len: {}", .{meshes.items.len});
    std.log.info("meshes indices len: {}", .{meshes_indices.items.len});
    std.log.info("meshes positions len: {}", .{meshes_positions.items.len});
    std.log.info("meshes normals len: {}", .{meshes_normals.items.len});
    std.log.info("meshes texcoords len: {}", .{meshes_texcoords.items.len});

    //std.log.debug("\nmesh indices: {any}\n", .{meshes_indices.items});

    const total_num_vertices = @as(u32, @intCast(meshes_positions.items.len));
    const total_num_indices = @as(u32, @intCast(meshes_indices.items.len));

    var vertices = try allocator.alloc(f32, 8 * total_num_vertices);
    defer allocator.free(vertices);
    var index: usize = 0;
    for (meshes_positions.items, meshes_normals.items, meshes_texcoords.items) |pos, norm, uv| {
        const vertex_data = pos ++ norm ++ uv;
        std.mem.copyForwards(f32, vertices[index..][0..8], &vertex_data);
        index += 8;
    }

    var indices = try allocator.alloc(gl.GLuint, total_num_indices);
    defer allocator.free(indices);
    for (meshes_indices.items, 0..total_num_indices) |ind, i| {
        indices[i] = ind;
    }

    //std.log.debug("vertices: {any} \nindices: {any}", .{ vertices, indices });

    var mesh = try Mesh.init(allocator, vertices, indices);

    return mesh;
}

pub fn render(meshes: []const Mesh, modelArrays: std.ArrayList([16]f32), modelLoc: gl.GLint) void {
    for (meshes, modelArrays.items) |mesh, modelArr| {
        gl.uniformMatrix4fv(modelLoc, 1, gl.FALSE, &modelArr);
        gl.bindVertexArray(mesh.vao);
        gl.drawElements(gl.TRIANGLES, mesh.indexCount, gl.UNSIGNED_INT, null);
    }
}
