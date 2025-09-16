//!
//! **All functions** ending in `withProject` are used to interact with the relationship between
//! project and images, they get `conn` as in transction and not to use `commit()`
//! or `release()` after finishing. The caller should call `rollback()` when error occurs.
//!
const std = @import("std");
const tk = @import("tokamak");
const pg = @import("pg");
const Project = @import("Project.zig");

pub const FindError = Project.FindError;
pub const InsertError = error{ ImageUrlExisted, ImageUrlInProjectExisted };
pub const BaseType = []const u8;
const Self = @This();

id: i32,
url: []const u8,

/// Insert an image then inserting relationship between `project_id` and the image.
pub fn insertWithProject(conn: *pg.Conn, project_id: i32, url: []const u8) !void {
    var image_id_row = conn.row(
        \\ INSERT INTO image(url)
        \\ VALUES ($1)
        \\ RETURNING id
    , .{url}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) return InsertError.ImageUrlExisted;
        }
        return err;
    };

    const image_id = image_id_row.?.getCol(i32, "id");
    try image_id_row.?.deinit();

    var project_id_row = try conn.row(
        \\ SELECT 1 FROM project
        \\ WHERE id = $1
    , .{project_id}) orelse return FindError.ProjectNotFound;
    try project_id_row.deinit();

    _ = conn.exec(
        \\ INSERT INTO image_project(project_id, image_id)
        \\ VALUES ($1, $2) 
    , .{ project_id, image_id }) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) return InsertError.ImageUrlInProjectExisted;
        }
        return err;
    };
}

pub fn deleteWithProject(conn: *pg.Conn, alloc: std.mem.Allocator, project_id: i32) !void {
    const rs = conn.query(
        \\ SELECT image_id FROM image_project
        \\ WHERE project_id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    defer rs.deinit();

    var image_ids = std.array_list.Aligned(i32, null).empty;
    defer image_ids.deinit(alloc);
    while (try rs.next()) |row| {
        const image_id = row.getCol(i32, "image_id");
        try image_ids.append(alloc, image_id);
    }

    for (image_ids.items[0..]) |id| {
        _ = conn.exec(
            \\ DELETE FROM image 
            \\ WHERE id = $1
        , .{id}) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }
}
pub fn findManyByProjectId(
    alloc: std.mem.Allocator,
    pool: *pg.Pool,
    project_id: i32,
) !std.array_list.Aligned([]const u8, null) {
    const conn = try pool.acquire();
    defer conn.release();

    var rs = conn.query(
        \\ SELECT i.url FROM image i
        \\ LEFT JOIN image_project ip ON i.id = ip.image_id
        \\ WHERE ip.project_id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    defer rs.deinit();

    var list = std.array_list.Aligned([]const u8, null).empty;
    // FIX: free items
    errdefer list.deinit(alloc);

    while (try rs.next()) |row| {
        const url = row.getCol([]const u8, "url");
        try list.append(alloc, try alloc.dupe(u8, url));
    }
    return list;
}
/// Replace or delete a image for a project.
/// Delete first, then insert.
pub fn updateWithProject(
    conn: *pg.Conn,
    project_id: i32,
    deleted_image_urls: [][]const u8,
    inserted_image_urls: [][]const u8,
) !void {
    for (deleted_image_urls) |url| {
        _ = conn.exec(
            \\ DELETE FROM image
            \\ WHERE id = 
            \\ (
            \\   SELECT ip.image_id FROM image_project ip
            \\   LEFT JOIN image i ON i.id = ip.image_id
            \\   WHERE i.url = $1 AND ip.project_id = $2
            \\ )
        , .{ url, project_id }) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }
    for (inserted_image_urls) |url| {
        try insertWithProject(conn, project_id, url);
    }
}
