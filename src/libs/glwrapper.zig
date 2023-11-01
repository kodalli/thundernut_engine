const std = @import("std");
const gl = @import("zopengl");
const assert = std.debug.assert;

pub const Uint = gl.Uint;
pub const Sizei = gl.Sizei;
pub const Enum = gl.Enum;
pub const Char = gl.Char;
pub const Sizeiptr = gl.Sizeiptr;
pub const Boolean = gl.Boolean;
pub const Int = gl.Int;
pub const Float = gl.Float;

pub const Framebuffer = extern struct { name: Uint = 0 };
pub const Renderbuffer = extern struct { name: Uint = 0 };
pub const Shader = extern struct { name: Uint = 0 };
pub const Program = extern struct { name: Uint = 0 };
pub const Texture = extern struct { name: Uint = 0 };
pub const Buffer = extern struct { name: Uint = 0 };
pub const VertexArrayObject = extern struct { name: Uint = 0 };
pub const UniformLocation = extern struct { location: Uint };
pub const VertexAttribLocation = extern struct { location: Uint };

pub const ShaderType = enum(Enum) {
    //----------------------------------------------------------------------------------------------
    // OpenGL 2.0 (Core Profile)
    //----------------------------------------------------------------------------------------------
    vertex = gl.VERTEX_SHADER,
    fragment = gl.FRAGMENT_SHADER,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.2 (Core Profile)
    //----------------------------------------------------------------------------------------------
    geometry = gl.GEOMETRY_SHADER,
};

pub const BufferTarget = enum(Enum) {
    //----------------------------------------------------------------------------------------------
    // OpenGL 1.5 (Core Profile)
    //----------------------------------------------------------------------------------------------
    array_buffer = gl.ARRAY_BUFFER,
    element_array_buffer = gl.ELEMENT_ARRAY_BUFFER,
    //----------------------------------------------------------------------------------------------
    // OpenGL 2.1 (Core Profile)
    //----------------------------------------------------------------------------------------------
    pixel_pack_buffer = gl.PIXEL_PACK_BUFFER,
    pixel_unpack_buffer = gl.PIXEL_UNPACK_BUFFER,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.0 (Core Profile)
    //----------------------------------------------------------------------------------------------
    transform_feedback_buffer = gl.TRANSFORM_FEEDBACK_BUFFER,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.1 (Core Profile)
    //----------------------------------------------------------------------------------------------
    copy_read_buffer = gl.COPY_READ_BUFFER,
    copy_write_buffer = gl.COPY_WRITE_BUFFER,
    texture_buffer = gl.TEXTURE_BUFFER,
    uniform_buffer = gl.UNIFORM_BUFFER,
};

pub const BufferUsage = enum(Enum) {
    //----------------------------------------------------------------------------------------------
    // OpenGL 1.5 (Core Profile)
    //----------------------------------------------------------------------------------------------
    stream_draw = gl.STREAM_DRAW,
    stream_read = gl.STREAM_READ,
    stream_copy = gl.STREAM_COPY,
    static_draw = gl.STATIC_DRAW,
    static_read = gl.STATIC_READ,
    static_copy = gl.STATIC_COPY,
    dynamic_draw = gl.DYNAMIC_DRAW,
    dynamic_read = gl.DYNAMIC_READ,
    dynamic_copy = gl.DYNAMIC_COPY,
};

pub const VertexAttribType = enum(Enum) {
    //----------------------------------------------------------------------------------------------
    // OpenGL 1.0 (Core Profile)
    //----------------------------------------------------------------------------------------------
    byte = gl.BYTE,
    short = gl.SHORT,
    int = gl.INT,
    float = gl.FLOAT,
    double = gl.DOUBLE,
    unsigned_byte = gl.UNSIGNED_BYTE,
    unsigned_short = gl.UNSIGNED_SHORT,
    unsigned_int = gl.UNSIGNED_INT,
    //----------------------------------------------------------------------------------------------
    // OpenGL 1.2 (Core Profile)
    //----------------------------------------------------------------------------------------------
    unsigned_int_2_10_10_10_rev = gl.UNSIGNED_INT_2_10_10_10_REV,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.0 (Core Profile)
    //----------------------------------------------------------------------------------------------
    half_float = gl.HALF_FLOAT,
    unsigned_int_10_f_11_f_11_f_rev = gl.UNSIGNED_INT_10F_11F_11F_REV,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.3 (Core Profile)
    //----------------------------------------------------------------------------------------------
    int_2_10_10_10_rev = gl.INT_2_10_10_10_REV,
};

