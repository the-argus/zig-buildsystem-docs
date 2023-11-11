const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libfoo = b.addSharedLibrary(.{
        .name = "foo",
        .target = target,
        .optimize = optimize,
    });

    libfoo.addCSourceFiles(&.{
        "src/foo.c",
        "src/bar.c",
    }, &.{
        "-Wall",
    });

    libfoo.addIncludePath(.{ .path = "include" });
    libfoo.addIncludePath(.{ .path = "src" });

    libfoo.linkLibC();

    libfoo.installHeadersDirectory("include", "");

    b.installArtifact(libfoo);
}
