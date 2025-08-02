const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const util = @import("../../util.zig");

const Pair = util.token.Pair;
const Success = @import("../../response.zig").Success;
const User = @import("../../model.zig").User;
const Config = @import("../../Config.zig");

pub const Error = error{WrongPassword};

const LoginDTO = struct {
    username: []const u8,
    password: []const u8,
};

pub fn login(
    token_fingerprints: *std.StringHashMap([]const u8),
    arena: *std.heap.ArenaAllocator,
    config: Config,
    pool: *pg.Pool,
    data: LoginDTO,
) !Success(Pair) {
    try loginInternal(arena.allocator(), pool, data);
    const pair = try util.token.generate(
        arena.allocator(),
        token_fingerprints,
        config.app.at_secret,
        config.app.rt_secret,
        data.username,
    );
    return .{
        .message = "Login successful",
        .data = pair,
    };
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
