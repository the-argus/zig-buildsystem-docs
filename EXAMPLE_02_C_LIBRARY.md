# Using Zig To Build A Library

This document will get you to the point where you can build an extremely simple
executable with no dependencies besides libc and/or libc++.

## The Project

In the `examples/02_c_library` directory, you can see a project that looks like
this:

- src/
  - foo.c
  - bar.c
  - bar.h
- include/
  - foo.h
- .gitignore
- build.zig

The `include` directory is the "public" headers of the project. It's headers that
`foo.c` and `bar.c` need to compile, and so do any files which are linking our
library.

The `src` directory contains the `.c` files as well as private headers: headers
which we need to compile but reference internal symbols which we do not want to
expose to people linking our library. In this case, `bar.h` is a private header
and it defined symbols which we only want to use in `bar.c` and `foo.c`.

## The Build Script

Our library building script looks like this:

```zig
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

    libfoo.linkLibC();

    libfoo.installHeadersDirectory("include", "");

    b.installArtifact(libfoo);
}
```

First of all, note `addSharedLibrary`. This is very similar to `addExecutable`,
and it has another sibling: `addStaticLibrary`. Swap it out for that if you need
a static artifact. All three of these functions return a `std.Build.Step.Compile`.

The only other difference from our basic executable example is the following line:

```zig
libfoo.installHeadersDirectory("include", "");
```

This is going to make sure that the contents of `include/` in our project will
get installed to `zig-out/include/` (assuming `zig-out` is your install prefix).
That means that anyone linking this library will be able to do `#include <foo.h>`.
If we would prefer that the headers got installed to a subdirectory, say `include/foo/`,
we could put that subdirectory in the second argument (currently the string is empty
because we just wanted to install directly into `include/`). To install in `include/foo/`,
do:

```zig
libfoo.installHeadersDirectory("include", "foo");
```

The definition of `installHeadersDirectory` looks like this:

```zig
pub fn installHeadersDirectory(
    a: *Compile,
    src_dir_path: []const u8,
    dest_rel_path: []const u8,
) void {
    return installHeadersDirectoryOptions(a, .{
        .source_dir = .{ .path = src_dir_path },
        .install_dir = .header,
        .install_subdir = dest_rel_path,
    });
}
```

So it's just calling `installHeadersDirectoryOptions` and passing in some defaults.
Before we move on to that function though, notice the argument names: `src_dir_path`
and `dest_rel_path`. That means a path relative to the source code directory and
a path relative to the install destination, respectively. Now for `installHeadersDirectoryOptions`:

```zig
pub fn installHeadersDirectoryOptions(
    cs: *Compile,
    options: std.Build.Step.InstallDir.Options,
) void {
    const b = cs.step.owner;
    const install_dir = b.addInstallDirectory(options);
    b.getInstallStep().dependOn(&install_dir.step);
    cs.installed_headers.append(&install_dir.step) catch @panic("OOM");
}
```

So first, we grab the `std.Build` which is building the step be accessing the
`owner` field of the compile step. The builder holds a pointer to the root of
the build graph (the install step). We are going to do two things with the builder:
first, use its `addInstallDirectory` function to create a new `Step.InstallDir`.
Then, we get the builder's install step, so we can make it depend on the new step.

`addInstallDirectory` is an example of the [add prefix pattern](./API_PATTERNS.md#the-build-struct-step-constructors-and-the-add-prefix)

Finally, and most importantly, we add the step to a list of steps that the `Step.Compile`
has called `installed_headers`. This way, the library has a reference to the step
that produces the headers it needs.

## Linking The Library

After having built this library, you may want to link it into another library or
executable. That involves just calling the `linkLibrary` function of the `Compile.Step`.
Here is a full build script which does exactly that. It uses a made-up source file
called `main.c` as the source for the executable which depends on libfoo.

```zig
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

    libfoo.linkLibC();

    libfoo.installHeadersDirectory("include", "");

    b.installArtifact(libfoo);

    // additional stuff for adding an executable that depends on libfoo
    const foo_exe = b.addExecutable(.{
        .name = "foo_exe",
        .target = target,
        .optimize = optimize,
    });

    foo_exe.addCSourceFiles(&.{
        "main.c",
    }, &.{
        "-Wall",
    });

    // the cool thing. notice we don't need to add include directories: this linkLibrary
    // function automatically adds the library's public include directory.
    foo_exe.linkLibrary(libfoo);

    b.installArtifact(foo_exe);
}
```
