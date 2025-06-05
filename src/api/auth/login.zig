const std = @import("std");
const tk = @import("tokamak");
const Success = @import("response").Success;
const pg = @import("pg");
const util = @import("../../util.zig");

const Pair = util.token.Pair;
const User = @import("model").User;
const Config = @import("../../Config.zig");

pub const Error = error{WrongPassword};

const LoginDTO = struct {
    username: []const u8,
    password: []const u8,
};

pub fn login(
    req: tk.Request,
    token_fingerprints: *std.StringHashMap([]const u8),
    config: Config,
    p: *pg.Pool,
    data: LoginDTO,
) !Success(Pair) {
    try loginInternal(req.arena, p, data);
    const pair = try util.token.generate(
        req.arena,
        token_fingerprints,
        config.app.at_secret,
        config.app.rt_secret,
        data.username,
    );
    return .with(.{
        .message = "Login successful",
        .data = pair,
    });
}

fn loginInternal(alloc: std.mem.Allocator, pool: *pg.Pool, data: LoginDTO) !void {
    const user = try User.findByUsername(alloc, pool, data.username);
    std.crypto.pwhash.bcrypt.strVerify(
        user.password,
        data.password,
        .{ .silently_truncate_password = false },
    ) catch |err| switch (err) {
        std.crypto.pwhash.KdfError.PasswordVerificationFailed => return Error.WrongPassword,
        else => return err,
    };
}
