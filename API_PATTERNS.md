# Zig Buildsystem API Patterns

Common patterns in the Zig build system. You do not need to know these to use the
library, but knowing them will help you understand what you are doing.

## dependency graph

When you make a build script, you make a `build` function which takes a `*std.Build`.
That builder has an `install_step`. That step, and every other step, has a list
of dependencies:

```zig
dependencies: std.ArrayList(*Step),
```

Before a step is interpreted into actual compiler invocations, zig will traverse
into the dependencies of the step and make sure all of its children are built first.
In order to add your own compilation steps, you can create your own instances of
std.Build.Step and append them to this list of dependencies, or to the dependencies
of another step that's already in the graph.

You are not intended to directly append to dependencies by doing
`try build.getInstallStep().dependencies.append(...)`. Instead, use the functions
provided by the `std.Build` to interface with the build graph.

## cstyle inheritance from Step

`std.Build.Step` is a struct, defined within a file called `Step.zig`. It contains
some important functions and fields. Here is the beginning of `Step.zig`:

```zig
id: Id,
name: []const u8,
owner: *Build,
makeFn: MakeFn,

dependencies: std.ArrayList(*Step),
/// This field is empty during execution of the user's build script, and
/// then populated during dependency loop checking in the build runner.
dependants: std.ArrayListUnmanaged(*Step),
state: State,
```

It has a pointer back to the builder, and a list of dependencies, and a function
pointer to the code that will be run when it is evaluated during the actual build
execution. It also has an `id` field. This is an enum which corresponds to the
many sub-classes of `Step`. Here is what that enum looks like:

```zig
pub const Id = enum {
    top_level,
    compile,
    install_artifact,
    install_file,
    install_dir,
    remove_dir,
    fmt,
    translate_c,
    write_file,
    run,
    check_file,
    check_object,
    config_header,
    objcopy,
    options,
    custom,

    pub fn Type(comptime id: Id) type {
        return switch (id) {
            .top_level => Build.TopLevelStep,
            .compile => Compile,
            .install_artifact => InstallArtifact,
            .install_file => InstallFile,
            .install_dir => InstallDir,
            .remove_dir => RemoveDir,
            .fmt => Fmt,
            .translate_c => TranslateC,
            .write_file => WriteFile,
            .run => Run,
            .check_file => CheckFile,
            .check_object => CheckObject,
            .config_header => ConfigHeader,
            .objcopy => ObjCopy,
            .options => Options,
            .custom => @compileError("no type available for custom step"),
        };
    }
}
```

As you can see by the `Type` function, each value of `Id` corresponds to a
different actual type. Every one of those types has a `std.Build.Step` as its
first field. For example, the first field of `Compile.zig`:

```zig
step: Step,
```

That means that you can safely cast a pointer to a `std.Build.Step.Compile` (or
any other step type) to a `std.Build.Step`. There is also a way to downcast: a
function provided by the `std.Build.Step`.

```zig
pub fn cast(step: *Step, comptime T: type) ?*T {
    if (step.id == T.base_id) {
        return @fieldParentPtr(T, "step", step);
    }
    return null;
}
```

## the Build struct Step constructors and the add prefix

The `std.Build` has a lot of functions such as `addInstallDirectory`, or `addInstallFileWithDir`,
or `addInstallArtifact`. All of these functions call initialization functions of
various types. For example, `addInstallArtifact` calls the `create` function of
`std.Build.Step.InstallArtifact`. That function returns a pointer to a newly
allocated step which will copy a compiled artifact from its cache to the installation
prefix. However, the steps produced by the `addFoo` functions do *not* add the
steps to the build graph.

```zig
/// This merely creates the step; it does not add it to the dependencies of the
/// top-level install step.
pub fn addInstallArtifact(
    self: *Build,
    artifact: *Step.Compile,
    options: Step.InstallArtifact.Options,
) *Step.InstallArtifact {
    return Step.InstallArtifact.create(self, artifact, options);
}
```

If you want an easy shorthand for adding a new step to the build graph, try the
versions of the `addFoo` functions just called `foo`. `addInstallArtifact` has
`installArtifact` and `addInstallDirectory` has `installDirectory`. All of these
are functions of `std.Build`, and they are usually just one line. For example, here
is `installArtifact`.

```zig
pub fn installArtifact(self: *Build, artifact: *Step.Compile) void {
    self.getInstallStep().dependOn(&self.addInstallArtifact(artifact, .{}).step);
}
```

It simply creates a new install artifact step using the default options and then
passes a pointer to its `step` field into the `dependOn` function of builder's
top-level install step. This means that the newly created step will be traversed
at build time.
