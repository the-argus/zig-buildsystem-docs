const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const program = b.addExecutable(.{
        .name = "program",
        .target = target,
        .optimize = optimize,
    });

    program.addCSourceFiles(&.{
        "main.c",
    }, &.{
        "-Wall",
    });

    program.linkLibC();

    // link raylib
    {
        const raylib_dep = b.dependency("raylib",
        // this second argument is a struct with all the CLI arguments we want
        // to propagate to the dependency.
        .{
            .target = target,
            .optimize = optimize,
        });

        // inside of the raylib build.zig, they did b.addStaticLibrary(.{ .name = "raylib" })
        // so we need to use "raylib" as the name here in order to get it. It's possible
        // that a dependency will have multiple artifacts!
        const raylib_lib = raylib_dep.artifact("raylib");

        program.linkLibrary(raylib_lib);
    }

    b.installArtifact(program);
}
