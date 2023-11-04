const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("gl");
const utils = @import("libs/utils.zig");
const zmath = @import("zmath");
const zmesh = @import("zmesh");
const prim = @import("libs/primitives/primitives.zig");

const print = std.debug.print;
pub const GLProc = *const fn () callconv(.C) void;

fn getProcAddress(load_ctx: GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = load_ctx;
    return glfw.getProcAddress(proc);
}

fn loadShaders() gl.GLuint {
    const vert: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.vertexShaderSource.ptr)};
    const frag: [*c]const [*c]const u8 = &[_][*c]const u8{@ptrCast(utils.fragmentShaderSource.ptr)};

    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(vertexShader, 1, vert, null);
    gl.compileShader(vertexShader);

    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(fragmentShader, 1, frag, null);
    gl.compileShader(fragmentShader);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    return shaderProgram;
}

fn setupWindow() !*glfw.Window {
    const gl_major = 4;
    const gl_minor = 0;

    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    return try glfw.Window.create(640, 480, "ThunderNut Engine", null);
}

const Vertex = struct {
    position: [3]f32,
    normal: [3]f32,
};

const Mesh = struct {
    index_offset: u32,
    vertex_offset: i32,
    num_indices: u32,
    num_vertices: u32,

    const IndexType = zmesh.Shape.IndexType;
};

fn appendMesh(
    mesh: zmesh.Shape,
    meshes: *std.ArrayList(Mesh),
    meshes_indices: *std.ArrayList(Mesh.IndexType),
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

fn generateMeshes(
    allocator: std.mem.Allocator,
    meshes: *std.ArrayList(Mesh),
    meshes_indices: *std.ArrayList(Mesh.IndexType),
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

fn create(allocator: std.mem.Allocator) !prim.Mesh {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var meshes = std.ArrayList(Mesh).init(allocator);
    defer meshes.deinit();

    var meshes_indices = std.ArrayList(Mesh.IndexType).init(arena);
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

    std.log.debug("\nmesh indices: {any}\n", .{meshes_indices.items});

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

    std.log.debug("vertices: {any} \nindices: {any}", .{ vertices, indices });

    var mesh = try prim.Mesh.init(allocator, vertices, indices);

    return mesh;
}

pub fn main() !void {
    try run();
}

fn run() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const window = try setupWindow();
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const load_ctx: GLProc = undefined;
    try gl.load(load_ctx, getProcAddress);

    gl.viewport(0, 0, 640, 480);
    gl.enable(gl.DEPTH_TEST);

    const shaderProgram = loadShaders();
    defer gl.deleteProgram(shaderProgram);

    gl.useProgram(shaderProgram);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var mesh = try create(allocator);
    defer mesh.deinit();

    while (!window.shouldClose()) {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        //if (window.getKey(.space) == .press) {
        const angle = @as(f32, @floatCast(glfw.getTime()));
        const rotX = zmath.rotationX(angle);
        const rotY = zmath.rotationY(angle);
        const rotMatrix = zmath.matToArr(zmath.mul(rotY, rotX));
        gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "transform"), 1, gl.FALSE, &rotMatrix);
        //}

        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
