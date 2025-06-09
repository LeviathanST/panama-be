const tk = @import("tokamak");
const pg = @import("pg");
const model = @import("model");
const Success = @import("response").Success;
const Project = @import("model").Project;

pub const Error = error{AtLeastOne};
const InsertDTO = struct {
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8 = null,
    images: []model.Image.BaseType,
    video: ?model.Video.BaseType,
};

pub fn create(p: *pg.Pool, data: InsertDTO) !Success(?u8) {
    if (data.video == null and data.images.len == 0) return Error.AtLeastOne;
    try Project.insert(
        p,
        data.title,
        data.description,
        data.category,
        data.time,
        data.images,
        data.video,
    );
    return .{
        .message = "Create project successful!",
        .data = null,
    };
}