pub const PrimitiveType = enum(Enum) {
    //----------------------------------------------------------------------------------------------
    // OpenGL 1.0 (Core Profile)
    //----------------------------------------------------------------------------------------------
    points = gl.POINTS,
    line_strip = gl.LINE_STRIP,
    line_loop = gl.LINE_LOOP,
    lines = gl.LINES,
    triangle_strip = gl.TRIANGLE_STRIP,
    triangle_fan = gl.TRIANGLE_FAN,
    triangles = gl.TRIANGLES,
    //----------------------------------------------------------------------------------------------
    // OpenGL 3.2 (Core Profile)
    //----------------------------------------------------------------------------------------------
    line_strip_adjacency = gl.LINE_STRIP_ADJACENCY,
    lines_adjacency = gl.LINES_ADJACENCY,
    triangle_strip_adjacency = gl.TRIANGLE_STRIP_ADJACENCY,
    triangles_adjacency = gl.TRIANGLES_ADJACENCY,
};

pub const Capability = enum(Enum) {
    //---------------------------------------------------------------------------------------------
    // OpenGL 1.0 (Core Profile)
    //---------------------------------------------------------------------------------------------
    blend = gl.BLEND,
    cull_face = gl.CULL_FACE,
    depth_test = gl.DEPTH_TEST,
    dither = gl.DITHER,
    line_smooth = gl.LINE_SMOOTH,
    polygon_smooth = gl.POLYGON_SMOOTH,
    scissor_test = gl.SCISSOR_TEST,
    stencil_test = gl.STENCIL_TEST,
    //---------------------------------------------------------------------------------------------
    // OpenGL 1.1 (Core Profile)
    //---------------------------------------------------------------------------------------------
    color_logic_op = gl.COLOR_LOGIC_OP,
    polygon_offset_fill = gl.POLYGON_OFFSET_FILL,
    polygon_offset_line = gl.POLYGON_OFFSET_LINE,
    polygon_offset_point = gl.POLYGON_OFFSET_POINT,
    //---------------------------------------------------------------------------------------------
    // OpenGL 1.3 (Core Profile)
    //---------------------------------------------------------------------------------------------
    multisample = gl.MULTISAMPLE,
    sample_alpha_to_coverage = gl.SAMPLE_ALPHA_TO_COVERAGE,
    sample_alpha_to_one = gl.SAMPLE_ALPHA_TO_ONE,
    sample_coverage = gl.SAMPLE_COVERAGE,
    //---------------------------------------------------------------------------------------------
    // OpenGL 2.0 (Core Profile)
    //---------------------------------------------------------------------------------------------
    program_point_size = gl.PROGRAM_POINT_SIZE,
    //---------------------------------------------------------------------------------------------
    // OpenGL 3.0 (Core Profile)
    //---------------------------------------------------------------------------------------------
    framebuffer_srgb = gl.FRAMEBUFFER_SRGB,
    rasterizer_discard = gl.RASTERIZER_DISCARD,
    //---------------------------------------------------------------------------------------------
    // OpenGL 3.1 (Core Profile)
    //---------------------------------------------------------------------------------------------
    primitive_restart = gl.PRIMITIVE_RESTART,
    //---------------------------------------------------------------------------------------------
    // OpenGL 3.2 (Core Profile)
    //---------------------------------------------------------------------------------------------
    depth_clamp = gl.DEPTH_CLAMP,
    sample_mask = gl.SAMPLE_MASK,
    texture_cube_map_seamless = gl.TEXTURE_CUBE_MAP_SEAMLESS,
    //---------------------------------------------------------------------------------------------
    // OpenGL 4.0 (Core Profile)
    //---------------------------------------------------------------------------------------------
    sample_shading = gl.SAMPLE_SHADING,
};

pub fn createShader(@"type": ShaderType) Shader {
    return @as(Shader, @bitCast(gl.createShader(@intFromEnum(@"type"))));
}

pub fn deleteShader(shader: Shader) void {
    assert(@as(Uint, @bitCast(shader)) > 0);
    gl.deleteShader(@as(Uint, @bitCast(shader)));
}

