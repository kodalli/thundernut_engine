const gl = @import("gl");

// Must call unloadShaders to delete the shaderProgram
pub fn loadShaders(vert: [:0]const u8, frag: [:0]const u8) gl.GLuint {
    const vertPtr = &[_][*c]const u8{@ptrCast(vert.ptr)};
    const fragPtr = &[_][*c]const u8{@ptrCast(frag.ptr)};

    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(vertexShader, 1, vertPtr, null);
    gl.compileShader(vertexShader);

    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(fragmentShader, 1, fragPtr, null);
    gl.compileShader(fragmentShader);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    gl.useProgram(shaderProgram);

    return shaderProgram;
}

pub fn unloadShaders(shaderProgram: gl.GLuint) void {
    gl.deleteProgram(shaderProgram);
}
