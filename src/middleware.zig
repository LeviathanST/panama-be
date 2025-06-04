const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const GeneralError = @import("App.zig").GeneralError;
const User = @import("model").User;

// TODO: Using role for authentication
pub const Auth = struct {
    pub const Error = error{Unauthorized} || User.FindError;

    pub const Data = struct {
        account_id: u64,
    };

    pub fn @"fn"(ctx: *tk.Context) anyerror!Data {
        const pool = try ctx.injector.get(*pg.Pool);
        // TODO: change to Bearer token
        const account_id = ctx.req.header("authorization") orelse return Error.Unauthorized;
        if (!(try User.existedById(pool, 1))) return Error.UserNotFound;
        return .{
            .account_id = try std.fmt.parseInt(
                u64,
                account_id,
                10,
            ),
        };
    }
};
