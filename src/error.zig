const std = @import("std");
const tk = @import("tokamak");
const mw = @import("middleware.zig");
const model = @import("model");
const response = @import("response");
const api = @import("api.zig");
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
};
const error_mappings = [_]ErrorMapping{
    .{ .err = GeneralError.ParamEmpty, .status = 400, .message = "Request params empty!" },
    .{ .err = GeneralError.InvalidHeader, .status = 400, .message = "Invalid header!" },

    .{ .err = AuthError.Unauthorized, .status = 401, .message = "You not have permissions!" },

    .{ .err = UserError.FindError.UserNotFound, .status = 400, .message = "User not found!" },
    .{ .err = UserError.InsertError.UserExisted, .status = 400, .message = "User is existed!" },

    .{ .err = ProjectError.FindError.ProjectNotFound, .status = 400, .message = "Project not found!" },
    .{ .err = api.InsertProjectError.AtLeastOne, .status = 400, .message = "Please insert a project with at least one video or image!" },
    // We need to avoid these errors
    .{ .err = ImageError.InsertError.ImageUrlExisted, .status = 400, .message = "Image URL is existed!" },
    .{ .err = ImageError.InsertError.ImageUrlInProjectExisted, .status = 400, .message = "Image URL is existed in project!" },
    .{ .err = VideoError.InsertError.VideoUrlExisted, .status = 400, .message = "Video URL is existed!" },
    .{ .err = VideoError.InsertError.VideoUrlInProjectExisted, .status = 400, .message = "Video URL is existed in project!" },
    //
    .{ .err = LoginError.WrongPassword, .status = 400, .message = "Wrong password!" },

    .{ .err = TokenError.InvalidToken, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.ExpiredToken, .status = 400, .message = "Expired token!" },
    .{ .err = TokenError.JWTAlgoInvalid, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTSigningMethodNotExists, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTTypeInvalid, .status = 400, .message = "Invalid token!" },
    .{ .err = TokenError.JWTVerifyFail, .status = 400, .message = "Invalid token!" },
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
