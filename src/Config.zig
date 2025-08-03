const std = @import("std");
const zenv = @import("zenv");

const Config = @This();

app: AppConfig,
db: DBConfig,
_reader: zenv.Term,

pub const AppConfig = struct {
    port: u16,
    round_hashing: u6,
    at_secret: []const u8,
    rt_secret: []const u8,
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
    var term = try zenv.Term.init(allocator);
    errdefer term.deinit();
    const reader = term.reader();
    const app = try reader.readStruct(AppConfig, .{});
    const db = try reader.readStruct(DBConfig, .{ .prefix = "DB_" });

    return .{
        .app = app,
        .db = db,
        ._reader = term,
    };
}
pub fn deinit(self: *Config) void {
    self._reader.deinit();
}
