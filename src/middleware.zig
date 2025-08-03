const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const util = @import("util.zig");
const Config = @import("Config.zig");
const User = @import("model.zig").User;

// TODO: Using role for authentication
pub const Auth = struct {
    pub const Error = error{Unauthorized} || User.FindError;

    pub const Data = struct {
        account_id: i32,
    };

    pub fn @"fn"(ctx: *tk.Context) anyerror!Data {
        const p = try ctx.injector.get(*pg.Pool);
        const map = try ctx.injector.get(*std.StringHashMap([]const u8));
        const config = try ctx.injector.get(Config);

        const header = ctx.req.header("authorization") orelse return Error.Unauthorized;
        var splits = std.mem.splitScalar(u8, header, ' ');
        if (!std.mem.eql(u8, splits.first(), "Bearer")) return Error.Unauthorized;

        const claims = try util.token.verify(
            ctx.req.arena,
            map.*,
            config.app.at_secret,
            splits.next() orelse return Error.Unauthorized,
            .a,
        );
        const account_id = try User.findIdByUsername(p, claims.username);
        return .{
            .account_id = account_id,
        };
    }
};
pub fn cors() tk.Route {
    const H = struct {
        fn handleCors(ctx: *tk.Context) anyerror!void {
            ctx.res.header("access-control-allow-origin", ctx.req.header("origin") orelse "*");

            if (ctx.req.method == .OPTIONS and ctx.req.header("access-control-request-method") != null) {
                ctx.res.header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS");
                ctx.res.header("access-control-allow-headers", "content-type, authorization");
                ctx.res.header("access-control-allow-private-network", "true");
                ctx.res.status = 200;
                return ctx.send(void{});
            }
        }
    };

    return .{
        .handler = H.handleCors,
    };
}
