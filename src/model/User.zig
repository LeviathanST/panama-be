const std = @import("std");
const Pool = @import("pg").Pool;

pub const FindError = error{UserNotFound};

id: u64,
username: []const u8,
password: []const u8,

pub fn existedById(pool: *Pool, id: u64) !bool {
    const conn = try pool.acquire();
    defer conn.deinit();

    const row = conn.row(
        \\ SELECT EXISTS (SELECT 1 FROM "user" WHERE id = $1) as "exists"
    , .{id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("PG error message: {s}", .{pg_err.message});
        }
        return err;
    };

    return row.?.getCol(bool, "exists");
}
