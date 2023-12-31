# Zig Buildsystem Docs

Comprehensive documentation for using the Zig build system to build C and C++ projects.

Made for Zig version 0.11.0.

Intended for people who do not really want to learn the Zig language, but just want
to build their C and C++ projects in the easiest way possible (the easiest way
is not CMake and vcpkg, that is for sure).

## Table of Contents

First, you're going to want to visit [Basic Syntax](./SYNTAX_01_BASIC.md) unless
you are already confident writing zig code.

1. Examples and Walkthrough
   1. [Basic C Executable](./EXAMPLE_01_BASIC_EXECUTABLE.md)
   2. [C Library](./EXAMPLE_2_C_LIBRARY.md)
   3. [Package Manager](./EXAMPLE_03_PACKAGE_MANAGER.md)
2. [API Documentation](./API.md)
3. [Common Patterns In The Zig Buildsystem API](./API_PATTERNS.md)
4. Zig Syntax Reference
   1. [Basic Syntax](./SYNTAX_01_BASIC.md)
   2. [Arrays and Slices](./SYNTAX_02_ARRAYS_AND_SLICES.md)
   3. [Generics](./SYNTAX_03_GENERICS.md)

## Why Zig and not Meson or Scons or Foobar?

Meson is not much different from cmake: it is an improvement over autotools, though.
Scons is certainly a worthy competitor to Zig. In the case of both Zig and scons,
you get access to a fully-featured programming language when writing your build
scripts.

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
project. So compilation with zig is two step: first, compile the build program,
then compile the target program.
