const std = @import("std");
const tk = @import("tokamak");
const mw = @import("middleware.zig");
const model = @import("model");
const response = @import("response");
const api = @import("api");
const util = @import("util.zig");

pub const GeneralError = error{ ParamEmpty, InvalidHeader };
const AuthError = mw.Auth.Error;
const UserError = model.User;
const ImageError = model.Image;
const VideoError = model.Video;
const ProjectError = model.Project;
const LoginError = api.LoginError;
const TokenError = util.TokenError;

const ErrorMapping = struct {
    err: anyerror,
    status: u16,
    message: []const u8,

    pub fn bad_request(err: anyerror, message: []const u8) ErrorMapping {
        return .{
            .err = err,
            .status = 400,
            .message = message,
        };
    }

    pub fn unauthorized(err: anyerror, message: []const u8) ErrorMapping {
        return .{
            .err = err,
            .status = 401,
            .message = message,
        };
    }
};

const error_mappings = [_]ErrorMapping{
    .bad_request(GeneralError.ParamEmpty, "Request params empty!"),
    .bad_request(GeneralError.InvalidHeader, "Invalid header!"),

    .unauthorized(AuthError.Unauthorized, "You not have permissions!"),

    .bad_request(UserError.FindError.UserNotFound, "User not found!"),
    .bad_request(UserError.InsertError.UserExisted, "User is existed!"),

    .bad_request(ProjectError.FindError.ProjectNotFound, "Project not found!"),
    .bad_request(api.InsertProjectError.AtLeastOne, "Please insert a project with at least one video or image!"),

    // We need to avoid these errors
    .bad_request(ImageError.InsertError.ImageUrlExisted, "Image URL is existed!"),
    .bad_request(ImageError.InsertError.ImageUrlInProjectExisted, "Image URL is existed in project!"),
    .bad_request(VideoError.InsertError.VideoUrlExisted, "Video URL is existed!"),
    .bad_request(VideoError.InsertError.VideoUrlInProjectExisted, "Video URL is existed in project!"),
    //
    .bad_request(LoginError.WrongPassword, "Wrong password!"),

    .bad_request(TokenError.ExpiredToken, "Expired token!"),
    .bad_request(TokenError.InvalidToken, "Invalid token!"),
    .bad_request(TokenError.JWTSigningMethodNotExists, "Invalid token!"),
    .bad_request(TokenError.JWTTypeInvalid, "Invalid token!"),
    .bad_request(TokenError.JWTVerifyFail, "Invalid token!"),
};

pub fn handler(ctx: *tk.Context, err: anyerror) !void {
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
