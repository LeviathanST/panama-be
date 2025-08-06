pub const VideoResponse = struct {
    url: []const u8,
};

pub const ProjectResponse = struct {
    id: i32,
    title: []const u8,
    thumbnail: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8,
    images: [][]const u8,
    video: ?VideoResponse,
};
