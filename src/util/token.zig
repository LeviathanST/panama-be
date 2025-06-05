//! # Features
//! - Only 1 devices can be verified at the same time.
const std = @import("std");
const jwt = @import("zig-jwt");
const uuid = @import("uuid");

pub const Error = error{ InvalidToken, ExpiredToken } || jwt.Error;
pub const Pair = struct {
    at: []const u8,
    rt: []const u8,
};
pub const Claims = struct {
    username: []const u8,
    fingerprint: []const u8,
    iat: i64,
    exp: ?i64 = null,
};
const ValidType = enum { r, a };

/// Pair token is revoked each times generates one
pub fn generate(
    alloc: std.mem.Allocator,
    fingerprints_map: *std.StringHashMap([]const u8),
    at_secret: []const u8,
    rt_secret: []const u8,
    username: []const u8,
) !Pair {
    const id = uuid.v4.new();
    const urn = uuid.urn.serialize(id);
    const fp = try alloc.dupe(u8, &urn);

    const a_claims: Claims = .{
        .username = username,
        .fingerprint = fp,
        .iat = std.time.timestamp(),
        .exp = std.time.timestamp() + 24 * 60 * 60, // = 1 day
    };
    const r_claims: Claims = .{
        .username = username,
        .fingerprint = fp,
        .iat = std.time.timestamp(),
    };

    try fingerprints_map.put(username, fp);
    const s = jwt.SigningMethodHS256.init(alloc);
    const at = try s.sign(a_claims, at_secret);
    const rt = try s.sign(r_claims, rt_secret);
    return .{
        .at = at,
        .rt = rt,
    };
}

pub fn refresh(
    alloc: std.mem.Allocator,
    fingerprints_map: *std.StringHashMap([]const u8),
    rt: []const u8,
    at_secret: []const u8,
    rt_secret: []const u8,
) !Pair {
    const parsed = try verify(alloc, fingerprints_map.*, rt_secret, rt, .r);
    return try generate(alloc, fingerprints_map, at_secret, rt_secret, parsed.username);
}

pub fn verify(
    alloc: std.mem.Allocator,
    fingerprints_map: std.StringHashMap([]const u8),
    secret: []const u8,
    t: []const u8,
    valid_type: ValidType,
) !Claims {
    const s = jwt.SigningMethodHS256.init(alloc);
    const token = try s.parse(t, secret);
    const parsed = try isValid(alloc, token, valid_type);
    std.log.info("username {s}", .{parsed.username});
    const fingerprint = fingerprints_map.get(parsed.username) orelse return Error.InvalidToken;
    std.log.info("finger {s}", .{fingerprint});
    if (!std.mem.eql(u8, fingerprint, parsed.fingerprint)) return Error.InvalidToken;
    return parsed;
}

pub fn isValid(alloc: std.mem.Allocator, token: jwt.Token, valid_type: ValidType) !Claims {
    var validator = try jwt.Validator.init(token);
    defer validator.deinit();
    if (valid_type == .a) {
        if (validator.isExpired(std.time.timestamp())) return Error.ExpiredToken;
    }
    const parsed = try std.json.parseFromValueLeaky(
        Claims,
        alloc,
        validator.claims.value,
        .{ .ignore_unknown_fields = true },
    );
    return parsed;
}
