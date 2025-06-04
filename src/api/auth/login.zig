const tk = @import("tokamak");
const response = @import("response");

pub fn login(ctx: *tk.Context) !void {
    try response.sendSuccess(ctx, "You are logging", null);
}
