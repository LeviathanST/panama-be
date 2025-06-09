const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "panama_be",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");

    const tokamak = b.dependency("tokamak", .{
        .target = target,
        .optimize = optimize,
    }).module("tokamak");
    const zenv = b.dependency("zenv", .{
        .target = target,
        .optimize = optimize,
    }).module("zenv");
    const pg = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
        .column_names = true,
    }).module("pg");
    const uuid = b.dependency("uuid", .{
        .target = target,
        .optimize = optimize,
    }).module("uuid");
    const jwt = b.dependency("zig_jwt", .{}).module("zig-jwt");
    const aws = b.dependency("aws", .{}).module("aws");

    const modules = [_][]const u8{ "response", "model" };
    inline for (modules) |m| {
        exe.root_module.addImport(m, b.addModule(m, .{
            .root_source_file = b.path("src/" ++ m ++ ".zig"),
            .imports = &.{
                .{ .name = "tokamak", .module = tokamak },
                .{ .name = "pg", .module = pg },
                .{ .name = "zenv", .module = zenv },
                .{ .name = "zig-jwt", .module = jwt },
                .{ .name = "uuid", .module = uuid },
                .{ .name = "aws", .module = aws },
            },
        }));
    }
    exe.root_module.addImport("tokamak", tokamak);
    exe.root_module.addImport("zenv", zenv);
    exe.root_module.addImport("pg", pg);
    exe.root_module.addImport("zig-jwt", jwt);
    exe.root_module.addImport("uuid", uuid);
    exe.root_module.addImport("aws", aws);
    run_step.dependOn(&run_exe.step);
}
