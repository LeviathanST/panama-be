const std = @import("std");
const tk = @import("tokamak");
const response = @import("response");
const pg = @import("pg");

const util = @import("util.zig");
const model = @import("model");
const mw = @import("middleware.zig");
const api = @import("api.zig");

const Config = @import("Config.zig");

const Self = @This();

server: tk.Server,
pool: pg.Pool,
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

pub fn initArena() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(std.heap.page_allocator);
}
pub fn iniTokenFingerprints(arena: std.heap.ArenaAllocator) std.StringHashMap([]const u8) {
    return std.StringHashMap([]const u8).init(arena.allocator());
}

pub fn initServer(ct: *tk.Container, routes: []const tk.Route, config: Config) !tk.Server {
    return try tk.app.Base.initServer(ct, routes, .{
        .listen = .{
            .hostname = "0.0.0.0",
            .port = config.app.port,
        },
        .request = .{
            .lazy_read_size = 1024 * 1024 * 2, // 2mb
            .max_body_size = 1_000_000_000, // 1gb
            .max_multiform_count = 10,
        },
    });
}
pub fn initPool(ct: *tk.Container, config: *Config) !pg.Pool {
    return (try pg.Pool.init(ct.allocator, .{
        .auth = .{
            .username = config.db.username,
            .password = config.db.password,
            .database = config.db.database,
        },
        .connect = .{
            .host = config.db.host,
            .port = config.db.port,
        },
    })).*;
}
pub fn afterBundleInit(pool: *pg.Pool) void {
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

pub const GeneralError = error{ ParamEmpty, InvalidHeader };
const AuthError = mw.Auth.Error;
const UserError = model.User;
const ImageError = model.Image;
const VideoError = model.Video;
const ProjectError = model.Project;
const LoginError = api.LoginError;
const TokenError = util.TokenError;

const ErrorMapping = struct {
    err: anyerror,
    status: u16,
    message: []const u8,
};
const error_mappings = [_]ErrorMapping{
    .{ .err = GeneralError.ParamEmpty, .status = 400, .message = "Request params empty!" },
    .{ .err = GeneralError.InvalidHeader, .status = 400, .message = "Invalid header!" },

    .{ .err = AuthError.Unauthorized, .status = 401, .message = "You not have permissions!" },

    .{ .err = UserError.FindError.UserNotFound, .status = 400, .message = "User not found!" },
    .{ .err = UserError.InsertError.UserExisted, .status = 400, .message = "User is existed!" },

    .{ .err = ProjectError.FindError.ProjectNotFound, .status = 400, .message = "Project not found!" },
    .{ .err = api.InsertProjectError.AtLeastOne, .status = 400, .message = "Please insert a project with at least one video or image!" },
    // We need to avoid these errors
    .{ .err = ImageError.InsertError.ImageUrlExisted, .status = 400, .message = "Image URL is existed!" },
    .{ .err = ImageError.InsertError.ImageUrlInProjectExisted, .status = 400, .message = "Image URL is existed in project!" },
    .{ .err = VideoError.InsertError.VideoUrlExisted, .status = 400, .message = "Video URL is existed!" },
    .{ .err = VideoError.InsertError.VideoUrlInProjectExisted, .status = 400, .message = "Video URL is existed in project!" },
    //
    .{ .err = LoginError.WrongPassword, .status = 400, .message = "Wrong password!" },

    .{ .err = TokenError.InvalidToken, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.ExpiredToken, .status = 400, .message = "Expired token!" },
    .{ .err = TokenError.JWTAlgoInvalid, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTSigningMethodNotExists, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTTypeInvalid, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTVerifyFail, .status = 400, .message = "Invalid token!" },
};

pub fn errorHandler(ctx: *tk.Context, err: anyerror) !void {
    const ResponseError = response.Error;
    var res = ResponseError(void).with(.{ .status = 500, .message = "Internal Server Error", .@"error" = {} });

    inline for (error_mappings) |mapping| {
        if (err == mapping.err) {
            res.status = mapping.status;
            res.message = mapping.message;
            break;
        }
    } else {
        std.log.err("Unexpected error: {}, name: {s}", .{ err, @errorName(err) });
    }

    try ctx.send(res);
}
