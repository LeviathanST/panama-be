const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const Sponsor = @import("../../model.zig").Sponsor;

const UpdateDTO = struct {
    new_src: []const u8,
    new_alt: []const u8,
};

pub fn update(
    pool: *pg.Pool,
    id: i32,
    dto: UpdateDTO,
) !Success(?u8) {
    try Sponsor.update(
        pool,
        id,
        dto.new_src,
        dto.new_alt,
    );
    return .{
        .message = "Update sponsor successfully!",
        .data = null,
    };
}
