//!
//! **All functions** ending in `withProject` are used to interact with the relationship between
//! project and video, they get `conn` as in transction and not to use `commit()`
//! or `release()` after finishing. The caller should call `rollback()` when error occurs.
//!
const std = @import("std");
const FormData = @import("tokamak").FormData;
const pg = @import("pg");

pub const InsertError = error{ VideoUrlExisted, VideoUrlInProjectExisted };
pub const BaseType = struct {
    video_url: []const u8,
};
const Project = @import("Project.zig");
const Self = @This();

id: i32,
url: []const u8,

pub fn insertWithProject(conn: *pg.Conn, project_id: i32, url: []const u8) !void {
    var video_id_row = conn.row(
        \\ INSERT INTO video (url)
        \\ VALUES ($1)
        \\ RETURNING id
    , .{url}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) return InsertError.VideoUrlExisted;
        }
        return err;
    };
    const video_id = video_id_row.?.getCol(i32, "id");
    try video_id_row.?.deinit();

    var project_id_row = try conn.row(
        \\ SELECT 1 FROM project
        \\ WHERE id = $1
    , .{project_id}) orelse return Project.FindError.ProjectNotFound;
    try project_id_row.deinit();

    _ = conn.exec(
        \\ INSERT INTO video_project(project_id, video_id)
        \\ VALUES ($1, $2) 
    , .{ project_id, video_id }) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) return InsertError.VideoUrlInProjectExisted;
        }
        return err;
    };
}

pub fn deleteWithProject(conn: *pg.Conn, project_id: i32) !void {
    var video_id_row = conn.row(
        \\ SELECT video_id FROM video_project
        \\ WHERE project_id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return; // ignore video id is null
    const video_id = video_id_row.getCol(i32, "video_id");
    try video_id_row.deinit();
    _ = conn.exec(
        \\ DELETE FROM video
        \\ WHERE id = $1
    , .{video_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
}

pub fn findByProjectId(alloc: std.mem.Allocator, pool: *pg.Pool, project_id: i32) !?Self {
    const conn = try pool.acquire();
    defer conn.release();

    var row = conn.row(
        \\ SELECT * FROM video v
        \\ LEFT JOIN video_project vp ON v.id = vp.video_id
        \\ WHERE vp.project_id = $1
    , .{project_id}) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return null;
    defer row.deinit() catch @panic("Error when select video");

    const self = try row.to(Self, .{ .map = .name, .allocator = alloc });
    return self;
}

pub fn updateWithProject(
    conn: *pg.Conn,
    project_id: i32,
    deleted_video_url: ?[]const u8,
    inserted_video: ?BaseType,
) !void {
    if (deleted_video_url) |url| {
        _ = conn.exec(
            \\ DELETE FROM video
            \\ WHERE EXISTS
            \\ (
            \\   SELECT 1 FROM video_project vp
            \\   LEFT JOIN video v ON v.id = vp.video_id
            \\   WHERE v.url = $1 AND vp.project_id = $2
            \\ )
        , .{ url, project_id }) catch |err| {
            if (conn.err) |pg_err| {
                std.log.err("{s}", .{pg_err.message});
            }
            return err;
        };
    }
    if (inserted_video) |video| {
        try insertWithProject(conn, project_id, video.video_url);
    }
}
