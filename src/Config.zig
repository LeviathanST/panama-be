const std = @import("std");
const zenv = @import("zenv");
const tk = @import("tokamak");
const pg = @import("pg");

const Config = @This();

app: AppConfig,
db: DBConfig,
_reader: zenv.Reader,

pub const AppConfig = struct {
    port: u16,
    round_hashing: u6,
    secret: []const u8,
    client_url: []const u8,
};

pub const DBConfig = struct {
    host: []const u8,
    port: u16,
    database: []const u8,
    username: []const u8,
    password: []const u8,
};

pub fn init(allocator: std.mem.Allocator) !Config {
    const reader = try zenv.Reader.init(allocator, .TERM, .{});
    errdefer reader.deinit();

    const app = try reader.readStruct(AppConfig, .{});
    const db = try reader.readStruct(DBConfig, .{ .prefix = "DB_" });

    return .{
        .app = app.*,
        .db = db.*,
        ._reader = reader,
    };
}
pub fn deinit(self: *Config) void {
    self._reader.deinit();
}
