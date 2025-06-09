const std = @import("std");
const pg = @import("pg");
const model = @import("model");
const Success = @import("response").Success;

const UpdateDTO = struct {
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8,
    deleted_image_urls: [][]const u8,
    inserted_image_urls: [][]const u8,
    deleted_video: ?[]const u8, // TODO: using id: i32 instead
    inserted_video: ?model.Video.BaseType,
};

pub fn update(pool: *pg.Pool, id: i32, data: UpdateDTO) !Success(?u8) {
    try model.Project.update(
        pool,
        id,
        data.title,
        data.description,
        data.category,
        data.time,
        data.deleted_image_urls,
        data.inserted_image_urls,
        data.deleted_video,
        data.inserted_video,
    );
    return .{
        .message = "Update a project successful!",
        .data = null,
    };
}
