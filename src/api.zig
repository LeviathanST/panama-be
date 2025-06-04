pub const UnProtected = struct {
    pub const @"GET /login" = @import("api/auth/login.zig").login;
    pub const @"GET /ping" = @import("api/ping.zig").ping;
};

pub const Protected = struct {
    pub const @"GET /verify" = @import("api/auth/verify.zig").verify;
};
