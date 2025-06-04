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

    exe.root_module.addImport("response", b.addModule("response", .{
        .root_source_file = b.path("src/response.zig"),
        .imports = &.{
            .{ .name = "tokamak", .module = tokamak },
        },
    }));
    exe.root_module.addImport("model", b.addModule("model", .{
        .root_source_file = b.path("src/model.zig"),
        .imports = &.{
            .{ .name = "tokamak", .module = tokamak },
            .{ .name = "pg", .module = pg },
        },
    }));
    exe.root_module.addImport("tokamak", tokamak);
    exe.root_module.addImport("zenv", zenv);
    exe.root_module.addImport("pg", pg);
    run_step.dependOn(&run_exe.step);
}
