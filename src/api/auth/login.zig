const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const util = @import("../../util.zig");

const Pair = util.token.Pair;
const Success = @import("../../response.zig").Success;
const User = @import("../../model.zig").User;
const Config = @import("../../Config.zig");

pub const Error = error{ WrongPassword, LimitLogin };

const LoginDTO = struct {
    username: []const u8,
    password: []const u8,
};

pub const LimitLogin = struct { times: u2, at: i64 };

pub fn login(
    token_fingerprints: *std.StringHashMap([]const u8),
    limit_logins: *std.StringHashMap(LimitLogin),
    arena: *std.heap.ArenaAllocator,
    config: Config,
    pool: *pg.Pool,
    data: LoginDTO,
) !Success(Pair) {
    try checkLimit(limit_logins, data.username);
    loginInternal(arena.allocator(), pool, data) catch |err| switch (err) {
        Error.WrongPassword => {
            try limitLogin(limit_logins, data.username);
            return err;
        },
        else => return err,
    };
    // reset limit times
    try limit_logins.put(data.username, .{ .times = 0, .at = 0 });
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

fn limitLogin(table: *std.StringHashMap(LimitLogin), username: []const u8) !void {
    const getOrPut = try table.getOrPut(username);
    const times = getOrPut.value_ptr.times;

    if (!getOrPut.found_existing) {
        // dont need to write `at` at the first, second time
        getOrPut.value_ptr.* = .{ .times = 0, .at = 0 };
    } else {
        const value = times + 1;
        if (value == 3) {
            getOrPut.value_ptr.* = .{
                .times = 2,
                .at = std.time.timestamp() + 60 * 5, // 5 mins
            };
        } else if (value < 3) {
            getOrPut.value_ptr.* = .{ .times = value, .at = 0 };
        } else {
            return Error.LimitLogin;
        }
    }
}

fn checkLimit(table: *std.StringHashMap(LimitLogin), username: []const u8) !void {
    const get = table.get(username) orelse return;

    if (get.times == 2 and std.time.timestamp() - get.at < 0)
        return Error.LimitLogin;

    if (get.times == 2 and
        get.at != 0 and
        std.time.timestamp() - get.at > 0)
        try table.put(username, .{ .times = 0, .at = 0 });
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
