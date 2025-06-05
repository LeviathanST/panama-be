const login = @import("api/auth/login.zig");
const register = @import("api/auth/register.zig");
const refresh = @import("api/auth/refresh.zig");

pub const LoginError = login.Error;

pub const UnProtected = struct {
    pub const @"GET /ping" = @import("api/ping.zig").ping;
    pub const @"POST /login" = login.login;
    pub const @"POST /register" = register.register;
    pub const @"POST /refresh" = refresh.refresh;
};

pub const Protected = struct {
    pub const @"GET /verify" = @import("api/auth/verify.zig").verify;
};