// using single continuous source string
pub fn shaderSource(shader: Shader, source: [:0]const u8) void {
    const shaderId = @as(Uint, @bitCast(shader));
    assert(shaderId > 0);
    const sources = [_][*c]const Char{@ptrCast(source.ptr)};
    gl.shaderSource(shaderId, 1, &sources, null);
}

pub fn compileShader(shader: Shader) void {
    assert(@as(Uint, @bitCast(shader)) > 0);
    gl.compileShader(@as(Uint, @bitCast(shader)));
}

pub fn createProgram() Program {
    return @as(Program, @bitCast(gl.createProgram()));
}

pub fn deleteProgram(program: Program) void {
    assert(@as(Uint, @bitCast(program)) > 0);
    gl.deleteProgram(@as(Uint, @bitCast(program)));
}

pub fn attachShader(program: Program, shader: Shader) void {
    assert(@as(Uint, @bitCast(program)) > 0);
    assert(@as(Uint, @bitCast(shader)) > 0);
    gl.attachShader(@as(Uint, @bitCast(program)), @as(Uint, @bitCast(shader)));
}

pub fn linkProgram(program: Program) void {
    assert(@as(Uint, @bitCast(program)) > 0);
    gl.linkProgram(@as(Uint, @bitCast(program)));
}

pub fn genVertexArray(ptr: *VertexArrayObject) void {
    gl.genVertexArrays(1, @as([*c]Uint, @ptrCast(ptr)));
}

pub fn genVertexArrays(arrays: []VertexArrayObject) void {
    gl.genVertexArrays(@intCast(arrays.len), @ptrCast(arrays.ptr));
}

pub fn deleteVertexArray(ptr: *const VertexArrayObject) void {
    gl.deleteVertexArrays(1, @ptrCast(ptr));
}

pub fn deleteVertexArrays(arrays: []const VertexArrayObject) void {
    gl.deleteVertexArrays(@intCast(arrays.len), @ptrCast(arrays.ptr));
}

pub fn bindVertexArray(array: VertexArrayObject) void {
    gl.bindVertexArray(@as(Uint, @bitCast(array)));
}

pub fn genBuffer(ptr: *Buffer) void {
    gl.genBuffers(1, @as([*c]Uint, @ptrCast(ptr)));
}

pub fn genBuffers(buffers: []Buffer) void {
    gl.genBuffers(@intCast(buffers.len), @as([*c]Uint, @ptrCast(buffers.ptr)));
}

pub fn bufferData(
    target: BufferTarget,
    size: usize,
    bytes: ?*const anyopaque,
    usage: BufferUsage,
) void {
    assert(size > 0);
    gl.bufferData(
        @intFromEnum(target),
        @as(Sizeiptr, @bitCast(size)),
        bytes,
        @intFromEnum(usage),
    );
}

pub fn bindBuffer(target: BufferTarget, buffer: Buffer) void {
    gl.bindBuffer(@intFromEnum(target), @as(Uint, @bitCast(buffer)));
}

pub fn enableVertexAttribArray(location: VertexAttribLocation) void {
    gl.enableVertexAttribArray(@as(Uint, @bitCast(location)));
}

pub fn vertexAttribPointer(
    location: VertexAttribLocation,
    size: u32,
    attrib_type: VertexAttribType,
    normalised: Boolean,
    stride: u32,
    offset: usize,
) void {
    gl.vertexAttribPointer(
        @as(Uint, @bitCast(location)),
        @as(Int, @bitCast(size)),
        @intFromEnum(attrib_type),
        normalised,
        @as(Sizei, @bitCast(stride)),
        @as(*allowzero const anyopaque, @ptrFromInt(offset)),
    );
}

pub fn drawElements(mode: PrimitiveType, count: u32, @"type": VertexAttribType, indices: ?*const anyopaque) void {
    gl.drawElements(@intFromEnum(mode), @as(Sizei, @bitCast(count)), @intFromEnum(@"type"), indices);
}

pub fn useProgram(program: Program) void {
    gl.useProgram(@as(Uint, @bitCast(program)));
}

pub fn viewport(x: Int, y: Int, width: i32, height: i32) void {
    gl.viewport(x, y, @as(Sizei, @bitCast(width)), @as(Sizei, @bitCast(height)));
}

pub fn enable(capability: Capability) void {
    gl.enable(@intFromEnum(capability));
}
