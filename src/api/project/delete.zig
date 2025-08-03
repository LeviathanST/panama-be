const std = @import("std");
const Pool = @import("pg").Pool;
const Project = @import("../../model.zig").Project;
const Success = @import("../../response.zig").Success;

pub fn delete(pool: *Pool, alloc: std.mem.Allocator, id: i32) !Success(?u8) {
    try Project.delete(pool, alloc, id);
    return .{
        .message = "Delete a project successful!",
        .data = null,
    };
}
