const std = @import("std");
const pg = @import("pg");
const base_type = @import("../../base_type.zig");
const Project = @import("../../model.zig").Project;
const Success = @import("../../response.zig").Success;

pub fn getAll(pool: *pg.Pool, alloc: std.mem.Allocator) !Success([]base_type.ProjectResponse) {
    var list = try Project.getAll(pool, alloc);
    defer list.deinit();
    return .{
        .message = "Get all project id successful!",
        .data = try list.toOwnedSlice(),
    };
}
