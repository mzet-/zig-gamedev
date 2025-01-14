# ztracy - performance markers for Tracy 0.8

Zig bindings taken from: https://github.com/SpexGuy/Zig-Tracy

## Getting started

Copy `ztracy` folder to a `libs` subdirectory of the root of your project.

Then in your `build.zig` add:

```zig
pub fn build(b: *std.build.Builder) void {
    ...
    const enable_tracy = b.option(bool, "enable-tracy", "Enable Tracy profiler") orelse false;

    const exe_options = b.addOptions();
    exe_options.addOption(bool, "enable_tracy", enable_tracy);
    exe.addOptions("build_options", exe_options);

    const options_pkg = std.build.Pkg{
        .name = "build_options",
        .path = exe_options.getSource(),
    };

    const ztracy_pkg = std.build.Pkg{
        .name = "ztracy",
        .path = .{ .path = "libs/ztracy/ztracy.zig" },
        .dependencies = &[_]std.build.Pkg{
            options_pkg,
        },
    };
    exe.addPackage(ztracy_pkg);
    @import("libs/ztracy/build.zig").link(exe, enable_tracy);
}
```

Now in your code you may import and use ztracy. To build your project with Tracy enabled run:

`zig build -Denable-tracy=true`

```zig
const ztracy = @import("ztracy");

pub fn main() !void {
    {
        const tracy_zone = ztracy.ZoneNC(@src(), "Compute Magic", 0x00_ff_00_00);
        defer tracy_zone.End();
        ...
    }
}
```
