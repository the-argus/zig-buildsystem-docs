const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "example",
        .target = target,
        .optimize = optimize,
    });

    exe.addCSourceFiles(&.{
        "main.c",
        "src/foo.c",
        "src/bar.c",
    }, &.{
        "-Wall",
    });

    exe.addIncludePath(.{ .path = "include" });

    exe.linkLibC();

    b.installArtifact(exe);
}
