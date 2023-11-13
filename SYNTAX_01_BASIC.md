# Zig Syntax, or, Why Does It Look Like Javascript?

Zig has a few idiosyncracies that can perplex new users. To avoid this, I will
be explaining most of the syntax. Luckily, the language is quite simple.
Read the following example:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
}
```

`const` is the start of a variable declaration. It means that the contents of
the variable will not be modified after creation. The compiler can also make these
compile-time constants if it's able to deduce their value at compile time.

`std` is the name of the variable. We are going to store the stdlib inside of this
variable.

`=` is the assignment operator. Put the left hand side into the right hand side.

`@import` is a _builtin_ function. All builtin functions will be prefixed with
an `@` symbol. An example of another builtin is `@panic` which ends the program
and can print a stack trace.

`@import("std")` means that we are importing the standard library. Normally, this
would be a path to a file which has variables and functions we want to import into
`std`. For example, if the stdlib was located in a folder called `stdlib/` and the
entry point was called `main.zig`, we would do `@import("stdlib/main.zig")`. In this
case, though, zig lets you use this shorthand to import this known namespace.

TODO: is there some sort of search path or environment variable zig uses for this?

`;` is used to end an operation (either an assignment operator or outermost function
call).

Continuing on to the function:

`pub` means that other files can do `@import("/path/to/this/file.zig")` and get access
to this variable/function.

`fn` means that this is a function.

`build` is the name of the function. Zig does not have function overloading, so
this name must be unique within the current namespace. Also, in the case of `build.zig`,
this function _must_ be called `build` in order for it to get automatically called
in `zig build`. It's like `int main` but for the zig build system.

`b` is the name of an argument that this function accepts.

`*std.Build` is the _type_ of `b`. Notice that these two are separated by a colon.
Type hinting in zig is always provided this way. For example:

```zig
// no hinting
const letter = 'u';
// hinting
const letter: u8 = 'u';
```

`void` is the return type of the function.

Inside the function (in the `{}`) there is a variable declaration and assignment.
We've seen this already, with the exception of `b.standardTargetOptions`. The
dot (`.`) is used to access a field which is inside a namespace or struct. In this
case, the type `std.Build` has a function in it which accepts two arguments: a `std.Build`
and some options (which we'll get to in a second). The actual source code for
`standardTargetOptions` looks like this:

```zig
pub fn standardTargetOptions(self: *std.Build, args: std.Build.StandardTargetOptionsArgs) CrossTarget {
    /// code and stuff (why are you looking at this? the point is the function arguments)
}
```

So as we can see, it is a `pub` function (hence why we are able to access it with
the `.` notation) and it accepts the two aforementioned arguments. It returns something
called a `CrossTarget`, which we'll ignore for now, since that's not important to
the syntax. Although you can't tell by the snippet, this is also in a file called
`Build.zig` which is imported into `std` as `pub const Build = @import("Build.zig");`.
So then, why do we do `b.standardTargetOptions(.{})` and not
`std.Build.standardTargetOptions(b, .{})`? Well, it's just shorthand! You totally
can do the latter method, if you prefer.

One last thing: `.{}`. What is that?

Well, in C, you can do the following:

```c
typedef struct {
    float x;
    float y;
} Vector2;

Vector2 vec = {.x = 10, .y = 0};
// or...
Vector2 vec_again = {};
```

The compiler knows that `{}` is meant to be a `Vector2` because that's what it's
being assigned to. Zig has precisely the same feature, except it works in more
contexts (such as when passing an argument to a function) and it requires an additional
`.` before the curly braces. The same code in zig would look like this:

```zig
const Vector2 = struct {
    x: f32 = 0, // float32 with a default value of 0
    y: f32 = 0,
};

const vec : Vector2 = .{
    .x = 10,
    .y = 0,
};
const vec : Vector2 = .{};
```

The same thing applies to `standardTargetOptions`, which accepts a `StandardTargetOptionsArgs`.
To construct a default `StandardTargetOptionsArgs`, just put a `.{}` it its place.

Note though that zig does not support implicit constructors. When I say "construct"
a default instance of the struct, I am only referring to default initialization
of its fields, provided that the fields have a definite default value.

That is the basic syntax of Zig. Later we will cover slices, arrays, and the `&`
operator.
