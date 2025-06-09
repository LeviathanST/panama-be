const std = @import("std");
const zenv = @import("zenv");

const Config = @This();

app: AppConfig,
db: DBConfig,
s3: S3Config,
_reader: zenv.Reader,

pub const S3Config = struct {
    endpoint_url: []const u8,
    bucket: []const u8,
    access_key_id: []const u8,
    secret_access_key: []const u8,
};
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
    const reader = try zenv.Reader.init(allocator, .TERM, .{});
    errdefer reader.deinit();

    const app = try reader.readStruct(AppConfig, .{});
    const db = try reader.readStruct(DBConfig, .{ .prefix = "DB_" });
    const s3 = try reader.readStruct(S3Config, .{ .prefix = "S3_" });

    return .{
        .app = app.*,
        .db = db.*,
        .s3 = s3.*,
        ._reader = reader,
    };
}
pub fn deinit(self: *Config) void {
    self._reader.deinit();
}
