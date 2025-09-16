const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const Sponsor = @import("../../model.zig").Sponsor;

pub fn getAll(
    alloc: std.mem.Allocator,
    pool: *pg.Pool,
) !Success([]Sponsor) {
    var list = try Sponsor.getAll(pool, alloc);
    defer list.deinit(alloc);
    return .{
        .message = "Get all sponsors successfully!",
        .data = try list.toOwnedSlice(alloc),
    };
}
