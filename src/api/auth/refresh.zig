const std = @import("std");
const tk = @import("tokamak");
const token = @import("../../util.zig").token;

const Success = @import("response").Success;
const Config = @import("../../Config.zig");

const RefreshDTO = struct {
    rt: []const u8,
};
// TODO: This route is not works in swagger
pub fn refresh(
    req: tk.Request,
    token_fingerprints: *std.StringHashMap([]const u8),
    config: Config,
    data: RefreshDTO,
) !Success(token.Pair) {
    const pair = try token.refresh(
        req.arena,
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
