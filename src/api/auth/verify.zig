const std = @import("std");
const AuthData = @import("../../middleware.zig").Auth.Data;
pub fn verify(auth_data: AuthData) !void {
    std.log.info("You are logged with account id {d}", .{auth_data.account_id});
}
