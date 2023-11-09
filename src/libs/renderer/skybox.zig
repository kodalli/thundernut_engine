const gl = @import("gl");
const std = @import("std");
const zstbi = @import("zstbi");

const vertexShader =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\out vec3 TexCoords;
    \\
    \\uniform mat4 projection;
    \\uniform mat4 view;
    \\
    \\void main() {
    \\  TexCoords = aPos;
    \\  gl_Position = projection * view * vec4(aPos, 1.0);
    \\}
;

const fragmentShader =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\in vec3 TexCoords;
    \\
    \\uniform samplerCube skybox;
    \\
    \\void main() {
    \\  FragColor = texture(skybox, TexCoords);
    \\}
;

// Render the skybox last so fragments can be discarded in early depth testing to save bandwidth
// Avoids rendering stuff that won't be visible

pub fn loadCubemap(faces: std.ArrayList([:0]u8)) !void {
    var textureID: gl.GLuint = undefined;
    gl.genTextures(1, &textureID);
    gl.bindTexture(gl.TEXTURE_CUBE_MAP, textureID);

    for (0..faces.items.len, faces.items) |i, face_path| {
        var img = try zstbi.Image.loadFromFile(face_path, 0);
        gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl.RGB, img.width, img.height, 0, gl.RGB, gl.UNSIGNED_BYTE, &img.data);
        img.deinit();
    }

    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE);
}

pub fn renderSkybox() void {
    gl.depthMask(gl.FALSE);
    skyboxShader.use();

    // set view and projectio matrix
    gl.bindVertexArray(skyboxVAO);
    gl.bindTexture(gl.TEXTURE_CUBE_MAP, cubeMapTexture);
    gl.drawArrays(gl.TRIANGLES, 0, 36);
    gl.depthMask(gl.TRUE);
}
