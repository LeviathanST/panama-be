const std = @import("std");
const pg = @import("pg");
const tk = @import("tokamak");
const api = @import("../../api.zig");
const model = @import("model");

const Project = model.Project;
const Image = model.Image;
const Video = model.Video;

const Success = @import("response").Success;
const VideoResponse = struct {
    url: []const u8,
    thumbnail: []const u8,
};
const ProjectResponse = struct {
    id: i32,
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8,
    images_url: [][]const u8,
    video: ?VideoResponse,
};

pub fn find(alloc: std.mem.Allocator, pool: *pg.Pool, id: i32) !Success(ProjectResponse) {
    const project = try Project.find(alloc, pool, id);
    var images = try Image.findManyByProjectId(alloc, pool, id);
    const raw_video = try Video.findByProjectId(alloc, pool, id);
    const video: ?VideoResponse = blk: {
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
            .images_url = try images.toOwnedSlice(),
            .video = video,
        },
    };
}
