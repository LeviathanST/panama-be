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
    /// TODO: https://github.com/ziglang/zig/issues/22247
    _iat: []const u8,
    _exp: ?[]const u8 = null,

    /// The caller should `free()` memory the return value
    /// after finish.
    ///
    /// NOTE: this function is only temporary until
    /// the issue (noted in Claims) is fixed by Zig.
    pub fn int64ToSlice(alloc: std.mem.Allocator, number: i64) ![]const u8 {
        return std.fmt.allocPrint(alloc, "{d}", .{number});
    }

    pub fn exp(self: Claims) !i64 {
        std.debug.assert(self._exp != null); // .exp is required in the AT
        return std.fmt.parseInt(i64, self._exp.?, 10);
    }
    pub fn iat(self: Claims) !i64 {
        std.debug.assert(self._iat != null); // .iat is required in the AT
        return std.fmt.parseInt(i64, self._iat.?, 10);
    }
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

    const iat = try Claims.int64ToSlice(alloc, std.time.timestamp());
    defer alloc.free(iat);
    const exp = try Claims.int64ToSlice(alloc, std.time.timestamp() + 24 * 60 * 60); // = 1 day
    defer alloc.free(exp);

    const a_claims: Claims = .{
        .username = username,
        .fingerprint = fp,
        ._iat = iat,
        ._exp = exp,
    };
    const r_claims: Claims = .{
        .username = username,
        .fingerprint = fp,
        ._iat = iat,
    };

    std.log.debug("Generate token for user {s}!", .{username});
    std.log.debug("Fingerprint {s}", .{fp});
    try fingerprints_map.put(try alloc.dupe(u8, username), fp);
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
    std.log.debug("Number of fg {d}", .{fingerprints_map.count()});
    var iter = fingerprints_map.iterator();
    while (iter.next()) |entry| {
        std.log.debug("{s} - {s}", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
    const s = jwt.SigningMethodHS256.init(alloc);
    const token = try s.parse(t, secret);
    const parsed = try isValid(alloc, token, valid_type);
    std.log.debug("User `{s}` verify token: {s}", .{ parsed.username, t });
    const fingerprint = fingerprints_map.get(parsed.username) orelse return Error.InvalidToken;
    std.log.debug("Fingerprint from token: {s}", .{parsed.fingerprint});
    if (!std.mem.eql(u8, fingerprint, parsed.fingerprint)) return Error.InvalidToken;
    return parsed;
}

pub fn isValid(alloc: std.mem.Allocator, token: jwt.Token, valid_type: ValidType) !Claims {
    var validator = try jwt.Validator.init(token);
    defer validator.deinit();
    const parsed = try std.json.parseFromValueLeaky(
        Claims,
        alloc,
        validator.claims.value,
        .{ .ignore_unknown_fields = true },
    );
    if (valid_type == .a) {
        // I need to use "Claims.exp()" to convert exp slice
        // into i64.
        // validator.isExpired
        const now = std.time.timestamp();
        if (!(now - validator.leeway < try parsed.exp())) {
            return Error.ExpiredToken;
        }
    }
    return parsed;
}
