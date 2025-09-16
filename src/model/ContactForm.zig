const std = @import("std");
const pg = @import("pg");

id: i32,
guess_name: []const u8,
email: []const u8,
interest_area: []const u8,
content: []const u8,
created_at: i64,
is_confirmed: bool,

pub fn getAll(pool: *pg.Pool, alloc: std.mem.Allocator) !std.ArrayList(@This()) {
    var conn = try pool.acquire();
    defer conn.release();
    const rs = try conn.query("SELECT * FROM contact_form", .{});
    defer rs.deinit();
    var list = std.array_list.Aligned(@This(), null).empty;
    errdefer list.deinit(alloc);
    while (try rs.next()) |row| {
        const inst = try row.to(@This(), .{ .allocator = alloc });
        try list.append(alloc, inst);
    }
    return list;
}

pub fn insert(
    pool: *pg.Pool,
    guess_name: []const u8,
    email: []const u8,
    interest_area: []const u8,
    content: []const u8,
) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\INSERT INTO contact_form(guess_name, email, interest_area, content)
        \\VALUES ($1, $2, $3, $4)
    , .{ guess_name, email, interest_area, content });
}
pub fn delete(pool: *pg.Pool, id: i32) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\DELETE FROM contact_form
        \\WHERE id = $1
    , .{id});
}
pub fn updateConfirm(
    pool: *pg.Pool,
    id: i32,
    new_value: bool,
) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\UPDATE contact_form
        \\SET is_confirmed = $1
        \\WHERE id = $2
    , .{ new_value, id });
}
