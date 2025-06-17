const std = @import("std");
const pg = @import("pg");

const base_type = @import("base_type");
const Image = @import("Image.zig");
const Video = @import("Video.zig");

const Self = @This();

pub const FindError = error{ProjectNotFound};

id: i32,
title: []const u8,
description: []const u8,
category: []const u8,
time: ?[]const u8,

pub fn getAll(pool: *pg.Pool, alloc: std.mem.Allocator) !std.ArrayList(base_type.ProjectResponse) {
    const conn = try pool.acquire();
    defer conn.release();

    const rs = conn.queryOpts(
        \\ SELECT * FROM project 
    , .{}, .{ .allocator = alloc }) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    defer rs.deinit();

    var list = std.ArrayList(base_type.ProjectResponse).init(alloc);
    errdefer list.deinit();

    while (try rs.next()) |row| {
        const inst = try row.to(Self, .{ .allocator = alloc, .map = .name });
        var images = try Image.findManyByProjectId(alloc, pool, inst.id);
        const video: ?base_type.VideoResponse = v: {
            if (try Video.findByProjectId(alloc, pool, inst.id)) |vi| {
                break :v .{
                    .url = vi.url,
                    .thumbnail = vi.thumbnail,
                };
            } else break :v null;
        };
        try list.append(.{
            .id = inst.id,
            .title = inst.title,
            .description = inst.description,
            .category = inst.category,
            .time = inst.time,
            .images = try images.toOwnedSlice(),
            .video = video,
        });
    }
    return list;
}
pub fn insert(
    p: *pg.Pool,
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8,
    images: [][]const u8,
    video: ?Video.BaseType,
) !void {
    const conn = try p.acquire();
    defer conn.release();
    errdefer conn.rollback() catch @panic("Error when rollback insert project");

    try conn.begin();
    var row = blk: {
        if (time) |t| {
            break :blk conn.row(
                \\ INSERT INTO project (title, description, category, time) 
                \\ VALUES ($1, $2, $3, $4)
                \\ RETURNING id
            , .{ title, description, category, t });
        } else {
            break :blk conn.row(
                \\ INSERT INTO project (title, description, category) 
                \\ VALUES ($1, $2, $3)
                \\ RETURNING id
            , .{ title, description, category });
        }
    } catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    const project_id = row.?.getCol(i32, "id");
    try row.?.deinit();

    // TODO: We can run parallel here
    for (images) |image| {
        try Image.insertWithProject(conn, project_id, image);
    }
    if (video) |v| {
        try Video.insertWithProject(conn, project_id, v.video_url, v.thumbnail_url);
    }

    try conn.commit();
}
pub fn find(alloc: std.mem.Allocator, pool: *pg.Pool, project_id: i32) !Self {
    const conn = try pool.acquire();
    defer conn.release();

    const row = conn.row(
        \\ SELECT * FROM project
        \\ WHERE id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.ProjectNotFound;
    const self = try row.to(Self, .{
        .map = .name,
        .allocator = alloc,
    });
    return self;
}
pub fn delete(pool: *pg.Pool, alloc: std.mem.Allocator, project_id: i32) !void {
    const conn = try pool.acquire();
    defer conn.release();
    errdefer conn.rollback() catch @panic("Error when rollback delete project");

    try conn.begin();
    var check_row = conn.row(
        \\ SELECT 1 FROM project
        \\ WHERE id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.ProjectNotFound;
    try check_row.deinit();

    try Image.deleteWithProject(conn, alloc, project_id);
    try Video.deleteWithProject(conn, project_id);

    _ = conn.exec(
        \\ DELETE FROM project
        \\ WHERE id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    try conn.commit();
}
pub fn update(
    pool: *pg.Pool,
    project_id: i32,
    title: []const u8,
    description: []const u8,
    category: []const u8,
    time: ?[]const u8,
    deleted_image_urls: [][]const u8,
    inserted_image_urls: [][]const u8,
    deleted_video: ?[]const u8, // TODO: using id: i32 instead
    inserted_video: ?Video.BaseType,
) !void {
    const conn = try pool.acquire();
    defer conn.release();
    errdefer conn.rollback() catch @panic("Error when rollback update project");

    try conn.begin();
    try Image.updateWithProject(conn, project_id, deleted_image_urls, inserted_image_urls);
    try Video.updateWithProject(conn, project_id, deleted_video, inserted_video);

    _ = blk: {
        if (time) |_| {
            break :blk conn.exec(
                \\ UPDATE project
                \\ SET (title, description, category, time)
                \\   = ($1, $2, $3, $4)
                \\ WHERE id = $5
            , .{ title, description, category, time, project_id });
        } else {
            break :blk conn.exec(
                \\ UPDATE project
                \\ SET (title, description, category)
                \\   = ($1, $2, $3)
                \\ WHERE id = $4
            , .{ title, description, category, project_id });
        }
    } catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    try conn.commit();
}
