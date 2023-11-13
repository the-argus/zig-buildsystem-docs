# The Zig Package Manager

Zig can fetch third-party dependencies. At the time of writing, this functionality
is new to the last stable release (0.11.0). It is subject to change and entirely
undocumented anywhere else, as far as I can tell.

Here is what you need to do, if you want to build an exe which depends on a library
whose source is in another third-party library. First, create a file next to your
`build.zig` called `build.zig.zon`. Give it the following contents:

```zig
.{
    .name = "myprogram",
    .version = "0.0.1",

    .dependencies = .{
        .raylib = .{
            .url = "https://github.com/raysan5/raylib/archive/e7664d5684f4b7c487d2a08645f23a1d0485f9e7.tar.gz",
            .hash = "12203a237a96a5f37713979a57a201b4ec93f8a56e571f8584cfeb72156e4ccc14fa",
        },
    }
}
```

The "name" and "version" fields are for your package: make them whatever you want.
At time of writing, I don't believe these have any effect on anything.

The `dependencies` section is the interesting part. It's a struct containing
named entries for each third-party dependency. The names of these (for example
`.raylib`) are up to you. You will later reference the names in your `build.zig`.

Inside each entry (in our case, just `.raylib` there are two fields: `url` and `hash`.
Notice that this is version control agnostic: there is no `commit` or `branch`
field. Simply use a link which downloads a tarball, and provide the hash of said
tarball.

## Getting The Hash

All hashes for third-party tarballs start with `1220`, which denotes the hash
algorithm used. Getting this hash is not easy (utilities such as `sha256sum` do
not work). At the time of writing, the best way to get the hash when you don't
know it. For example, you change the commit of the tarball you're downloading,
so the hash has changed. In this case, set the hash to the following:

```txt
1220aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```

Then run `zig build`. Zig will fetch the tarball, find that its hash is wrong,
and then print out the actual hash. Copy-paste the correct hash into your `build.zig.zon`
and run `zig build` again. Zig should correctly fetch the package and put it in
its cache after that.

## A Note About Zig's Cache

At time of writing, zig notices cache changes based on the _hash_, not the url.
That means that if you change the URL, zig will see that the hash is the same and
assume that you are just getting the same tarball from a different place, and
not even try to download from the new URL.

So if I change this:

```zig
        .raylib = .{
            .url = "https://github.com/raysan5/raylib/archive/e7664d5684f4b7c487d2a08645f23a1d0485f9e7.tar.gz",
            .hash = "12203a237a96a5f37713979a57a201b4ec93f8a56e571f8584cfeb72156e4ccc14fa",
        },
```

To this:

```zig
        .raylib = .{
            // notice the different commit hash!
            .url = "https://github.com/raysan5/raylib/archive/595ca7010ea7c48943101b766a1ed2a34e5364a7.tar.gz",
            .hash = "12203a237a96a5f37713979a57a201b4ec93f8a56e571f8584cfeb72156e4ccc14fa",
        },
```

and run `zig build`, it will be as though I never even changed the URL. Zig will
just keep using the tarball it has in cache, because the hash is the same.

## Using Dependencies In Your build.zig
