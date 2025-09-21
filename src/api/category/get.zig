const std = @import("std");
const pg = @import("pg");
const Category = @import("../../model.zig").Category;
const Success = @import("../../response.zig").Success;

const UpdateDTO = struct {
    new_url: []const u8,
    new_name: []const u8,
};

pub fn get(pool: *pg.Pool, alloc: std.mem.Allocator) !Success([]Category) {
    var categories = try Category.getAll(pool, alloc);
    defer categories.deinit(alloc);

    return .{
        .message = "Get all categories info successfully!",
        .data = try categories.toOwnedSlice(alloc),
    };
}
