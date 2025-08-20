const std = @import("std");
const pg = @import("pg");
id: i32,
src: []const u8,
alt: []const u8,

pub fn getAll(pool: *pg.Pool, alloc: std.mem.Allocator) !std.ArrayList(@This()) {
    var conn = try pool.acquire();
    defer conn.release();
    const rs = try conn.query("SELECT * FROM sponsor", .{});
    defer rs.deinit();
    var list = std.ArrayList(@This()).init(alloc);
    errdefer list.deinit();
    while (try rs.next()) |row| {
        const inst = try row.to(@This(), .{ .allocator = alloc });
        try list.append(inst);
    }
    return list;
}

pub fn insert(pool: *pg.Pool, src: []const u8, alt: []const u8) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\INSERT INTO sponsor(src, alt)
        \\VALUES ($1, $2)
    , .{ src, alt });
}
pub fn delete(pool: *pg.Pool, id: i32) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\DELETE FROM sponsor
        \\WHERE id = $1
    , .{id});
}
pub fn update(
    pool: *pg.Pool,
    id: i32,
    new_src: []const u8,
    new_alt: []const u8,
) !void {
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec(
        \\UPDATE sponsor
        \\SET (src, alt) = ($1, $2)
        \\WHERE id = $3
    , .{ new_src, new_alt, id });
}
