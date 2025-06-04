const tk = @import("tokamak");
pub fn sendErr(ctx: *tk.Context, status: u16, message: []const u8, data: anytype) !void {
    try ctx.send(.{
        .status = status,
        .message = message,
        .@"error" = data,
    });
}
/// The response always have `status code = 200`
pub fn sendSuccess(ctx: *tk.Context, message: []const u8, data: anytype) !void {
    try ctx.send(.{
        .status = 200,
        .message = message,
        .data = data,
    });
}
