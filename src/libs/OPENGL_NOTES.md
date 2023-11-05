## Managing Vertex Buffers

### Big VBO vs VBO per VAO

- Huge VBO w/ pos of all objs shared by all VAOs, each VAO has offset and len
- One VBO per VAO w/ only pos of the instances for its vertex data
- Huge VBO for static objects and one smaller VBO for moving ones

1. For relatively few large objects using separate VBO per objects is fine
2. For large num of small objs, store groups of objs in same VBO better, draw groups of related objs w/ single call
3. For small subset of world drawn each frame, like player changing rooms: group objs that are drawn at same time (same room) should be in same VBO, and objs that are never drawn at same time in diff VBO
4. Subset of vertices is frequently modified: keep dynamic vertices in separate VBO and keep other VBOs completely static

If you have multiple instances of same obj type like prefabs of same geometry, share vertex data between them

> https://stackoverflow.com/questions/27473234/is-combining-instance-vbos-a-good-idea

### How Prefabs Can Be Rendered

- `glDrawElementsInstanced` renders multiple instances of same mesh geometry w/ diff transformations efficiently
- Reuses same vertex data for each instance but apply diff transformation matrix
- Draw a lot in single draw call (grass, trees, bricks etc.)

1. Vertex shader accpet additional attribute that chagnes per instance, not per vertex
    - Model matrix applied to each instance of mesh to get world space, (t, r, s)
2. Instance buffer with transformation matrices for each instance of mesh.
    - Buffer bound to attribute location in shader
    - Attribute divisor set to 1 using `glVertexAttribDivisor`
        - Tells OpenGL that this attr should advance once per instance not per vertex
3. Draw call using `glDrawElementsInstance` provide count of instance to draw, then OpenGL draws N instances each with transformations

### Primitives

1. Cube
2. Sphere
3. Capsule
4. Cylinder
5. Plane
6. Quad

### Uniform Buffer Objects (UBO)

- If the unifomrs are part of a block and odn't change b/w draws, can use a UBO to set mutliple uniforms at once
- Upload data once to the bufer then bind that buffer to the shader

### Shader Storage Buffer Objects (SSBO)

- For dynamic data
