## Ways To Design An Efficient ECS System

### Organize Entities For Efficient Look Up

1. Archetype Pattern
    - Entities grouped by makeup (archetype)
    - System only iterates over archetypes that contain set of components its interested in
    - Highly efficient, minimizes cache misses and uncessary checks
2. Component Masking / Bitsets
    - Each entity has a bitmask representing components
    - System determines if entity has all necessary components by & b/w entity comp mask and system comp mask 
3. Observer Pattern
    - When comp removed/added from entity, ECS notifies systems that are interested in those components
    - Systems maintain a list of entities they are interested in w/o having to check every entity in world
4. Sparse Sets
    - Data structure efficiently associates entities w/ comps and can quickly iterate over entities with comp
5. Indexing / Look-up Tables
    - Look-up table to track which entites have which components

### Parallelization

- Run systems that don't have interdependencies 
- Order of execution for certain things matters
- Renderer goes last
- Audio can be parallel with renderer

### Bevy

**Sparse Sets** (Less Memory)
  - Efficiently store data for entities w/ very small or very large number of comps
  - Don't require pre-allocatin of memory, helps handle dynamic number of entities and components

**Tables** (Faster Execution)
  - Good for storing comp data when all entities have the same set of comps
  - Efficiently store data for entities with large number of comps
  - Fast access to component data for all entities
  - Need pre allocation of memory, not good for dynamic number of comps
- Bevy uses sparse set by default but tables can be explicitly specified for comps that need performance benefits of tables
- These can be useful for batch processing and spatial partitioning, flexible/scalable
- Bevy uses tables for physics and rendering
  - Transform and velocity comps for all entities, allow for parallel computation
  - Mesh and materials comps for all entities -> parallel
- Sparse set for health, inventory, ai etc.

**Entity Pooling**
- World is sparse set of entities
- Reuse entity IDs for entities that are destroyed and then recreated
- Avoid allocating new memory for entities
1. New entity -> new ID
2. Add entity to sparse set world
3. Destroy entity -> remove from sparse set world
4. Reuse ID for destroyed entity when a new entity is created

**Archetype**
- Group entities together based on comps they have
  - Entities w/ transform, velocity and mesh could be grouped to same archetype 
- Efficiently performoperations on groups of entities, such as rendering and physics simulation 

**DAG Scheduler**
- Represents dependencies b/w systems
  - Rendering after physics system to get updated positions

**Events**
- 

