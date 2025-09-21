const std = @import("std");
const pg = @import("pg");

const Category = @This();
pub const InsertError = error{EmptyString};

type: []const u8,
name: []const u8,
normal_img_url: []const u8,
hover_img_url: []const u8,

pub fn getAll(
    pool: *pg.Pool,
    alloc: std.mem.Allocator,
) !std.array_list.Aligned(@This(), null) {
    var conn = try pool.acquire();
    defer conn.release();

    var result = try conn.queryOpts(
        "SELECT * FROM category_info",
        .{},
        .{ .allocator = alloc },
    );
    defer result.deinit();

    var list = std.array_list.Aligned(@This(), null).empty;
    errdefer list.deinit(alloc);

    while (try result.next()) |r| {
        try list.append(alloc, try r.to(Category, .{ .allocator = alloc }));
    }
    return list;
}

/// All the values will be trimmed from
/// the begining and ending before checking
pub fn update(
    pool: *pg.Pool,
    category_type: []const u8,
    new_normal_img_url: ?[]const u8,
    new_hover_img_url: ?[]const u8,
    new_name: ?[]const u8,
) !void {
    var conn = try pool.acquire();
    defer conn.release();

    if (new_normal_img_url) |v| {
        if (std.mem.eql(
            u8,
            std.mem.trim(u8, v, " "),
            "",
        )) return InsertError.EmptyString;
        _ = conn.exec(
            \\\ UPDATE category_img
            \\\ SET    normal_img_url = $1  
            \\\ WHERE  type = $2
        , .{ v, category_type }) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }

    if (new_hover_img_url) |v| {
        if (std.mem.eql(
            u8,
            std.mem.trim(u8, v, " "),
            "",
        )) return InsertError.EmptyString;
        _ = conn.exec(
            \\\ UPDATE category_img
            \\\ SET    hover_img_url = $1  
            \\\ WHERE  type = $2
        , .{ v, category_type }) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }

    if (new_name) |v| {
        if (std.mem.eql(
            u8,
            std.mem.trim(u8, v, " "),
            "",
        )) return InsertError.EmptyString;
        _ = conn.exec(
            \\\ UPDATE category_img
            \\\ SET    name = $1  
            \\\ WHERE  type = $2
        , .{ v, category_type }) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }
}
