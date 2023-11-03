const std = @import("std");

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
