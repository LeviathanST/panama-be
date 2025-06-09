const std = @import("std");
const s3 = @import("s3");
const Config = @import("../Config.zig");

pub fn testGetObjects(alloc: std.mem.Allocator, config: Config) !void {
    try getObjects(alloc, config.s3);
}

pub fn getObjects(alloc: std.mem.Allocator, config: Config.S3Config) !void {
    var client = try s3.S3Client.init(alloc, .{
        .access_key_id = config.access_key_id,
        .secret_access_key = config.secret_access_key,
        .endpoint = config.endpoint_url,
        .region = "auto",
    });
    defer client.deinit();

    const objects = try client.listObjects(config.bucket, .{});
    std.log.info("Object count {d}", .{objects.len});
}
