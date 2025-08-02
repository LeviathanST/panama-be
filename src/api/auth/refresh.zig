const std = @import("std");
const tk = @import("tokamak");
const token = @import("../../util.zig").token;

const Success = @import("../../response.zig").Success;
const Config = @import("../../Config.zig");

const RefreshDTO = struct {
    rt: []const u8,
};
// TODO: This route is not works in swagger
pub fn refresh(
    arena: *std.heap.ArenaAllocator,
    token_fingerprints: *std.StringHashMap([]const u8),
    config: Config,
    data: RefreshDTO,
) !Success(token.Pair) {
    const pair = try token.refresh(
        arena.allocator(),
        token_fingerprints,
        data.rt,
        config.app.at_secret,
        config.app.rt_secret,
    );
    return .{
        .message = "Refresh token successful!",
        .data = pair,
    };
}
