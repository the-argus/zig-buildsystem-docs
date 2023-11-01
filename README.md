# Zig Buildsystem Docs

Comprehensive documentation for using the Zig build system to build C and C++ projects.

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
favorite terminal emulator to use Zig.

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
