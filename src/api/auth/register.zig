const std = @import("std");
const pg = @import("pg");

const User = @import("model").User;
const Success = @import("response").Success;
const Config = @import("../../Config.zig");

pub const Error = User.InsertError;

const RegisterDTO = struct {
    username: []const u8,
    password: []const u8,
};

pub fn register(config: Config, pool: *pg.Pool, data: RegisterDTO) !Success(?u8) {
    try registerInternal(pool, config.app.round_hashing, data);
    return .{
        .message = "Register sucessful!",
        .data = null,
    };
}
fn registerInternal(p: *pg.Pool, round_hashing: u6, data: RegisterDTO) !void {
    var buf: [std.crypto.pwhash.bcrypt.hash_length * 2]u8 = undefined;
    const hash = try std.crypto.pwhash.bcrypt.strHash(
        data.password,
        .{
            .params = .{
                .rounds_log = round_hashing,
                .silently_truncate_password = false,
            },
            .encoding = .crypt,
        },
        &buf,
    );
    try User.insert(p, data.username, hash);
}
