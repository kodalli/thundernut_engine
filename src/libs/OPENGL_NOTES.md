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

### Renderer

#### Forward Renderer
- Does all material/lighting calculations in single pass
- Clustered Forward / Forward + renderer
  - Break view frustum into clusters
  - Assign lights to clusters
  - Can get more lights than traditional forward renderer
- MSAA works

### Deferred Renderer
- One or more pre-passes to collect relevant info on scene
- Do material/lighting calculation in screen space in final pass after
- Cuts down on shading cost by only shading visible fragments, more lights in scene
- More complicated
- Can be more expensive than equivalent forward renderer in some situations
- Use more texture bandwidth
- No MSAA
- Transparency is harder/less straightforward to do

### GPU Driven Rendering
- CPU normal makes bind calls and draw calls for each entity
- For each data type (meshes, materials, transforms, textures) create single array with all data of that datatype and bind these arrays once to avoid per entity/pre draw rebinds

### Pipelined Rendering
- Extract data from "main world" into separate "render world"
- Randers frame N in the render app, while main app simulates frame N+1
- Clear all entities b/w frames, enables consistent entity mapping b/w main and render worlds, while still being able to spawn new entities in the render world that don't exist in the main world
- Problem is that significant archetype moves and copies because using table
- Solution to switch to EntityHashMap


### Shadows

#### PCF Shadow Fitlering 
- Percentage-Close Filtering
  - Take multiple samples from shadow map
  - Compare w/ an interpolated mesh surface depth-projected into the frame of reference light
  - Calculates percentage of sampels in the depth buffer that are closer to the light than the mesh surface
- Essentially creates a blur effect, improves shadow quality
- Lets you use low res shadow maps

#### Shadow Map Filter by Jimenez14
- Cheaper than Castano but can flicker
- Need Temporal Anit-Aliasing (TAA) to reduce flicker
- Bends shadow cascades more smoothly than Castano

### Transparency
 - glFrontFace, GL_CCW
 - glEnable, glDisable with arg GL_CULL_FACE

### Batching / Instancing
- Entities w/ same material and mesh can be batched
- Things that don't need to rebind won't incur runtime cost
- If pipeline (shaders), bind group (shader-accessible bound data), vertex/index buffer (mesh) is different, it can't be batched

- very close/overlap objects
- near 0.1f
- far 10.0f