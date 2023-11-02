# Zig Buildsystem Docs

Comprehensive documentation for using the Zig build system to build C and C++ projects.

Made for Zig version 0.11.0.

Intended for people who do not really want to learn the Zig language, but just want
to build their C and C++ projects in the easiest way possible (the easiest way
is not CMake and vcpkg, that is for sure).

## Why Zig and not Meson or Scons or Foobar?

Meson is not much different from cmake: it is primarily an improvement if you come
from the dark depths known as "autotools." Scons is certainly a worthy competitor
to Zig. In the case of both Zig and scons, you get access to a fully-featured
language thanks to the build system basically just being a library for those
languages.

But Zig has one great advantage: it is a C/C++ compiler as well as a build system.
That means _no more compiler detecting code_. There is only _one_ compiler that
anyone could be using to build a Zig project: `zig cc`. This compiler works virtually
the same way on all platforms, and has excellent cross-compilation support thanks
to shipping its own libc.

Building a Zig project looks like this on all platforms:

First, go to [ziglang.org/download](https://ziglang.org/download/) and
download the `v0.11.0` zip/tarball for your system. Unzip it. Add the resulting
unpacked folder to your path (it should contain a `zig` or `zig.exe` executable).
Then:

```bash
cd zigproject
zig build
```

It will fetch any third party dependencies, build them and compile your program.

Oh yeah, Zig is also a package manager.

Additionally, Zig provides a declarative method of building, which we'll discuss
more later. It makes Zig good at detecting changes and invalidating cache. I rarely
(never?) find myself clearing cache folders or generated files when using Zig.

## Zig For Dummies

You probably don't want to learn the whole Zig language if you are just trying to
build you C/C++ projects. So lets go over just what you need to know to get it working.

### What is Zig Doing?

Zig is a single executable program. If you download zig, you will get a zip/tar
file containing the stdlib as text files, and some file like `zig.exe` or just
`zig`. This is a CLI program, so you will be using `cmd.exe` or powershell or your
favorite terminal emulator to interact with it.

Zig has many _subcommands_. These are basically all of the different things that
zig can do. It can translate C code into zig code with the `translate-c` subcommand,
or it can compile a C++ program with `zig c++`, and it can be used as a drop-in
replacement for objcopy with `zig objcopy`. We will be focusing only on the first
subcommand, though: `zig build`.

When you run `zig build` in your project, the Zig executable will look for a file
called `build.zig` in your working directory. It will then take that file as input,
along with the stdlib that the executable came with, to compile a program. Then,
Zig will run that program and pass along any flags that you provided at the initial
command line invocation. The program that was compiled was _not_ your project's
executable or library. Rather, it is an executable which is able to compile your
project. This means it is quite fast (not that it matters since the actual compilation
is by far the most time consuming part) and that you have to wait for your build
code to compile whenever you change it.

### Basic Zig Syntax

See [Basic Syntax](./BASIC_ZIG_SYNTAX.md) for a primer on the very very basics
of the language. Luckily, that is most of the language.

### Building A Basic Project

Let's say that you have project with a directory structure that looks something
like this:

- src/
  - foo.c
  - bar.c
- include/
  - foo.h
  - bar.h
- LICENSE
- .gitignore
- main.c

You can see this in the `examples/1_basic` directory.

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
of this executable. If you do not do this step, the exe will basically not be

