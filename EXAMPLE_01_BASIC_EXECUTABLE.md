# Building A Basic C/C++ Project

This document will get you to the point where you can build an extremely simple
executable with no dependencies besides libc and/or libc++.

## Basic Zig Syntax

See [Basic Syntax](./SYNTAX_01_BASIC.md) for a primer on the very very basics
of the language. Luckily, that is most of the language.

## The Project

Let's say that you have project with a directory structure that looks something
like this:

- src/
  - foo.c
  - bar.c
- include/
  - foo.h
  - bar.h
- .gitignore
- main.c

You can see this in the `examples/01_basic` directory.

## The Build Script

The first step is to create a `build.zig` file. Then, give it the following
contents:

```zig
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
```

If things in here like `fn` and `.{}` are alien to you, check out the [Basic Syntax](./BASIC_ZIG_SYNTAX.md)
page. If not, then read on. We'll start by going line by line.

```zig
const target = b.standardTargetOptions(.{});
```

This function will look at the arguments passed to the program (the familiar
`argv`) and looks for a flag `-Dtarget="..."` and tries to parse it. If it's
successful, it will return a [`std.zig.CrossTarget`](https://ziglang.org/documentation/master/std/#A;std:zig.CrossTarget).
We can then pass that struct to other functions to let them know what kind of
architecture, OS, and libc we want to use.

Additionally, this function will add some additional info to the stdout if this
program is invoked with `zig build help`. It will include a description of the
target option. The `.{}` is a way of passing in the default options.

```zig
const optimize = b.standardOptimizeOption(.{});
```

`optimize` is just an enum value. Its declaration looks like this:

```zig
pub const OptimizeMode = enum {
    Debug,
    ReleaseSafe,
    ReleaseFast,
    ReleaseSmall,
};
```

These are the very same optimization option that can be chosen on the command line.
Now, let's look at `addExecutable`. This is a function that the `b` `std.Build`
object has. It will return a pointer to a `std.Build.Step.Compile`. This is a newly
allocated object (allocated with the `b.allocator`) and it _should not be freed_.
It is available through this pointer for you to modify, but the builder is also
internally storing a pointer to it as well, which it will later use to figure out
what it needs to build and how.

```zig
const exe = b.addExecutable(.{
    .name = "example",
    .target = target,
    .optimize = optimize,
});
```

Notice that, for the options (`std.Build.ExecutableOptions`) we are specifying
the name, target, and optimize fields, but leaving the others at default. Here
are the available options:

```zig
pub const ExecutableOptions = struct {
    name: []const u8,
    root_source_file: ?LazyPath = null,
    version: ?std.SemanticVersion = null,
    target: CrossTarget = .{},
    optimize: std.builtin.Mode = .Debug,
    linkage: ?Step.Compile.Linkage = null,
    max_rss: usize = 0,
    link_libc: ?bool = null,
    single_threaded: ?bool = null,
    use_llvm: ?bool = null,
    use_lld: ?bool = null,
    zig_lib_dir: ?LazyPath = null,
    main_pkg_path: ?LazyPath = null,
};
```

The default optimize mode is debug, and the default target is... a default `CrossTarget`.
But if we investigate into `CrossTarget.zig`, we'll find:

```zig
/// `null` means native.
cpu_arch: ?Target.Cpu.Arch = null,
```

So the default target is native. However, we want the player to be able to change
this with their command-line options, so we pass the target we got from the command-line
(with `standardTargetOptions`) into this executable. However, the `name` field is
required, and it will be the name of the file. So this example, on windows, will
produce a `example.exe` executable.

Now, we are going to modify this `Compile.Step` that we got from `addExecutable`.
Let's queue up some C source files to be compiled:

```zig
exe.addCSourceFiles(&.{
    "main.c",
    "src/foo.c",
    "src/bar.c",
}, &.{
    "-Wall",
});
```

Here we see a slice of source files, followed by a slice of flags. These flags
are shared when compiling all of the source files in the list. If you want to
have different flags on a per-file basis, you'll need to add files separately
using separate `exe.addCSourceFiles` calls.

Note that the source files are relative to the root directory (the location of
the build.zig).

Also note that you have raw access to the flags passed to the compiler, so there
is some overlap with other functionality. For example, you can pass in some
`"-Iinclude/"` flag, but there is already functionality to add an include directory
to a `Step.Compile`, as we'll see next.

```zig
exe.addIncludePath(.{ .path = "include" });
```

This is a function of a `Step.Compile` which adds a certain path as available for
include by all C source files in that `exe`. We do not directly pass in the path
as a string, however. We pass in a union called a `LazyPath`, and we choose to
set the `path` field to be active, and set it to the relative path from root to
the include directory. `LazyPath` can also be a `std.Build.GeneratedFile` which
is something which needs to be generated but hasn't yet, so the path to it is
unknown (hence "lazy" path. It waits to do its job of being a path until later).
Also, a `LazyPath` can be a `cwd_relative` path, which is just a path relative to
the place that the user invoked `zig build` instead of relative to the actual
build.zig.


```zig
exe.linkLibC();
```

Libc is just so gosh darn popular that the Zig folks made a whole function for
linking it. Also, the zig distribution will provide the libc itself.

This is needed if we want access to such hits as `stdio.h` and `unistd.h`.

```zig
b.installArtifact(exe);
```

Here it is, the ultimate step: setting the build to actual depend on the compilation
of this executable. If you do not do this step, the exe will not be a part of the
build graph and therefore be ignored when running `zig build`. What this actually
does is set the install step (which is always run) to be dependent on building your
library. You can also make other steps besides the install step, and then run
them with `zig build stepname`. We'll cover that in detail later. For now, we are
only using `zig build` which just does the install step, and for that to build
our custom executable it needs to depend on it.

All done. Now run `zig build` to get the executable in `zig-out/bin/`.
