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

#### Parallelize Sparse Sets
- Using chunking to divide sparse set into smaller chunks then process each chunk in parallel
    1. Create list of chunks, each chunk is subset of sparse set
    2. For each chunk create new thread/task to process chunk
    3. Process each chunk in parallel
    4. Once all chunks processed, merge results back into sparse set
- To handle dependent components, use component filtering which process entities in a chunk that have the required components
    1. Get list of all entities in chunk
    2. Filter the list of entities to only include entities that have the required components
    3. Process filtered list of entities
- When order matters use a DAG to schedule execution
- Archetype table to speed up filtering

#### Archetype Table
- All components will be known at compile time and have ids
    - When you register a component check if comp id exists otherwise add
- Need a vec of component ids
- Get Archetype id or insert new one

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
- like unity, subscribe and listeners

**One-Shot Systems**
- Run arbitrary logic on demand, not every frame

#### Sparse Set Implementation
**Values**
- Sparse array
  - Holds indices of actual elements [2, 7, 9, ...] 
- Dense array
  - Stores actual set elements [0, 1, 2, ...]
- N 
  - Current number of elements
- Capacity
  - Capacity of set or size of dense array
- MaxValue
  - Max value in set or size of sparse array

**Functions**
- Search(x: int)
  - If element present, return index of element in dense array else -1
- Insert(x: int)
  - Insert new element into set
- Deletion(x: int)
  - Deletes an element
- Intersection(sparseSet) 
  - Finds intersection of this set with s and returns pointer to result
- SetUnion(sparseSet)
  - Find union of two sets
