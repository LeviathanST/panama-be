const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const Sponsor = @import("../../model.zig").Sponsor;

const InsertDTO = struct {
    src: []const u8,
    alt: []const u8,
};

pub fn create(
    pool: *pg.Pool,
    dto: InsertDTO,
) !Success(?u8) {
    try Sponsor.insert(pool, dto.src, dto.alt);
    return .{
        .message = "Add sponsor successfully!",
        .data = null,
    };
}
