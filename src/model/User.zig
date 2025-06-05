const std = @import("std");
const Pool = @import("pg").Pool;

pub const FindError = error{UserNotFound};
pub const InsertError = error{UserExisted};

pub const Self = @This();

id: i32,
username: []const u8,
password: []const u8,

pub fn insert(pool: *Pool, username: []const u8, password: []const u8) !void {
    const conn = try pool.acquire();
    defer conn.deinit();

    _ = conn.exec(
        \\ INSERT INTO "user" (username, password)
        \\ VALUES ($1, $2)
    , .{ username, password }) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("PG error message: {s}", .{pg_err.message});
            if (pg_err.isUnique()) return InsertError.UserExisted;
        }
        return err;
    };
}

pub fn findIdByUsername(pool: *Pool, username: []const u8) !i32 {
    const conn = try pool.acquire();
    defer conn.deinit();

    var row = conn.row(
        \\ SELECT id FROM "user" WHERE username = $1
    , .{username}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("PG error message: {s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.UserNotFound;
    defer row.deinit() catch unreachable;
    return row.getCol(i32, "id");
}

pub fn findByUsername(alloc: std.mem.Allocator, pool: *Pool, username: []const u8) !Self {
    const conn = try pool.acquire();
    defer conn.deinit();

    var row = conn.row(
        \\ SELECT * FROM "user" WHERE username = $1
    , .{username}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("PG error message: {s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.UserNotFound;
    defer row.deinit() catch unreachable;

    const user = try row.to(Self, .{ .map = .name, .allocator = alloc });
    return user;
}
