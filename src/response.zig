const tk = @import("tokamak");
pub fn Success(comptime T: type) type {
    return struct {
        const Self = @This();

        status: u16 = 200,
        message: []const u8,
        data: T,
    };
}
pub fn Error(comptime T: type) type {
    return struct {
        const Self = @This();

        status: u16,
        message: []const u8,
        @"error": T,

        pub fn with(self: Self) Self {
            return self;
        }
        pub fn sendResponse(self: Self, ctx: *tk.Context) !void {
            ctx.res.status = self.status;
            try ctx.res.json(self, .{ .emit_null_optional_fields = false });
        }
    };
}
