const std = @import("std");
const pg = @import("pg");
const tk = @import("tokamak");
const api = @import("../../api.zig");
const model = @import("../../model.zig");
const base_type = @import("../../base_type.zig");

const Project = model.Project;
const Image = model.Image;
const Video = model.Video;

const Success = @import("../../response.zig").Success;
pub fn find(alloc: std.mem.Allocator, pool: *pg.Pool, id: i32) !Success(base_type.ProjectResponse) {
    const project = try Project.find(alloc, pool, id);
    var images = try Image.findManyByProjectId(alloc, pool, id);
    const raw_video = try Video.findByProjectId(alloc, pool, id);
    const video: ?base_type.VideoResponse = blk: {
        if (raw_video) |v| {
            break :blk .{ .url = v.url, .thumbnail = v.thumbnail };
        } else break :blk null;
    };

    return .{
        .message = "Get a project successful",
        .data = .{
            .id = id,
            .title = project.title,
            .description = project.description,
            .category = project.category,
            .time = project.time,
            .images = try images.toOwnedSlice(),
            .video = video,
        },
    };
}
