const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const util = @import("util.zig");
const Config = @import("Config.zig");
const GeneralError = @import("App.zig").GeneralError;
const User = @import("model").User;

// TODO: Using role for authentication
pub const Auth = struct {
    pub const Error = error{Unauthorized} || User.FindError;

    pub const Data = struct {
        account_id: i32,
    };

    pub fn @"fn"(ctx: *tk.Context) anyerror!Data {
        const p = try ctx.injector.get(*pg.Pool);
        const map = try ctx.injector.get(*std.StringHashMap([]const u8));
        const config = try ctx.injector.get(*Config);

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
