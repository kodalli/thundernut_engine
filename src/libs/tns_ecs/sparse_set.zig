const std = @import("std");

pub const SparseSet = struct {
    sparseArray: []i32,
    denseArray: []i32,
    numElements: i32,
    capacity: i32,
    maxValue: i32,

    pub fn init(allocator: std.mem.Allocator, maxV: i32, cap: i32) SparseSet {
        return .{
            .sparseArray = allocator.alloc([]i32, maxV+1),
            .denseArray = allocator.alloc([]i32, cap),
            .capacity = cap,
            .maxValue = maxV,
            .numElements = 0,
        };
    }

    pub fn deinit(self: *SparseSet, allocator: std.mem.Allocator) void {
        allocator.free(self.sparseArray);
        allocator.free(self.denseArray);
    }

    pub fn search(self: *SparseSet, x: i32) i32 {
        if (x > self.maxValue) {
            return -1;
        }

        if (self.sparseArray[x] < self.numElements and self.denseArray[self.sparseArray[x]] == x) {
            return self.sparseArray[x];
        }

        return -1;
    }

    pub fn insert(self: *SparseSet, x: i32) void {
        if (x > self.maxValue) {
            return;
        }

        if (self.numElements >= self.capacity) {
            return;
        }

        if (self.search(x) != -1) {
            return;
        }

        self.denseArray[self.numElements] = x;
        self.sparseArray[x] = self.numElements;
        self.numElements += 1;
    }

    pub fn delete(self: *SparseSet, x: i32) void {
        if (self.search(x) == -1) {
            return;
        }

        const temp = self.denseArray[self.maxValue - 1];
        self.denseArray[self.sparseArray[x]] = temp;
        self.sparseArray[temp] = self.sparseArray[x];

        self.numElements -= 1;
    }

    pub fn clear(self: *SparseSet) void {
        self.numElements = 0;
    }

    pub fn intersection(self: *SparseSet, other: *SparseSet, allocator: std.mem.Allocator) *SparseSet {
        const iCap = @min(self.numElements, other.numElements);
        const iMaxVal = @max(other.maxValue, self.maxValue);

        var result = SparseSet.init(allocator, iMaxVal, iCap);

        if (self.numElements < other.numElements) {
            for (0..self.numElements) |i| {
                if (other.search(self.denseArray[i]) != -1) {
                    result.insert(self.denseArray[i]);                      
                }
            }
        } else {
            for (0..other.numElements) |i| {
                if (self.search(other.denseArray[i]) != -1) {
                    result.insert(other.denseArray[i]);
                }
            }
        }

        return result; 
    }

    pub fn setUnion(self: *SparseSet, other: *SparseSet, allocator: std.mem.Allocator) *SparseSet {
        const uCap = other.numElements + self.numElements;
        const uMaxVal = @max(other.maxValue, self.maxValue);
        var result = SparseSet.init(allocator, uMaxVal, uCap);

        for (0..self.numElements) |i| {
            result.insert(self.denseArray[i]);
        }

        for (0..other.numElements) |i| {
            result.insert(other.denseArray[i]);
        }

        return result;
    }

};