const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const model = @import("../../model.zig");
const util = @import("../../util.zig");
const Config = @import("../../Config.zig");
const Success = @import("../../response.zig").Success;
const Project = @import("../../model.zig").Project;

pub const Error = error{AtLeastOne};
const InsertDTO = struct {
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8 = null,
    image_urls: []model.Image.BaseType,
    video: ?model.Video.BaseType,
};

pub fn create(p: *pg.Pool, data: InsertDTO) !Success(?u8) {
    if (data.video == null and data.image_urls.len == 0) return Error.AtLeastOne;
    try Project.insert(
        p,
        data.title,
        data.description,
        data.category,
        data.time,
        data.image_urls,
        data.video,
    );
    return .{
        .message = "Create project successful!",
        .data = null,
    };
}
