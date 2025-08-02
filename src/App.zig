const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");

const util = @import("util.zig");
const model = @import("model.zig");
const mw = @import("middleware.zig");
const api = @import("api.zig");
const @"error" = @import("error.zig");

const Config = @import("Config.zig");

const Self = @This();

server: tk.Server,
server_opts: tk.ServerOptions,
arena: std.heap.ArenaAllocator,
routes: []const tk.Route = &.{
    .group("", &.{
        mw.cors(),
        .group("/api", &.{
            .router(api.UnProtected),
            .provide(
                mw.Auth.@"fn",
                &.{
                    .router(api.Protected),
                },
            ),
        }),
    }),
    .get("/openapi.json", tk.swagger.json(.{ .info = .{ .title = "Panama API", .version = "0.0.1" } })),
    .get("/swagger-ui", tk.swagger.ui(.{ .url = "openapi.json" })),
},
config: Config,
token_fingerprints: std.StringHashMap([]const u8),

pub fn configure(bundle: *tk.Bundle) void {
    bundle.add(pg.Pool, .factory(initPool));
    bundle.addOverride(tk.ServerOptions, .factory(initServerOpts));

    bundle.addDeinitHook(cleanPool);
    bundle.addInitHook(notiServer);
    bundle.addInitHook(reassignConnPool);
}

fn cleanPool(pool: *pg.Pool) void {
    pool.deinit();
}

fn notiServer(config: Config) void {
    std.log.info("Server running on {d}", .{config.app.port});
}

pub fn initArena() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(std.heap.page_allocator);
}
pub fn iniTokenFingerprints(arena: std.heap.ArenaAllocator) std.StringHashMap([]const u8) {
    return std.StringHashMap([]const u8).init(arena.allocator());
}

pub fn initServerOpts(config: Config) !tk.ServerOptions {
    return .{
        .listen = .{
            .hostname = "0.0.0.0",
            .port = config.app.port,
        },
        .request = .{
            .lazy_read_size = 1024 * 1024 * 2, // 2mb
            .max_body_size = 1_000_000_000, // 1gb
            .max_multiform_count = 10,
        },
    };
}

pub fn initPool(ct: *tk.Container, config: Config) !pg.Pool {
    const pool = try pg.Pool.init(ct.allocator, .{
        .auth = .{
            .username = config.db.username,
            .password = config.db.password,
            .database = config.db.database,
        },
        .connect = .{
            .host = config.db.host,
            .port = config.db.port,
        },
    });
    errdefer pool.deinit();
    return pool.*;
}

fn reassignConnPool(pool: *pg.Pool) void {
    // tokamak use passed-by-value
    // to initialize all fields in App
    // if using initXxx().
    // Conns in pool point to address its owner,
    // so we need reassgin it here.
    for (pool._conns) |conn| {
        conn._pool = pool;
    }
}
pub fn deinit(self: *Self) void {
    self.token_fingerprints.deinit();
    self.arena.deinit();
}
