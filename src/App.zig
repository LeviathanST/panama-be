const std = @import("std");
const tk = @import("tokamak");
const response = @import("response");
const zenv = @import("zenv");
const pg = @import("pg");

const util = @import("util.zig");
const model = @import("model");
const mw = @import("middleware.zig");
const api = @import("api.zig");
const Config = @import("Config.zig");

server: tk.Server,
pool: pg.Pool,
routes: []const tk.Route = &.{
    .group("/api", &.{
        .router(api.UnProtected),
        .provide(
            mw.Auth.@"fn",
            &.{
                .router(api.Protected),
            },
        ),
    }),
    .get("/openapi.json", tk.swagger.json(.{ .info = .{ .title = "Panama API", .version = "0.0.1" } })),
    .get("/swagger-ui", tk.swagger.ui(.{ .url = "openapi.json" })),
},
config: Config,
/// Using to check valid token
token_fingerprints: std.StringHashMap([]const u8),

pub fn initServer(ct: *tk.Container, routes: []const tk.Route, config: Config) !tk.Server {
    return try tk.app.Base.initServer(ct, routes, .{
        .listen = .{
            .hostname = "0.0.0.0",
            .port = config.app.port,
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

const GeneralError = error{ ParamEmpty, InvalidInput };
const AuthError = mw.Auth.Error;
const UserError = model.User;
const LoginError = api.LoginError;
const TokenError = util.TokenError;

const ErrorMapping = struct {
    err: anyerror,
    status: u16,
    message: []const u8,
};
const error_mappings = [_]ErrorMapping{
    .{ .err = GeneralError.ParamEmpty, .status = 400, .message = "Request params empty!" },
    .{ .err = GeneralError.InvalidInput, .status = 400, .message = "Invalid input provided!" },

    .{ .err = AuthError.Unauthorized, .status = 401, .message = "You not have permissions!" },

    .{ .err = UserError.FindError.UserNotFound, .status = 400, .message = "User not found!" },
    .{ .err = UserError.InsertError.UserExisted, .status = 400, .message = "User is existed" },

    .{ .err = LoginError.WrongPassword, .status = 400, .message = "Wrong password" },

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
