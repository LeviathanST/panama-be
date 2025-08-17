const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const Sponsor = @import("../../model.zig").Sponsor;

pub fn delete(
    pool: *pg.Pool,
    id: i32,
) !Success(?u8) {
    try Sponsor.delete(pool, id);
    return .{
        .message = "Delete sponsors successfully!",
        .data = null,
    };
}
