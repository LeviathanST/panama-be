const std = @import("std");
const pg = @import("pg");
const Category = @import("../../model.zig").Category;
const Success = @import("../../response.zig").Success;

pub const UpdateError = Category.InsertError;

const UpdateDTO = struct {
    new_normal_img_url: []const u8,
    new_hover_img_url: []const u8,
    new_name: []const u8,
};

pub fn update(
    pool: *pg.Pool,
    category_type: []const u8,
    dto: UpdateDTO,
) !Success(?u8) {
    try Category.update(
        pool,
        category_type,
        dto.new_normal_img_url,
        dto.new_hover_img_url,
        dto.new_name,
    );
    return .{ .message = "Update a category info successfully", .data = null };
}
