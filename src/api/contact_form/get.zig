const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const ContactForm = @import("../../model.zig").ContactForm;

pub fn getAll(
    alloc: std.mem.Allocator,
    pool: *pg.Pool,
) !Success([]ContactForm) {
    var list = try ContactForm.getAll(pool, alloc);
    defer list.deinit();
    return .{
        .message = "Get all contact forms successfully!",
        .data = try list.toOwnedSlice(),
    };
}
