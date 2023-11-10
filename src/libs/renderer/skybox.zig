const gl = @import("gl");
const std = @import("std");
const zstbi = @import("zstbi");
const shaders = @import("shaders.zig");
const zmath = @import("zmath");

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
    \\  vec4 pos = projection * view * vec4(aPos, 1.0);
    \\  // Normalized device coordinates, makes z value equal to 1.0, the max depth value
    \\  // Only renders when no objects in front
    \\  gl_Position = pos.xyww;
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
    \\void main() {nrChannels
    \\  FragColor = texture(skybox, TexCoords);
    \\}
;

const skyboxVertices: [36][3]f32 = .{
    // positions
    .{ -1.0, 1.0, -1.0 },
    .{ -1.0, -1.0, -1.0 },
    .{ 1.0, -1.0, -1.0 },
    .{ 1.0, -1.0, -1.0 },
    .{ 1.0, 1.0, -1.0 },
    .{ -1.0, 1.0, -1.0 },

    .{ -1.0, -1.0, 1.0 },
    .{ -1.0, -1.0, -1.0 },
    .{ -1.0, 1.0, -1.0 },
    .{ -1.0, 1.0, -1.0 },
    .{ -1.0, 1.0, 1.0 },
    .{ -1.0, -1.0, 1.0 },

    .{ 1.0, -1.0, -1.0 },
    .{ 1.0, -1.0, 1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ 1.0, 1.0, -1.0 },
    .{ 1.0, -1.0, -1.0 },

    .{ -1.0, -1.0, 1.0 },
    .{ -1.0, 1.0, 1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ 1.0, -1.0, 1.0 },
    .{ -1.0, -1.0, 1.0 },

    .{ -1.0, 1.0, -1.0 },
    .{ 1.0, 1.0, -1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ 1.0, 1.0, 1.0 },
    .{ -1.0, 1.0, 1.0 },
    .{ -1.0, 1.0, -1.0 },

    .{ -1.0, -1.0, -1.0 },
    .{ -1.0, -1.0, 1.0 },
    .{ 1.0, -1.0, -1.0 },
    .{ 1.0, -1.0, -1.0 },
    .{ -1.0, -1.0, 1.0 },
    .{ 1.0, -1.0, 1.0 },
};

pub const Cubemap = struct {
    cubemapTexture: gl.GLuint = undefined,
    shaderProgram: gl.GLuint = undefined,
    skyboxVAO: gl.GLuint = undefined,
    projectionLoc: gl.GLint = undefined,
    viewLoc: gl.GLint = undefined,

    // Render the skybox last so fragments can be discarded in early depth testing to save bandwidth
    // Avoids rendering stuff that won't be visible
    pub fn init(self: *Cubemap, faces: [6][:0]u8) !*Cubemap {
        gl.genTextures(1, &self.cubemapTexture);
        gl.bindTexture(gl.TEXTURE_CUBE_MAP, self.cubemapTexture);

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

        gl.genVertexArrays(&self.skyboxVAO);
        self.shaderProgram = shaders.loadShaders(vertexShader, fragmentShader);

        self.projectionLoc = gl.getUniformLocation(self.shaderProgram, "projection");
        self.viewLoc = gl.getUniformLocation(self.shaderProgram, "view");
    }

    pub fn deinit(self: *Cubemap) void {
        shaders.unloadShaders(self.shaderProgram);
        gl.deleteTextures(1, &self.cubemapTexture);
        gl.deleteVertexArrays(1, &self.skyboxVAO);
    }

    pub fn renderSkybox(self: *Cubemap, projection: zmath.Mat, partialView: zmath.Mat) void {
        gl.depthMask(gl.FALSE);
        gl.useProgram(self.shaderProgram);

        // set view and projection matrix
        const projectionPtr = zmath.arrNPtr(&projection);
        const viewPtr = zmath.arrNPtr(&partialView);
        gl.uniformMatrix4fv(self.projectionLoc, 1, gl.FALSE, projectionPtr);
        gl.uniformMatrix4fv(self.viewLoc, 1, gl.FALSE, viewPtr);

        gl.bindVertexArray(self.skyboxVAO);
        gl.bindTexture(gl.TEXTURE_CUBE_MAP, self.cubemapTexture);
        gl.drawArrays(gl.TRIANGLES, 0, 36);
        gl.depthMask(gl.TRUE);
    }
};
