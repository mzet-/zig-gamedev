# zmath v0.3 - SIMD math library for game developers

Should work on all OSes supported by Zig. Works on x86_64 and ARM.

Provides ~140 optimized routines and ~70 extensive tests.

Can be used with any graphics API.

See functions list in the [code](https://github.com/michal-z/zig-gamedev/blob/main/libs/zmath/src/zmath.zig).

Read [intro article](https://github.com/michal-z/zig-gamedev/wiki/Fast,-multi-platform,-SIMD-math-library-in-Zig).

## Getting started

Copy `zmath` folder to a `libs` subdirectory of the root of your project.

Then in your `build.zig` add:

```zig
pub fn build(b: *std.build.Builder) void {
    ...
    const zmath_pkg = std.build.Pkg{
        .name = "zmath",
        .path = .{ .path = "libs/zmath/src/zmath.zig" },
    };
    exe.addPackage(zmath_pkg);
}
```

Now in your code you may import and use zmath:

```zig
const zm = @import("zmath");

pub fn main() !void {
    //
    // OpenGL/Vulkan example
    //
    const object_to_world = zm.rotationY(..);
    const world_to_view = zm.lookAtRh(
        zm.f32x4(3.0, 3.0, 3.0, 1.0), // eye position
        zm.f32x4(0.0, 0.0, 0.0, 1.0), // focus point
        zm.f32x4(0.0, 1.0, 0.0, 0.0), // up direction ('w' coord is zero because this is a vector not a point)
    );
    // `perspectiveFovRhGl` produces Z values in [-1.0, 1.0] range (Vulkan app should use `perspectiveFovRh`)
    const view_to_clip = zm.perspectiveFovRhGl(0.25 * math.pi, aspect_ratio, 0.1, 20.0);

    const object_to_view = zm.mul(object_to_world, world_to_view);
    const object_to_clip = zm.mul(object_to_view, view_to_clip);

    // Transposition is needed because GLSL uses column-major matrices by default
    gl.uniformMatrix4fv(0, 1, gl.TRUE, zm.asFloats(&object_to_clip));
    
    // In GLSL: gl_Position = vec4(in_position, 1.0) * object_to_clip;
    
    //
    // DirectX example
    //
    const object_to_world = zm.rotationY(..);
    const world_to_view = zm.lookAtLh(
        zm.f32x4(3.0, 3.0, -3.0, 1.0), // eye position
        zm.f32x4(0.0, 0.0, 0.0, 1.0), // focus point
        zm.f32x4(0.0, 1.0, 0.0, 0.0), // up direction ('w' coord is zero because this is a vector not a point)
    );
    const view_to_clip = zm.perspectiveFovLh(0.25 * math.pi, aspect_ratio, 0.1, 20.0);

    const object_to_view = zm.mul(object_to_world, world_to_view);
    const object_to_clip = zm.mul(object_to_view, view_to_clip);
    
    // Transposition is needed because HLSL uses column-major matrices by default
    const mem = allocateUploadMemory(...);
    zm.storeMat(mem, zm.transpose(object_to_clip));
    
    // In HLSL: out_position_sv = mul(float4(in_position, 1.0), object_to_clip);
    
    //
    // 'WASD' camera movement example
    //
    {
        const speed = zm.f32x4s(10.0);
        const delta_time = zm.f32x4s(demo.frame_stats.delta_time);
        const transform = zm.mul(zm.rotationX(demo.camera.pitch), zm.rotationY(demo.camera.yaw));
        var forward = zm.normalize3(zm.mul(zm.f32x4(0.0, 0.0, 1.0, 0.0), transform));

        zm.store(demo.camera.forward[0..], forward, 3);

        const right = speed * delta_time * zm.normalize3(zm.cross3(zm.f32x4(0.0, 1.0, 0.0, 0.0), forward));
        forward = speed * delta_time * forward;

        var campos = zm.load(demo.camera.position[0..], zm.Vec, 3);

        if (keyDown('W')) {
            campos += forward;
        } else if (keyDown('S')) {
            campos -= forward;
        }
        if (keyDown('D')) {
            campos += right;
        } else if (keyDown('A')) {
            campos -= right;
        }

        zm.store(demo.camera.position[0..], campos, 3);
    }
   
    //
    // SIMD wave equation solver example (works with vector width 4, 8 and 16)
    // 'T' can be F32x4, F32x8 or F32x16
    //
    var z_index: i32 = 0;
    while (z_index < grid_size) : (z_index += 1) {
        const z = scale * @intToFloat(f32, z_index - grid_size / 2);
        const vz = zm.splat(T, z);

        var x_index: i32 = 0;
        while (x_index < grid_size) : (x_index += zm.veclen(T)) {
            const x = scale * @intToFloat(f32, x_index - grid_size / 2);
            const vx = zm.splat(T, x) + voffset * zm.splat(T, scale);

            const d = zm.sqrt(vx * vx + vz * vz);
            const vy = zm.sin(d - vtime);

            const index = @intCast(usize, x_index + z_index * grid_size);
            zm.store(xslice[index..], vx, 0);
            zm.store(yslice[index..], vy, 0);
            zm.store(zslice[index..], vz, 0);
        }
    }
}
```
