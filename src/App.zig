const tk = @import("tokamak");
const response = @import("response");
const zenv = @import("zenv");
const pg = @import("pg");

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

pub const GeneralError = error{ParamEmpty};

pub fn errorHandler(ctx: *tk.Context, err: anyerror) !void {
    switch (err) {
        GeneralError.ParamEmpty => try response.sendErr(ctx, 400, "Request params is empty!", null),
        mw.Auth.Error.Unauthorized => try response.sendErr(ctx, 401, "You not have permissions!", null),
        model.User.FindError.UserNotFound => try response.sendErr(ctx, 400, "User not found!", null),
        else => try response.sendErr(ctx, 500, "Server Internal Error", null),
    }
}
