// ==============================================================================
//
// zmath lib 0.2
// Fast SIMD math library for game developers
// https://github.com/michal-z/zig-gamedev/blob/main/libs/common/zmath.zig
//
// zmath uses row-major matrices, row vectors (each row vector is stored in SIMD register).
// Handedness is determined by which function version is used (Rh vs. Lh),
// otherwise the function works with either left-handed or right-handed view coordinates.
//
// const va = f32x4(1.0, 2.0, 3.0, 1.0);
// const vb = f32x4(-1.0, 1.0, -1.0, 1.0);
// const v0 = va + vb - f32x4(0.0, 1.0, 0.0, 1.0) * splat(F32x4, 3.0);
// const v1 = cross(va, vb) + f32x4(1.0, 1.0, 1.0, 1.0);
// const s0 = dot3(va, vb);
//
// const m = rotationX(math.pi * 0.25);
// const v = f32x4(...);
// const v0 = mul(v, m); // 'v' treated as row vector
// const v1 = mul(m, v); // 'v' treated as column vector
// mul(v, m) == mul(transpose(m), v)
// const f = m[row][column];
//
// const b = va < vb;
// if (all(b, 0)) { ... } // '0' means check all vector components; if all are 'true'
// if (all(b, 3)) { ... } // '3' means check first three vector components; if all first three are 'true'
// if (any(b, 0)) { ... } // '0' means check all vector components; if any is 'true'
// if (any(b, 3)) { ... } // '3' means check first three vector components; if any from first three is 'true'
//
// const v4 = f32x4(...);
// const v8 = f32x8(...);
// const v16 = f32x16(...);
// const v4r = sin(v4);
// const v8r = sin(v8);
// const v16r = sin(v16);
//
// ------------------------------------------------------------------------------
// 1. Initialization functions
// ------------------------------------------------------------------------------
//
// f32x4(e0: f32, e1: f32, e2: f32, e3: f32) F32x4
// f32x8(e0: f32, e1: f32, e2: f32, e3: f32, e4: f32, e5: f32, e6: f32, e7: f32) F32x8
// f32x16(e0: f32, e1: f32, e2: f32, e3: f32, e4: f32, e5: f32, e6: f32, e7: f32,
//        e8: f32, e9: f32, ea: f32, eb: f32, ec: f32, ed: f32, ee: f32, ef: f32) F32x16
//
// f32x4s(e0: f32) F32x4
// f32x8s(e0: f32) F32x8
// f32x16s(e0: f32) F32x16
//
// u32x4(e0: u32, e1: u32, e2: u32, e3: u32) U32x4
// u32x8(e0: u32, e1: u32, e2: u32, e3: u32, e4: u32, e5: u32, e6: u32, e7: u32) U32x8
// u32x16(e0: u32, e1: u32, e2: u32, e3: u32, e4: u32, e5: u32, e6: u32, e7: u32,
//        e8: u32, e9: u32, ea: u32, eb: u32, ec: u32, ed: u32, ee: u32, ef: u32) U32x16
//
// boolx4(e0: bool, e1: bool, e2: bool, e3: bool) Boolx4
// boolx8(e0: bool, e1: bool, e2: bool, e3: bool, e4: bool, e5: bool, e6: bool, e7: bool) Boolx8
// boolx16(e0: bool, e1: bool, e2: bool, e3: bool, e4: bool, e5: bool, e6: bool, e7: bool,
//         e8: bool, e9: bool, ea: bool, eb: bool, ec: bool, ed: bool, ee: bool, ef: bool) Boolx16
//
// load(mem: []const f32, comptime T: type, comptime len: u32) T
// loadF32x4x4(mem: []const f32) Mat
// store(mem: []f32, v: anytype, comptime len: u32) void
// storeF32x4x4(mem: []f32, m: Mat) void
//
// splat(comptime T: type, value: f32) T
// splatInt(comptime T: type, value: u32) T
// usplat(comptime T: type, value: u32) T
//
// ------------------------------------------------------------------------------
// 2. Functions that work on all vector components (F32xN = F32x4 or F32x8 or F32x16)
// ------------------------------------------------------------------------------
//
// all(vb: anytype, comptime len: u32) bool
// any(vb: anytype, comptime len: u32) bool
//
// isNearEqual(v0: F32xN, v1: F32xN, epsilon: F32xN) BoolxN
// isNan(v: F32xN) BoolxN
// isInf(v: F32xN) BoolxN
// isInBounds(v: F32xN, bounds: F32xN) BoolxN
//
// andInt(v0: F32xN, v1: F32xN) F32xN
// andNotInt(v0: F32xN, v1: F32xN) F32xN
// orInt(v0: F32xN, v1: F32xN) F32xN
// norInt(v0: F32xN, v1: F32xN) F32xN
// xorInt(v0: F32xN, v1: F32xN) F32xN
//
// minFast(v0: F32xN, v1: F32xN) F32xN
// maxFast(v0: F32xN, v1: F32xN) F32xN
// min(v0: F32xN, v1: F32xN) F32xN
// max(v0: F32xN, v1: F32xN) F32xN
// round(v: F32xN) F32xN
// floor(v: F32xN) F32xN
// trunc(v: F32xN) F32xN
// ceil(v: F32xN) F32xN
// clamp(v0: F32xN, v1: F32xN) F32xN
// clampFast(v0: F32xN, v1: F32xN) F32xN
// saturate(v: F32xN) F32xN
// saturateFast(v: F32xN) F32xN
// lerp(v0: F32xN, v1: F32xN, t: f32) F32xN
// lerpV(v0: F32xN, v1: F32xN, t: F32xN) F32xN
// sqrt(v: F32xN) F32xN
// abs(v: F32xN) F32xN
// mod(v0: F32xN, v1: F32xN) F32xN
// modAngle(v: F32xN) F32xN
// mulAdd(v0: F32xN, v1: F32xN, v2: F32xN) F32xN
// select(mask: BoolxN, v0: F32xN, v1: F32xN)
// sin(v: F32xN) F32xN
// cos(v: F32xN) F32xN
// sincos(v: F32xN) [2]F32xN
// asin(v: F32xN) F32xN
// acos(v: F32xN) F32xN
// atan(v: F32xN) F32xN
// atan2(vy: F32xN, vx: F32xN) F32xN
//
// ------------------------------------------------------------------------------
// 3. 2D, 3D, 4D vector functions
// ------------------------------------------------------------------------------
//
// swizzle(v: Vec, c, c, c, c) Vec (comptime c = .x | .y | .z | .w)
// dot2(v0: Vec, v1: Vec) F32x4
// dot3(v0: Vec, v1: Vec) F32x4
// dot4(v0: Vec, v1: Vec) F32x4
// cross3(v0: Vec, v1: Vec) Vec
// lengthSq2(v: Vec) F32x4
// lengthSq3(v: Vec) F32x4
// lengthSq4(v: Vec) F32x4
// length2(v: Vec) F32x4
// length3(v: Vec) F32x4
// length4(v: Vec) F32x4
// normalize2(v: Vec) Vec
// normalize3(v: Vec) Vec
// normalize4(v: Vec) Vec
// mul(v: Vec, m: Mat) Vec
// mul(m: Mat, v: Vec) Vec
// mul(v: Vec, s: f32) Vec
// mul(s: f32, v: Vec) Vec
//
// ------------------------------------------------------------------------------
// 4. Matrix functions
// ------------------------------------------------------------------------------
//
// mul(m0: Mat, m1: Mat) Mat
// transpose(m: Mat) Mat
// rotationX(angle: f32) Mat
// rotationY(angle: f32) Mat
// rotationZ(angle: f32) Mat
// translation(x: f32, y: f32, z: f32) Mat
// translationV(v: Vec) Mat
// scaling(x: f32, y: f32, z: f32) Mat
// scalingV(v: Vec) Mat
// lookToLh(eyepos: Vec, eyedir: Vec, updir: Vec) Mat
// lookAtLh(eyepos: Vec, focuspos: Vec, updir: Vec) Mat
// lookToRh(eyepos: Vec, eyedir: Vec, updir: Vec) Mat
// lookAtRh(eyepos: Vec, focuspos: Vec, updir: Vec) Mat
// perspectiveFovLh(fovy: f32, aspect: f32, near: f32, far: f32) Mat
// perspectiveFovRh(fovy: f32, aspect: f32, near: f32, far: f32) Mat
// determinant(m: Mat) F32x4
// inverse(m: Mat) Mat
// inverseDet(m: Mat, det: ?*F32x4) Mat
// matToQuat(m: Mat) Quat
// matFromAxisAngle(axis: Vec, angle: f32) Mat
// matFromNormAxisAngle(axis: Vec, angle: f32) Mat
// matFromQuat(quat: Quat) Mat
// matFromRollPitchYaw(pitch: f32, yaw: f32, roll: f32) Mat
// matFromRollPitchYawV(angles: Vec) Mat
//
// ------------------------------------------------------------------------------
// 5. Quaternion functions
// ------------------------------------------------------------------------------
//
// mul(q0: Quat, q1: Quat) Quat
// conjugate(quat: Quat) Quat
// inverse(q: Quat) Quat
// slerp(q0: Quat, q1: Quat, t: f32) Quat
// slerpV(q0: Quat, q1: Quat, t: F32x4) Quat
// quatToMat(quat: Quat) Mat
// quatToAxisAngle(quat: Quat, axis: *Vec, angle: *f32) void
// quatFromMat(m: Mat) Quat
// quatFromAxisAngle(axis: Vec, angle: f32) Quat
// quatFromNormAxisAngle(axis: Vec, angle: f32) Quat
// quatFromRollPitchYaw(pitch: f32, yaw: f32, roll: f32) Quat
// quatFromRollPitchYawV(angles: Vec) Quat
//
// ------------------------------------------------------------------------------
// X. Misc functions
// ------------------------------------------------------------------------------
//
// linePointDistance(linept0: Vec, linept1: Vec, pt: Vec) F32x4
// sin(v: f32) f32
// cos(v: f32) f32
// sincos(v: f32) [2]f32
// asin(v: f32) f32
// acos(v: f32) f32
//
// ==============================================================================

// Fundamental types
pub const F32x4 = @Vector(4, f32);
pub const F32x8 = @Vector(8, f32);
pub const F32x16 = @Vector(16, f32);
pub const Boolx4 = @Vector(4, bool);
pub const Boolx8 = @Vector(8, bool);
pub const Boolx16 = @Vector(16, bool);

// Higher-level 'geometric' types
pub const Vec = F32x4;
pub const Mat = [4]F32x4;
pub const Quat = F32x4;

// Helper types
pub const U32x4 = @Vector(4, u32);
pub const U32x8 = @Vector(8, u32);
pub const U32x16 = @Vector(16, u32);

const builtin = @import("builtin");
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const expect = std.testing.expect;

const cpu_arch = builtin.cpu.arch;
const has_avx = if (cpu_arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .avx) else false;
const has_avx512f = if (cpu_arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .avx512f) else false;
const has_fma = if (cpu_arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .fma) else false;

// ------------------------------------------------------------------------------
//
// 1. Initialization functions
//
// ------------------------------------------------------------------------------

pub inline fn f32x4(e0: f32, e1: f32, e2: f32, e3: f32) F32x4 {
    return .{ e0, e1, e2, e3 };
}
pub inline fn f32x8(e0: f32, e1: f32, e2: f32, e3: f32, e4: f32, e5: f32, e6: f32, e7: f32) F32x8 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7 };
}
// zig fmt: off
pub inline fn f32x16(
    e0: f32, e1: f32, e2: f32, e3: f32, e4: f32, e5: f32, e6: f32, e7: f32,
    e8: f32, e9: f32, ea: f32, eb: f32, ec: f32, ed: f32, ee: f32, ef: f32) F32x16 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, ea, eb, ec, ed, ee, ef };
}
// zig fmt: on

pub inline fn f32x4s(e0: f32) F32x4 {
    return splat(F32x4, e0);
}
pub inline fn f32x8s(e0: f32) F32x8 {
    return splat(F32x8, e0);
}
pub inline fn f32x16s(e0: f32) F32x16 {
    return splat(F32x16, e0);
}

pub inline fn u32x4(e0: u32, e1: u32, e2: u32, e3: u32) U32x4 {
    return .{ e0, e1, e2, e3 };
}
pub inline fn u32x8(e0: u32, e1: u32, e2: u32, e3: u32, e4: u32, e5: u32, e6: u32, e7: u32) U32x8 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7 };
}
// zig fmt: off
pub inline fn u32x16(
    e0: u32, e1: u32, e2: u32, e3: u32, e4: u32, e5: u32, e6: u32, e7: u32,
    e8: u32, e9: u32, ea: u32, eb: u32, ec: u32, ed: u32, ee: u32, ef: u32) U32x16 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, ea, eb, ec, ed, ee, ef };
}
// zig fmt: on

pub inline fn boolx4(e0: bool, e1: bool, e2: bool, e3: bool) Boolx4 {
    return .{ e0, e1, e2, e3 };
}
pub inline fn boolx8(e0: bool, e1: bool, e2: bool, e3: bool, e4: bool, e5: bool, e6: bool, e7: bool) Boolx8 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7 };
}
// zig fmt: off
pub inline fn boolx16(
    e0: bool, e1: bool, e2: bool, e3: bool, e4: bool, e5: bool, e6: bool, e7: bool,
    e8: bool, e9: bool, ea: bool, eb: bool, ec: bool, ed: bool, ee: bool, ef: bool) Boolx16 {
    return .{ e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, ea, eb, ec, ed, ee, ef };
}
// zig fmt: on

pub fn veclen(comptime T: type) comptime_int {
    return @typeInfo(T).Vector.len;
}

pub inline fn splat(comptime T: type, value: f32) T {
    return @splat(veclen(T), value);
}
pub inline fn splatInt(comptime T: type, value: u32) T {
    return @splat(veclen(T), @bitCast(f32, value));
}
pub inline fn usplat(comptime T: type, value: u32) T {
    return @splat(veclen(T), value);
}

pub fn load(mem: []const f32, comptime T: type, comptime len: u32) T {
    var v = splat(T, 0.0);
    comptime var loop_len = if (len == 0) veclen(T) else len;
    comptime var i: u32 = 0;
    inline while (i < loop_len) : (i += 1) {
        v[i] = mem[i];
    }
    return v;
}
test "zmath.load" {
    const a = [7]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 };
    var ptr = &a;
    var i: u32 = 0;
    const v0 = load(a[i..], F32x4, 2);
    try expect(approxEqAbs(v0, [4]f32{ 1.0, 2.0, 0.0, 0.0 }, 0.0));
    i += 2;
    const v1 = load(a[i .. i + 2], F32x4, 2);
    try expect(approxEqAbs(v1, [4]f32{ 3.0, 4.0, 0.0, 0.0 }, 0.0));
    const v2 = load(a[5..7], F32x4, 2);
    try expect(approxEqAbs(v2, [4]f32{ 6.0, 7.0, 0.0, 0.0 }, 0.0));
    const v3 = load(ptr[1..], F32x4, 2);
    try expect(approxEqAbs(v3, [4]f32{ 2.0, 3.0, 0.0, 0.0 }, 0.0));
    i += 1;
    const v4 = load(ptr[i .. i + 2], F32x4, 2);
    try expect(approxEqAbs(v4, [4]f32{ 4.0, 5.0, 0.0, 0.0 }, 0.0));
}

pub fn store(mem: []f32, v: anytype, comptime len: u32) void {
    const T = @TypeOf(v);
    comptime var loop_len = if (len == 0) veclen(T) else len;
    comptime var i: u32 = 0;
    inline while (i < loop_len) : (i += 1) {
        mem[i] = v[i];
    }
}
test "zmath.store" {
    var a = [7]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 };
    const v = load(a[1..], F32x4, 3);
    store(a[2..], v, 4);
    try expect(a[0] == 1.0);
    try expect(a[1] == 2.0);
    try expect(a[2] == 2.0);
    try expect(a[3] == 3.0);
    try expect(a[4] == 4.0);
    try expect(a[5] == 0.0);
}

pub fn loadF32x4x4(mem: []const f32) Mat {
    return Mat{
        load(mem[0..4], F32x4, 0),
        load(mem[4..8], F32x4, 0),
        load(mem[8..12], F32x4, 0),
        load(mem[12..16], F32x4, 0),
    };
}
test "zmath.loadF32x4x4" {
    // zig fmt: off
    const a = [18]f32{
        1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0,
        13.0, 14.0, 15.0, 16.0,
        17.0, 18.0
    };
    // zig fmt: on
    const m = loadF32x4x4(a[1..]);
    try expect(approxEqAbs(m[0], [4]f32{ 2.0, 3.0, 4.0, 5.0 }, 0.0));
    try expect(approxEqAbs(m[1], [4]f32{ 6.0, 7.0, 8.0, 9.0 }, 0.0));
    try expect(approxEqAbs(m[2], [4]f32{ 10.0, 11.0, 12.0, 13.0 }, 0.0));
    try expect(approxEqAbs(m[3], [4]f32{ 14.0, 15.0, 16.0, 17.0 }, 0.0));
}

pub fn storeF32x4x4(mem: []f32, m: Mat) void {
    store(mem[0..4], m[0], 0);
    store(mem[4..8], m[1], 0);
    store(mem[8..12], m[2], 0);
    store(mem[12..16], m[3], 0);
}

// ------------------------------------------------------------------------------
//
// 2. Functions that work on all vector components (F32xN = F32x4 or F32x8 or F32x16)
//
// ------------------------------------------------------------------------------

pub fn all(vb: anytype, comptime len: u32) bool {
    const T = @TypeOf(vb);
    if (len > veclen(T)) {
        @compileError("zmath.all(): 'len' is greater than vector len of type " ++ @typeName(T));
    }
    comptime var loop_len = if (len == 0) veclen(T) else len;
    const ab: [veclen(T)]bool = vb;
    comptime var i: u32 = 0;
    var result = true;
    inline while (i < loop_len) : (i += 1) {
        result = result and ab[i];
    }
    return result;
}
test "zmath.all" {
    try expect(all(boolx8(true, true, true, true, true, false, true, false), 5) == true);
    try expect(all(boolx8(true, true, true, true, true, false, true, false), 6) == false);
    try expect(all(boolx8(true, true, true, true, false, false, false, false), 4) == true);
    try expect(all(boolx4(true, true, true, false), 3) == true);
    try expect(all(boolx4(true, true, true, false), 1) == true);
    try expect(all(boolx4(true, false, false, false), 1) == true);
    try expect(all(boolx4(false, true, false, false), 1) == false);
    try expect(all(boolx8(true, true, true, true, true, false, true, false), 0) == false);
    try expect(all(boolx4(false, true, false, false), 0) == false);
    try expect(all(boolx4(true, true, true, true), 0) == true);
}

pub fn any(vb: anytype, comptime len: u32) bool {
    const T = @TypeOf(vb);
    if (len > veclen(T)) {
        @compileError("zmath.any(): 'len' is greater than vector len of type " ++ @typeName(T));
    }
    comptime var loop_len = if (len == 0) veclen(T) else len;
    const ab: [veclen(T)]bool = vb;
    comptime var i: u32 = 0;
    var result = false;
    inline while (i < loop_len) : (i += 1) {
        result = result or ab[i];
    }
    return result;
}
test "zmath.any" {
    try expect(any(boolx8(true, true, true, true, true, false, true, false), 0) == true);
    try expect(any(boolx8(false, false, false, true, true, false, true, false), 3) == false);
    try expect(any(boolx8(false, false, false, false, false, true, false, false), 4) == false);
}

pub inline fn isNearEqual(
    v0: anytype,
    v1: anytype,
    epsilon: anytype,
) @Vector(veclen(@TypeOf(v0)), bool) {
    const T = @TypeOf(v0);
    const delta = v0 - v1;
    const temp = maxFast(delta, splat(T, 0.0) - delta);
    return temp <= epsilon;
}
test "zmath.isNearEqual" {
    {
        const v0 = f32x4(1.0, 2.0, -3.0, 4.001);
        const v1 = f32x4(1.0, 2.1, 3.0, 4.0);
        const b = isNearEqual(v0, v1, splat(F32x4, 0.01));
        try expect(@reduce(.And, b == Boolx4{ true, false, false, true }));
    }
    {
        const v0 = f32x8(1.0, 2.0, -3.0, 4.001, 1.001, 2.3, -0.0, 0.0);
        const v1 = f32x8(1.0, 2.1, 3.0, 4.0, -1.001, 2.1, 0.0, 0.0);
        const b = isNearEqual(v0, v1, splat(F32x8, 0.01));
        try expect(@reduce(.And, b == Boolx8{ true, false, false, true, false, false, true, true }));
    }
    try expect(all(isNearEqual(
        splat(F32x4, math.inf_f32),
        splat(F32x4, math.inf_f32),
        splat(F32x4, 0.0001),
    ), 0) == false);
    try expect(all(isNearEqual(
        splat(F32x4, -math.inf_f32),
        splat(F32x4, math.inf_f32),
        splat(F32x4, 0.0001),
    ), 0) == false);
    try expect(all(isNearEqual(
        splat(F32x4, -math.inf_f32),
        splat(F32x4, -math.inf_f32),
        splat(F32x4, 0.0001),
    ), 0) == false);
    try expect(all(isNearEqual(
        splat(F32x4, -math.nan_f32),
        splat(F32x4, math.inf_f32),
        splat(F32x4, 0.0001),
    ), 0) == false);
}

pub inline fn isNan(
    v: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    return v != v;
}
test "zmath.isNan" {
    {
        const v0 = F32x4{ math.inf_f32, math.nan_f32, math.qnan_f32, 7.0 };
        const b = isNan(v0);
        try expect(@reduce(.And, b == Boolx4{ false, true, true, false }));
    }
    {
        const v0 = F32x8{ 0, math.nan_f32, 0, 0, math.inf_f32, math.nan_f32, math.qnan_f32, 7.0 };
        const b = isNan(v0);
        try expect(@reduce(.And, b == Boolx8{ false, true, false, false, false, true, true, false }));
    }
}

pub inline fn isInf(
    v: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    const T = @TypeOf(v);
    return abs(v) == splat(T, math.inf_f32);
}
test "zmath.isInf" {
    {
        const v0 = f32x4(math.inf_f32, math.nan_f32, math.qnan_f32, 7.0);
        const b = isInf(v0);
        try expect(@reduce(.And, b == boolx4(true, false, false, false)));
    }
    {
        const v0 = f32x8(0, math.inf_f32, 0, 0, math.inf_f32, math.nan_f32, math.qnan_f32, 7.0);
        const b = isInf(v0);
        try expect(@reduce(.And, b == boolx8(false, true, false, false, true, false, false, false)));
    }
}

pub inline fn isInBounds(
    v: anytype,
    bounds: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    const T = @TypeOf(v);
    const Tu = @Vector(veclen(T), u1);
    const Tr = @Vector(veclen(T), bool);

    // 2 x cmpleps, xorps, load, andps
    const b0 = v <= bounds;
    const b1 = (bounds * splat(T, -1.0)) <= v;
    const b0u = @bitCast(Tu, b0);
    const b1u = @bitCast(Tu, b1);
    return @bitCast(Tr, b0u & b1u);
}
test "zmath.isInBounds" {
    {
        const v0 = f32x4(0.5, -2.0, -1.0, 1.9);
        const v1 = f32x4(-1.6, -2.001, -1.0, 1.9);
        const bounds = f32x4(1.0, 2.0, 1.0, 2.0);
        const b0 = isInBounds(v0, bounds);
        const b1 = isInBounds(v1, bounds);
        try expect(@reduce(.And, b0 == boolx4(true, true, true, true)));
        try expect(@reduce(.And, b1 == boolx4(false, false, true, true)));
    }
    {
        const v0 = f32x8(2.0, 1.0, 2.0, 1.0, 0.5, -2.0, -1.0, 1.9);
        const bounds = f32x8(1.0, 1.0, 1.0, math.inf_f32, 1.0, math.nan_f32, 1.0, 2.0);
        const b0 = isInBounds(v0, bounds);
        try expect(@reduce(.And, b0 == boolx8(false, true, false, true, true, false, true, true)));
    }
}

pub inline fn andInt(v0: anytype, v1: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @bitCast(Tu, v0);
    const v1u = @bitCast(Tu, v1);
    return @bitCast(T, v0u & v1u); // andps
}
test "zmath.andInt" {
    {
        const v0 = f32x4(0, @bitCast(f32, ~@as(u32, 0)), 0, @bitCast(f32, ~@as(u32, 0)));
        const v1 = f32x4(1.0, 2.0, 3.0, math.inf_f32);
        const v = andInt(v0, v1);
        try expect(v[3] == math.inf_f32);
        try expect(approxEqAbs(v, f32x4(0.0, 2.0, 0.0, math.inf_f32), 0.0));
    }
    {
        const v0 = f32x8(0, 0, 0, 0, 0, @bitCast(f32, ~@as(u32, 0)), 0, @bitCast(f32, ~@as(u32, 0)));
        const v1 = f32x8(0, 0, 0, 0, 1.0, 2.0, 3.0, math.inf_f32);
        const v = andInt(v0, v1);
        try expect(v[7] == math.inf_f32);
        try expect(approxEqAbs(v, f32x8(0, 0, 0, 0, 0.0, 2.0, 0.0, math.inf_f32), 0.0));
    }
}

pub inline fn andNotInt(v0: anytype, v1: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @bitCast(Tu, v0);
    const v1u = @bitCast(Tu, v1);
    return @bitCast(T, ~v0u & v1u); // andnps
}
test "zmath.andNotInt" {
    {
        const v0 = F32x4{ 1.0, 2.0, 3.0, 4.0 };
        const v1 = F32x4{ 0, @bitCast(f32, ~@as(u32, 0)), 0, @bitCast(f32, ~@as(u32, 0)) };
        const v = andNotInt(v1, v0);
        try expect(approxEqAbs(v, F32x4{ 1.0, 0.0, 3.0, 0.0 }, 0.0));
    }
    {
        const v0 = F32x8{ 0, 0, 0, 0, 1.0, 2.0, 3.0, 4.0 };
        const v1 = F32x8{ 0, 0, 0, 0, 0, @bitCast(f32, ~@as(u32, 0)), 0, @bitCast(f32, ~@as(u32, 0)) };
        const v = andNotInt(v1, v0);
        try expect(approxEqAbs(v, F32x8{ 0, 0, 0, 0, 1.0, 0.0, 3.0, 0.0 }, 0.0));
    }
}

pub inline fn orInt(v0: anytype, v1: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @bitCast(Tu, v0);
    const v1u = @bitCast(Tu, v1);
    return @bitCast(T, v0u | v1u); // orps
}
test "zmath.orInt" {
    {
        const v0 = F32x4{ 0, @bitCast(f32, ~@as(u32, 0)), 0, 0 };
        const v1 = F32x4{ 1.0, 2.0, 3.0, 4.0 };
        const v = orInt(v0, v1);
        try expect(v[0] == 1.0);
        try expect(@bitCast(u32, v[1]) == ~@as(u32, 0));
        try expect(v[2] == 3.0);
        try expect(v[3] == 4.0);
    }
    {
        const v0 = F32x8{ 0, 0, 0, 0, 0, @bitCast(f32, ~@as(u32, 0)), 0, 0 };
        const v1 = F32x8{ 0, 0, 0, 0, 1.0, 2.0, 3.0, 4.0 };
        const v = orInt(v0, v1);
        try expect(v[4] == 1.0);
        try expect(@bitCast(u32, v[5]) == ~@as(u32, 0));
        try expect(v[6] == 3.0);
        try expect(v[7] == 4.0);
    }
}

pub inline fn norInt(v0: anytype, v1: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @bitCast(Tu, v0);
    const v1u = @bitCast(Tu, v1);
    return @bitCast(T, ~(v0u | v1u)); // por, pcmpeqd, pxor
}

pub inline fn xorInt(v0: anytype, v1: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @bitCast(Tu, v0);
    const v1u = @bitCast(Tu, v1);
    return @bitCast(T, v0u ^ v1u); // xorps
}
test "zmath.xorInt" {
    {
        const v0 = F32x4{ 1.0, @bitCast(f32, ~@as(u32, 0)), 0, 0 };
        const v1 = F32x4{ 1.0, 0, 0, 0 };
        const v = xorInt(v0, v1);
        try expect(v[0] == 0.0);
        try expect(@bitCast(u32, v[1]) == ~@as(u32, 0));
        try expect(v[2] == 0.0);
        try expect(v[3] == 0.0);
    }
    {
        const v0 = F32x8{ 0, 0, 0, 0, 1.0, @bitCast(f32, ~@as(u32, 0)), 0, 0 };
        const v1 = F32x8{ 0, 0, 0, 0, 1.0, 0, 0, 0 };
        const v = xorInt(v0, v1);
        try expect(v[4] == 0.0);
        try expect(@bitCast(u32, v[5]) == ~@as(u32, 0));
        try expect(v[6] == 0.0);
        try expect(v[7] == 0.0);
    }
}

pub inline fn minFast(v0: anytype, v1: anytype) @TypeOf(v0) {
    return select(v0 < v1, v0, v1); // minps
}
test "zmath.minFast" {
    {
        const v0 = f32x4(1.0, 3.0, 2.0, 7.0);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = minFast(v0, v1);
        try expect(approxEqAbs(v, f32x4(1.0, 1.0, 2.0, 7.0), 0.0));
    }
    {
        const v0 = f32x4(1.0, math.nan_f32, 5.0, math.qnan_f32);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = minFast(v0, v1);
        try expect(v[0] == 1.0);
        try expect(v[1] == 1.0);
        try expect(!math.isNan(v[1]));
        try expect(v[2] == 4.0);
        try expect(v[3] == math.inf_f32);
        try expect(!math.isNan(v[3]));
    }
}

pub inline fn maxFast(v0: anytype, v1: anytype) @TypeOf(v0) {
    return select(v0 > v1, v0, v1); // maxps
}
test "zmath.maxFast" {
    {
        const v0 = f32x4(1.0, 3.0, 2.0, 7.0);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = maxFast(v0, v1);
        try expect(approxEqAbs(v, f32x4(2.0, 3.0, 4.0, math.inf_f32), 0.0));
    }
    {
        const v0 = f32x4(1.0, math.nan_f32, 5.0, math.qnan_f32);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = maxFast(v0, v1);
        try expect(v[0] == 2.0);
        try expect(v[1] == 1.0);
        try expect(v[2] == 5.0);
        try expect(v[3] == math.inf_f32);
        try expect(!math.isNan(v[3]));
    }
}

pub inline fn min(v0: anytype, v1: anytype) @TypeOf(v0) {
    // This will handle inf & nan
    return @minimum(v0, v1); // minps, cmpunordps, andps, andnps, orps
}
test "zmath.min" {
    {
        const v0 = f32x4(1.0, 3.0, 2.0, 7.0);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = min(v0, v1);
        try expect(approxEqAbs(v, f32x4(1.0, 1.0, 2.0, 7.0), 0.0));
    }
    {
        const v0 = f32x8(0, 0, -2.0, 0, 1.0, 3.0, 2.0, 7.0);
        const v1 = f32x8(0, 1.0, 0, 0, 2.0, 1.0, 4.0, math.inf_f32);
        const v = min(v0, v1);
        try expect(approxEqAbs(v, f32x8(0.0, 0.0, -2.0, 0.0, 1.0, 1.0, 2.0, 7.0), 0.0));
    }
    {
        const v0 = f32x4(1.0, math.nan_f32, 5.0, math.qnan_f32);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = min(v0, v1);
        try expect(v[0] == 1.0);
        try expect(v[1] == 1.0);
        try expect(!math.isNan(v[1]));
        try expect(v[2] == 4.0);
        try expect(v[3] == math.inf_f32);
        try expect(!math.isNan(v[3]));
    }
    {
        const v0 = f32x4(-math.inf_f32, math.inf_f32, math.inf_f32, math.qnan_f32);
        const v1 = f32x4(math.qnan_f32, -math.inf_f32, math.qnan_f32, math.nan_f32);
        const v = min(v0, v1);
        try expect(v[0] == -math.inf_f32);
        try expect(v[1] == -math.inf_f32);
        try expect(v[2] == math.inf_f32);
        try expect(!math.isNan(v[2]));
        try expect(math.isNan(v[3]));
        try expect(!math.isInf(v[3]));
    }
}

pub inline fn max(v0: anytype, v1: anytype) @TypeOf(v0) {
    // This will handle inf & nan
    return @maximum(v0, v1); // maxps, cmpunordps, andps, andnps, orps
}
test "zmath.max" {
    {
        const v0 = f32x4(1.0, 3.0, 2.0, 7.0);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = max(v0, v1);
        try expect(approxEqAbs(v, f32x4(2.0, 3.0, 4.0, math.inf_f32), 0.0));
    }
    {
        const v0 = f32x8(0, 0, -2.0, 0, 1.0, 3.0, 2.0, 7.0);
        const v1 = f32x8(0, 1.0, 0, 0, 2.0, 1.0, 4.0, math.inf_f32);
        const v = max(v0, v1);
        try expect(approxEqAbs(v, f32x8(0.0, 1.0, 0.0, 0.0, 2.0, 3.0, 4.0, math.inf_f32), 0.0));
    }
    {
        const v0 = f32x4(1.0, math.nan_f32, 5.0, math.qnan_f32);
        const v1 = f32x4(2.0, 1.0, 4.0, math.inf_f32);
        const v = max(v0, v1);
        try expect(v[0] == 2.0);
        try expect(v[1] == 1.0);
        try expect(v[2] == 5.0);
        try expect(v[3] == math.inf_f32);
        try expect(!math.isNan(v[3]));
    }
    {
        const v0 = f32x4(-math.inf_f32, math.inf_f32, math.inf_f32, math.qnan_f32);
        const v1 = f32x4(math.qnan_f32, -math.inf_f32, math.qnan_f32, math.nan_f32);
        const v = max(v0, v1);
        try expect(v[0] == -math.inf_f32);
        try expect(v[1] == math.inf_f32);
        try expect(v[2] == math.inf_f32);
        try expect(!math.isNan(v[2]));
        try expect(math.isNan(v[3]));
        try expect(!math.isInf(v[3]));
    }
}

pub fn round(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    if (cpu_arch == .x86_64 and has_avx) {
        if (T == F32x4) {
            return asm ("vroundps $0, %%xmm0, %%xmm0"
                : [ret] "={xmm0}" (-> T),
                : [v] "{xmm0}" (v),
            );
        } else if (T == F32x8) {
            return asm ("vroundps $0, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> T),
                : [v] "{ymm0}" (v),
            );
        } else if (T == F32x16 and has_avx512f) {
            return asm ("vrndscaleps $0, %%zmm0, %%zmm0"
                : [ret] "={zmm0}" (-> T),
                : [v] "{zmm0}" (v),
            );
        } else if (T == F32x16 and !has_avx512f) {
            const arr: [16]f32 = v;
            var ymm0 = @as(F32x8, arr[0..8].*);
            var ymm1 = @as(F32x8, arr[8..16].*);
            ymm0 = asm ("vroundps $0, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> F32x8),
                : [v] "{ymm0}" (ymm0),
            );
            ymm1 = asm ("vroundps $0, %%ymm1, %%ymm1"
                : [ret] "={ymm1}" (-> F32x8),
                : [v] "{ymm1}" (ymm1),
            );
            return @shuffle(f32, ymm0, ymm1, [16]i32{ 0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, -5, -6, -7, -8 });
        }
    } else {
        const sign = andInt(v, splatNegativeZero(T));
        const magic = orInt(splatNoFraction(T), sign);
        var r1 = v + magic;
        r1 = r1 - magic;
        const r2 = abs(v);
        const mask = r2 <= splatNoFraction(T);
        return select(mask, r1, v);
    }
}
test "zmath.round" {
    {
        try expect(all(round(splat(F32x4, math.inf_f32)) == splat(F32x4, math.inf_f32), 0));
        try expect(all(round(splat(F32x4, -math.inf_f32)) == splat(F32x4, -math.inf_f32), 0));
        try expect(all(isNan(round(splat(F32x4, math.nan_f32))), 0));
        try expect(all(isNan(round(splat(F32x4, -math.nan_f32))), 0));
        try expect(all(isNan(round(splat(F32x4, math.qnan_f32))), 0));
        try expect(all(isNan(round(splat(F32x4, -math.qnan_f32))), 0));
    }
    {
        var v = round(F32x16{ 1.1, -1.1, -1.5, 1.5, 2.1, 2.8, 2.9, 4.1, 5.8, 6.1, 7.9, 8.9, 10.1, 11.2, 12.7, 13.1 });
        try expect(approxEqAbs(
            v,
            F32x16{ 1.0, -1.0, -2.0, 2.0, 2.0, 3.0, 3.0, 4.0, 6.0, 6.0, 8.0, 9.0, 10.0, 11.0, 13.0, 13.0 },
            0.0,
        ));
    }
    var v = round(F32x4{ 1.1, -1.1, -1.5, 1.5 });
    try expect(approxEqAbs(v, F32x4{ 1.0, -1.0, -2.0, 2.0 }, 0.0));

    const v1 = F32x4{ -10_000_000.1, -math.inf_f32, 10_000_001.5, math.inf_f32 };
    v = round(v1);
    try expect(v[3] == math.inf_f32);
    try expect(approxEqAbs(v, F32x4{ -10_000_000.1, -math.inf_f32, 10_000_001.5, math.inf_f32 }, 0.0));

    const v2 = F32x4{ -math.qnan_f32, math.qnan_f32, math.nan_f32, -math.inf_f32 };
    v = round(v2);
    try expect(math.isNan(v2[0]));
    try expect(math.isNan(v2[1]));
    try expect(math.isNan(v2[2]));
    try expect(v2[3] == -math.inf_f32);

    const v3 = F32x4{ 1001.5, -201.499, -10000.99, -101.5 };
    v = round(v3);
    try expect(approxEqAbs(v, F32x4{ 1002.0, -201.0, -10001.0, -102.0 }, 0.0));

    const v4 = F32x4{ -1_388_609.9, 1_388_609.5, 1_388_109.01, 2_388_609.5 };
    v = round(v4);
    try expect(approxEqAbs(v, F32x4{ -1_388_610.0, 1_388_610.0, 1_388_109.0, 2_388_610.0 }, 0.0));

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = round(splat(F32x4, f));
        const fr = @round(splat(F32x4, f));
        const vr8 = round(splat(F32x8, f));
        const fr8 = @round(splat(F32x8, f));
        const vr16 = round(splat(F32x16, f));
        const fr16 = @round(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, 0.0));
        try expect(approxEqAbs(vr8, fr8, 0.0));
        try expect(approxEqAbs(vr16, fr16, 0.0));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

pub fn trunc(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    if (cpu_arch == .x86_64 and has_avx) {
        if (T == F32x4) {
            return asm ("vroundps $3, %%xmm0, %%xmm0"
                : [ret] "={xmm0}" (-> T),
                : [v] "{xmm0}" (v),
            );
        } else if (T == F32x8) {
            return asm ("vroundps $3, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> T),
                : [v] "{ymm0}" (v),
            );
        } else if (T == F32x16 and has_avx512f) {
            return asm ("vrndscaleps $3, %%zmm0, %%zmm0"
                : [ret] "={zmm0}" (-> T),
                : [v] "{zmm0}" (v),
            );
        } else if (T == F32x16 and !has_avx512f) {
            const arr: [16]f32 = v;
            var ymm0 = @as(F32x8, arr[0..8].*);
            var ymm1 = @as(F32x8, arr[8..16].*);
            ymm0 = asm ("vroundps $3, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> F32x8),
                : [v] "{ymm0}" (ymm0),
            );
            ymm1 = asm ("vroundps $3, %%ymm1, %%ymm1"
                : [ret] "={ymm1}" (-> F32x8),
                : [v] "{ymm1}" (ymm1),
            );
            return @shuffle(f32, ymm0, ymm1, [16]i32{ 0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, -5, -6, -7, -8 });
        }
    } else {
        const mask = abs(v) < splatNoFraction(T);
        const result = floatToIntAndBack(v);
        return select(mask, result, v);
    }
}
test "zmath.trunc" {
    {
        try expect(all(trunc(splat(F32x4, math.inf_f32)) == splat(F32x4, math.inf_f32), 0));
        try expect(all(trunc(splat(F32x4, -math.inf_f32)) == splat(F32x4, -math.inf_f32), 0));
        try expect(all(isNan(trunc(splat(F32x4, math.nan_f32))), 0));
        try expect(all(isNan(trunc(splat(F32x4, -math.nan_f32))), 0));
        try expect(all(isNan(trunc(splat(F32x4, math.qnan_f32))), 0));
        try expect(all(isNan(trunc(splat(F32x4, -math.qnan_f32))), 0));
    }
    {
        var v = trunc(F32x16{ 1.1, -1.1, -1.5, 1.5, 2.1, 2.8, 2.9, 4.1, 5.8, 6.1, 7.9, 8.9, 10.1, 11.2, 12.7, 13.1 });
        try expect(approxEqAbs(
            v,
            F32x16{ 1.0, -1.0, -1.0, 1.0, 2.0, 2.0, 2.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0, 11.0, 12.0, 13.0 },
            0.0,
        ));
    }
    var v = trunc(F32x4{ 1.1, -1.1, -1.5, 1.5 });
    try expect(approxEqAbs(v, F32x4{ 1.0, -1.0, -1.0, 1.0 }, 0.0));

    v = trunc(F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 });
    try expect(approxEqAbs(v, F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 }, 0.0));

    v = trunc(F32x4{ -math.qnan_f32, math.qnan_f32, math.nan_f32, -math.inf_f32 });
    try expect(math.isNan(v[0]));
    try expect(math.isNan(v[1]));
    try expect(math.isNan(v[2]));
    try expect(v[3] == -math.inf_f32);

    v = trunc(F32x4{ 1000.5001, -201.499, -10000.99, 100.750001 });
    try expect(approxEqAbs(v, F32x4{ 1000.0, -201.0, -10000.0, 100.0 }, 0.0));

    v = trunc(F32x4{ -7_388_609.5, 7_388_609.1, 8_388_109.5, -8_388_509.5 });
    try expect(approxEqAbs(v, F32x4{ -7_388_609.0, 7_388_609.0, 8_388_109.0, -8_388_509.0 }, 0.0));

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = trunc(splat(F32x4, f));
        const fr = @trunc(splat(F32x4, f));
        const vr8 = trunc(splat(F32x8, f));
        const fr8 = @trunc(splat(F32x8, f));
        const vr16 = trunc(splat(F32x16, f));
        const fr16 = @trunc(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, 0.0));
        try expect(approxEqAbs(vr8, fr8, 0.0));
        try expect(approxEqAbs(vr16, fr16, 0.0));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

pub fn floor(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    if (cpu_arch == .x86_64 and has_avx) {
        if (T == F32x4) {
            return asm ("vroundps $1, %%xmm0, %%xmm0"
                : [ret] "={xmm0}" (-> T),
                : [v] "{xmm0}" (v),
            );
        } else if (T == F32x8) {
            return asm ("vroundps $1, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> T),
                : [v] "{ymm0}" (v),
            );
        } else if (T == F32x16 and has_avx512f) {
            return asm ("vrndscaleps $1, %%zmm0, %%zmm0"
                : [ret] "={zmm0}" (-> T),
                : [v] "{zmm0}" (v),
            );
        } else if (T == F32x16 and !has_avx512f) {
            const arr: [16]f32 = v;
            var ymm0 = @as(F32x8, arr[0..8].*);
            var ymm1 = @as(F32x8, arr[8..16].*);
            ymm0 = asm ("vroundps $1, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> F32x8),
                : [v] "{ymm0}" (ymm0),
            );
            ymm1 = asm ("vroundps $1, %%ymm1, %%ymm1"
                : [ret] "={ymm1}" (-> F32x8),
                : [v] "{ymm1}" (ymm1),
            );
            return @shuffle(f32, ymm0, ymm1, [16]i32{ 0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, -5, -6, -7, -8 });
        }
    } else {
        const mask = abs(v) < splatNoFraction(T);
        var result = floatToIntAndBack(v);
        const larger_mask = result > v;
        const larger = select(larger_mask, splat(T, -1.0), splat(T, 0.0));
        result = result + larger;
        return select(mask, result, v);
    }
}
test "zmath.floor" {
    {
        try expect(all(floor(splat(F32x4, math.inf_f32)) == splat(F32x4, math.inf_f32), 0));
        try expect(all(floor(splat(F32x4, -math.inf_f32)) == splat(F32x4, -math.inf_f32), 0));
        try expect(all(isNan(floor(splat(F32x4, math.nan_f32))), 0));
        try expect(all(isNan(floor(splat(F32x4, -math.nan_f32))), 0));
        try expect(all(isNan(floor(splat(F32x4, math.qnan_f32))), 0));
        try expect(all(isNan(floor(splat(F32x4, -math.qnan_f32))), 0));
    }
    {
        var v = floor(F32x16{ 1.1, -1.1, -1.5, 1.5, 2.1, 2.8, 2.9, 4.1, 5.8, 6.1, 7.9, 8.9, 10.1, 11.2, 12.7, 13.1 });
        try expect(approxEqAbs(
            v,
            F32x16{ 1.0, -2.0, -2.0, 1.0, 2.0, 2.0, 2.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0, 11.0, 12.0, 13.0 },
            0.0,
        ));
    }
    var v = floor(F32x4{ 1.5, -1.5, -1.7, -2.1 });
    try expect(approxEqAbs(v, F32x4{ 1.0, -2.0, -2.0, -3.0 }, 0.0));

    v = floor(F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 });
    try expect(approxEqAbs(v, F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 }, 0.0));

    v = floor(F32x4{ -math.qnan_f32, math.qnan_f32, math.nan_f32, -math.inf_f32 });
    try expect(math.isNan(v[0]));
    try expect(math.isNan(v[1]));
    try expect(math.isNan(v[2]));
    try expect(v[3] == -math.inf_f32);

    v = floor(F32x4{ 1000.5001, -201.499, -10000.99, 100.75001 });
    try expect(approxEqAbs(v, F32x4{ 1000.0, -202.0, -10001.0, 100.0 }, 0.0));

    v = floor(F32x4{ -7_388_609.5, 7_388_609.1, 8_388_109.5, -8_388_509.5 });
    try expect(approxEqAbs(v, F32x4{ -7_388_610.0, 7_388_609.0, 8_388_109.0, -8_388_510.0 }, 0.0));

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = floor(splat(F32x4, f));
        const fr = @floor(splat(F32x4, f));
        const vr8 = floor(splat(F32x8, f));
        const fr8 = @floor(splat(F32x8, f));
        const vr16 = floor(splat(F32x16, f));
        const fr16 = @floor(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, 0.0));
        try expect(approxEqAbs(vr8, fr8, 0.0));
        try expect(approxEqAbs(vr16, fr16, 0.0));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

pub fn ceil(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    if (cpu_arch == .x86_64 and has_avx) {
        if (T == F32x4) {
            return asm ("vroundps $2, %%xmm0, %%xmm0"
                : [ret] "={xmm0}" (-> T),
                : [v] "{xmm0}" (v),
            );
        } else if (T == F32x8) {
            return asm ("vroundps $2, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> T),
                : [v] "{ymm0}" (v),
            );
        } else if (T == F32x16 and has_avx512f) {
            return asm ("vrndscaleps $2, %%zmm0, %%zmm0"
                : [ret] "={zmm0}" (-> T),
                : [v] "{zmm0}" (v),
            );
        } else if (T == F32x16 and !has_avx512f) {
            const arr: [16]f32 = v;
            var ymm0 = @as(F32x8, arr[0..8].*);
            var ymm1 = @as(F32x8, arr[8..16].*);
            ymm0 = asm ("vroundps $2, %%ymm0, %%ymm0"
                : [ret] "={ymm0}" (-> F32x8),
                : [v] "{ymm0}" (ymm0),
            );
            ymm1 = asm ("vroundps $2, %%ymm1, %%ymm1"
                : [ret] "={ymm1}" (-> F32x8),
                : [v] "{ymm1}" (ymm1),
            );
            return @shuffle(f32, ymm0, ymm1, [16]i32{ 0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, -5, -6, -7, -8 });
        }
    } else {
        const mask = abs(v) < splatNoFraction(T);
        var result = floatToIntAndBack(v);
        const smaller_mask = result < v;
        const smaller = select(smaller_mask, splat(T, -1.0), splat(T, 0.0));
        result = result - smaller;
        return select(mask, result, v);
    }
}
test "zmath.ceil" {
    {
        try expect(all(ceil(splat(F32x4, math.inf_f32)) == splat(F32x4, math.inf_f32), 0));
        try expect(all(ceil(splat(F32x4, -math.inf_f32)) == splat(F32x4, -math.inf_f32), 0));
        try expect(all(isNan(ceil(splat(F32x4, math.nan_f32))), 0));
        try expect(all(isNan(ceil(splat(F32x4, -math.nan_f32))), 0));
        try expect(all(isNan(ceil(splat(F32x4, math.qnan_f32))), 0));
        try expect(all(isNan(ceil(splat(F32x4, -math.qnan_f32))), 0));
    }
    {
        var v = ceil(F32x16{ 1.1, -1.1, -1.5, 1.5, 2.1, 2.8, 2.9, 4.1, 5.8, 6.1, 7.9, 8.9, 10.1, 11.2, 12.7, 13.1 });
        try expect(approxEqAbs(
            v,
            F32x16{ 2.0, -1.0, -1.0, 2.0, 3.0, 3.0, 3.0, 5.0, 6.0, 7.0, 8.0, 9.0, 11.0, 12.0, 13.0, 14.0 },
            0.0,
        ));
    }
    var v = ceil(F32x4{ 1.5, -1.5, -1.7, -2.1 });
    try expect(approxEqAbs(v, F32x4{ 2.0, -1.0, -1.0, -2.0 }, 0.0));

    v = ceil(F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 });
    try expect(approxEqAbs(v, F32x4{ -10_000_002.1, -math.inf_f32, 10_000_001.5, math.inf_f32 }, 0.0));

    v = ceil(F32x4{ -math.qnan_f32, math.qnan_f32, math.nan_f32, -math.inf_f32 });
    try expect(math.isNan(v[0]));
    try expect(math.isNan(v[1]));
    try expect(math.isNan(v[2]));
    try expect(v[3] == -math.inf_f32);

    v = ceil(F32x4{ 1000.5001, -201.499, -10000.99, 100.75001 });
    try expect(approxEqAbs(v, F32x4{ 1001.0, -201.0, -10000.0, 101.0 }, 0.0));

    v = ceil(F32x4{ -1_388_609.5, 1_388_609.1, 1_388_109.9, -1_388_509.9 });
    try expect(approxEqAbs(v, F32x4{ -1_388_609.0, 1_388_610.0, 1_388_110.0, -1_388_509.0 }, 0.0));

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = ceil(splat(F32x4, f));
        const fr = @ceil(splat(F32x4, f));
        const vr8 = ceil(splat(F32x8, f));
        const fr8 = @ceil(splat(F32x8, f));
        const vr16 = ceil(splat(F32x16, f));
        const fr16 = @ceil(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, 0.0));
        try expect(approxEqAbs(vr8, fr8, 0.0));
        try expect(approxEqAbs(vr16, fr16, 0.0));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

pub inline fn clamp(v: anytype, vmin: anytype, vmax: anytype) @TypeOf(v) {
    var result = max(vmin, v);
    result = min(vmax, result);
    return result;
}
test "zmath.clamp" {
    {
        const v0 = f32x4(-1.0, 0.2, 1.1, -0.3);
        const v = clamp(v0, splat(F32x4, -0.5), splat(F32x4, 0.5));
        try expect(approxEqAbs(v, f32x4(-0.5, 0.2, 0.5, -0.3), 0.0001));
    }
    {
        const v0 = f32x8(-2.0, 0.25, -0.25, 100.0, -1.0, 0.2, 1.1, -0.3);
        const v = clamp(v0, splat(F32x8, -0.5), splat(F32x8, 0.5));
        try expect(approxEqAbs(v, f32x8(-0.5, 0.25, -0.25, 0.5, -0.5, 0.2, 0.5, -0.3), 0.0001));
    }
    {
        const v0 = f32x4(-math.inf_f32, math.inf_f32, math.nan_f32, math.qnan_f32);
        const v = clamp(v0, f32x4(-100.0, 0.0, -100.0, 0.0), f32x4(0.0, 100.0, 0.0, 100.0));
        try expect(approxEqAbs(v, f32x4(-100.0, 100.0, -100.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x4(math.inf_f32, math.inf_f32, -math.nan_f32, -math.qnan_f32);
        const v = clamp(v0, splat(F32x4, -1.0), splat(F32x4, 1.0));
        try expect(approxEqAbs(v, f32x4(1.0, 1.0, -1.0, -1.0), 0.0001));
    }
}

pub inline fn clampFast(v: anytype, vmin: anytype, vmax: anytype) @TypeOf(v) {
    var result = maxFast(vmin, v);
    result = minFast(vmax, result);
    return result;
}
test "zmath.clampFast" {
    {
        const v0 = f32x4(-1.0, 0.2, 1.1, -0.3);
        const v = clampFast(v0, splat(F32x4, -0.5), splat(F32x4, 0.5));
        try expect(approxEqAbs(v, f32x4(-0.5, 0.2, 0.5, -0.3), 0.0001));
    }
}

pub inline fn saturate(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    var result = max(v, splat(T, 0.0));
    result = min(result, splat(T, 1.0));
    return result;
}
test "zmath.saturate" {
    {
        const v0 = f32x4(-1.0, 0.2, 1.1, -0.3);
        const v = saturate(v0);
        try expect(approxEqAbs(v, f32x4(0.0, 0.2, 1.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x8(0.0, 0.0, 2.0, -2.0, -1.0, 0.2, 1.1, -0.3);
        const v = saturate(v0);
        try expect(approxEqAbs(v, f32x8(0.0, 0.0, 1.0, 0.0, 0.0, 0.2, 1.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x4(-math.inf_f32, math.inf_f32, math.nan_f32, math.qnan_f32);
        const v = saturate(v0);
        try expect(approxEqAbs(v, f32x4(0.0, 1.0, 0.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x4(math.inf_f32, math.inf_f32, -math.nan_f32, -math.qnan_f32);
        const v = saturate(v0);
        try expect(approxEqAbs(v, f32x4(1.0, 1.0, 0.0, 0.0), 0.0001));
    }
}

pub inline fn saturateFast(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    var result = maxFast(v, splat(T, 0.0));
    result = minFast(result, splat(T, 1.0));
    return result;
}
test "zmath.saturateFast" {
    {
        const v0 = f32x4(-1.0, 0.2, 1.1, -0.3);
        const v = saturateFast(v0);
        try expect(approxEqAbs(v, f32x4(0.0, 0.2, 1.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x8(0.0, 0.0, 2.0, -2.0, -1.0, 0.2, 1.1, -0.3);
        const v = saturateFast(v0);
        try expect(approxEqAbs(v, f32x8(0.0, 0.0, 1.0, 0.0, 0.0, 0.2, 1.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x4(-math.inf_f32, math.inf_f32, math.nan_f32, math.qnan_f32);
        const v = saturateFast(v0);
        try expect(approxEqAbs(v, f32x4(0.0, 1.0, 0.0, 0.0), 0.0001));
    }
    {
        const v0 = f32x4(math.inf_f32, math.inf_f32, -math.nan_f32, -math.qnan_f32);
        const v = saturateFast(v0);
        try expect(approxEqAbs(v, f32x4(1.0, 1.0, 0.0, 0.0), 0.0001));
    }
}

pub inline fn sqrt(v: anytype) @TypeOf(v) {
    return @sqrt(v); // sqrtps
}

pub inline fn abs(v: anytype) @TypeOf(v) {
    return @fabs(v); // load, andps
}

pub inline fn select(mask: anytype, v0: anytype, v1: anytype) @TypeOf(v0) {
    return @select(f32, mask, v0, v1);
}

pub inline fn lerp(v0: anytype, v1: anytype, t: f32) @TypeOf(v0) {
    const T = @TypeOf(v0);
    return v0 + (v1 - v0) * splat(T, t); // subps, shufps, addps, mulps
}

pub inline fn lerpV(v0: anytype, v1: anytype, t: anytype) @TypeOf(v0) {
    return v0 + (v1 - v0) * t; // subps, addps, mulps
}

pub const F32x4Component = enum { x, y, z, w };

pub inline fn swizzle(
    v: F32x4,
    comptime x: F32x4Component,
    comptime y: F32x4Component,
    comptime z: F32x4Component,
    comptime w: F32x4Component,
) F32x4 {
    return @shuffle(f32, v, undefined, [4]i32{ @enumToInt(x), @enumToInt(y), @enumToInt(z), @enumToInt(w) });
}

pub inline fn mod(v0: anytype, v1: anytype) @TypeOf(v0) {
    // vdivps, vroundps, vmulps, vsubps
    return v0 - v1 * trunc(v0 / v1);
}
test "zmath.mod" {
    try expect(approxEqAbs(mod(splat(F32x4, 3.1), splat(F32x4, 1.7)), splat(F32x4, 1.4), 0.0005));
    try expect(approxEqAbs(mod(splat(F32x4, -3.0), splat(F32x4, 2.0)), splat(F32x4, -1.0), 0.0005));
    try expect(approxEqAbs(mod(splat(F32x4, -3.0), splat(F32x4, -2.0)), splat(F32x4, -1.0), 0.0005));
    try expect(approxEqAbs(mod(splat(F32x4, 3.0), splat(F32x4, -2.0)), splat(F32x4, 1.0), 0.0005));
    try expect(all(isNan(mod(splat(F32x4, math.inf_f32), splat(F32x4, 1.0))), 0));
    try expect(all(isNan(mod(splat(F32x4, -math.inf_f32), splat(F32x4, 123.456))), 0));
    try expect(all(isNan(mod(splat(F32x4, math.nan_f32), splat(F32x4, 123.456))), 0));
    try expect(all(isNan(mod(splat(F32x4, math.qnan_f32), splat(F32x4, 123.456))), 0));
    try expect(all(isNan(mod(splat(F32x4, -math.qnan_f32), splat(F32x4, 123.456))), 0));
    try expect(all(isNan(mod(splat(F32x4, 123.456), splat(F32x4, math.inf_f32))), 0));
    try expect(all(isNan(mod(splat(F32x4, 123.456), splat(F32x4, -math.inf_f32))), 0));
    try expect(all(isNan(mod(splat(F32x4, 123.456), splat(F32x4, math.nan_f32))), 0));
    try expect(all(isNan(mod(splat(F32x4, math.inf_f32), splat(F32x4, math.inf_f32))), 0));
    try expect(all(isNan(mod(splat(F32x4, math.inf_f32), splat(F32x4, math.nan_f32))), 0));
}

pub fn modAngle(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => modAngle32(v),
        F32x4, F32x8, F32x16 => modAngle32xN(v),
        else => @compileError("zmath.modAngle() not implemented for " ++ @typeName(T)),
    };
}

pub inline fn modAngle32xN(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return v - splat(T, math.tau) * round(v * splat(T, 1.0 / math.tau)); // 2 x vmulps, 2 x load, vroundps, vaddps
}
test "zmath.modAngle" {
    try expect(approxEqAbs(modAngle(splat(F32x4, math.tau)), splat(F32x4, 0.0), 0.0005));
    try expect(approxEqAbs(modAngle(splat(F32x4, 0.0)), splat(F32x4, 0.0), 0.0005));
    try expect(approxEqAbs(modAngle(splat(F32x4, math.pi)), splat(F32x4, math.pi), 0.0005));
    try expect(approxEqAbs(modAngle(splat(F32x4, 11 * math.pi)), splat(F32x4, math.pi), 0.0005));
    try expect(approxEqAbs(modAngle(splat(F32x4, 3.5 * math.pi)), splat(F32x4, -0.5 * math.pi), 0.0005));
    try expect(approxEqAbs(modAngle(splat(F32x4, 2.5 * math.pi)), splat(F32x4, 0.5 * math.pi), 0.0005));
}

pub inline fn mulAdd(v0: anytype, v1: anytype, v2: anytype) @TypeOf(v0) {
    const T = @TypeOf(v0);
    if (cpu_arch == .x86_64 and has_avx and has_fma) {
        return @mulAdd(T, v0, v1, v2);
    } else {
        // NOTE(mziulek): On .x86_64 without HW fma instructions @mulAdd maps to really slow code!
        return v0 * v1 + v2;
    }
}

fn sin32xN(v: anytype) @TypeOf(v) {
    // 11-degree minimax approximation
    const T = @TypeOf(v);

    var x = modAngle(v);
    const sign = andInt(x, splatNegativeZero(T));
    const c = orInt(sign, splat(T, math.pi));
    const absx = andNotInt(sign, x);
    const rflx = c - x;
    const comp = absx <= splat(T, 0.5 * math.pi);
    x = select(comp, x, rflx);
    const x2 = x * x;

    var result = mulAdd(splat(T, -2.3889859e-08), x2, splat(T, 2.7525562e-06));
    result = mulAdd(result, x2, splat(T, -0.00019840874));
    result = mulAdd(result, x2, splat(T, 0.0083333310));
    result = mulAdd(result, x2, splat(T, -0.16666667));
    result = mulAdd(result, x2, splat(T, 1.0));
    return x * result;
}
test "sin" {
    const epsilon = 0.0001;

    try expect(approxEqAbs(sin(splat(F32x4, 0.5 * math.pi)), splat(F32x4, 1.0), epsilon));
    try expect(approxEqAbs(sin(splat(F32x4, 0.0)), splat(F32x4, 0.0), epsilon));
    try expect(approxEqAbs(sin(splat(F32x4, -0.0)), splat(F32x4, -0.0), epsilon));
    try expect(approxEqAbs(sin(splat(F32x4, 89.123)), splat(F32x4, 0.916166), epsilon));
    try expect(approxEqAbs(sin(splat(F32x8, 89.123)), splat(F32x8, 0.916166), epsilon));
    try expect(approxEqAbs(sin(splat(F32x16, 89.123)), splat(F32x16, 0.916166), epsilon));
    try expect(all(isNan(sin(splat(F32x4, math.inf_f32))), 0) == true);
    try expect(all(isNan(sin(splat(F32x4, -math.inf_f32))), 0) == true);
    try expect(all(isNan(sin(splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(sin(splat(F32x4, math.qnan_f32))), 0) == true);

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = sin(splat(F32x4, f));
        const fr = @sin(splat(F32x4, f));
        const vr8 = sin(splat(F32x8, f));
        const fr8 = @sin(splat(F32x8, f));
        const vr16 = sin(splat(F32x16, f));
        const fr16 = @sin(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, epsilon));
        try expect(approxEqAbs(vr8, fr8, epsilon));
        try expect(approxEqAbs(vr16, fr16, epsilon));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

fn cos32xN(v: anytype) @TypeOf(v) {
    // 10-degree minimax approximation
    const T = @TypeOf(v);

    var x = modAngle(v);
    var sign = andInt(x, splatNegativeZero(T));
    const c = orInt(sign, splat(T, math.pi));
    const absx = andNotInt(sign, x);
    const rflx = c - x;
    const comp = absx <= splat(T, 0.5 * math.pi);
    x = select(comp, x, rflx);
    sign = select(comp, splat(T, 1.0), splat(T, -1.0));
    const x2 = x * x;

    var result = mulAdd(splat(T, -2.6051615e-07), x2, splat(T, 2.4760495e-05));
    result = mulAdd(result, x2, splat(T, -0.0013888378));
    result = mulAdd(result, x2, splat(T, 0.041666638));
    result = mulAdd(result, x2, splat(T, -0.5));
    result = mulAdd(result, x2, splat(T, 1.0));
    return sign * result;
}
test "zmath.cos" {
    const epsilon = 0.0001;

    try expect(approxEqAbs(cos(splat(F32x4, 0.5 * math.pi)), splat(F32x4, 0.0), epsilon));
    try expect(approxEqAbs(cos(splat(F32x4, 0.0)), splat(F32x4, 1.0), epsilon));
    try expect(approxEqAbs(cos(splat(F32x4, -0.0)), splat(F32x4, 1.0), epsilon));
    try expect(all(isNan(cos(splat(F32x4, math.inf_f32))), 0) == true);
    try expect(all(isNan(cos(splat(F32x4, -math.inf_f32))), 0) == true);
    try expect(all(isNan(cos(splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(cos(splat(F32x4, math.qnan_f32))), 0) == true);

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const vr = cos(splat(F32x4, f));
        const fr = @cos(splat(F32x4, f));
        const vr8 = cos(splat(F32x8, f));
        const fr8 = @cos(splat(F32x8, f));
        const vr16 = cos(splat(F32x16, f));
        const fr16 = @cos(splat(F32x16, f));
        try expect(approxEqAbs(vr, fr, epsilon));
        try expect(approxEqAbs(vr8, fr8, epsilon));
        try expect(approxEqAbs(vr16, fr16, epsilon));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

pub fn sin(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => sin32(v),
        F32x4, F32x8, F32x16 => sin32xN(v),
        else => @compileError("zmath.sin() not implemented for " ++ @typeName(T)),
    };
}

pub fn cos(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => cos32(v),
        F32x4, F32x8, F32x16 => cos32xN(v),
        else => @compileError("zmath.cos() not implemented for " ++ @typeName(T)),
    };
}

pub fn sincos(v: anytype) [2]@TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => sincos32(v),
        F32x4, F32x8, F32x16 => sincos32xN(v),
        else => @compileError("zmath.sincos() not implemented for " ++ @typeName(T)),
    };
}

pub fn asin(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => asin32(v),
        F32x4, F32x8, F32x16 => asin32xN(v),
        else => @compileError("zmath.asin() not implemented for " ++ @typeName(T)),
    };
}

pub fn acos(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => acos32(v),
        F32x4, F32x8, F32x16 => acos32xN(v),
        else => @compileError("zmath.acos() not implemented for " ++ @typeName(T)),
    };
}

fn sincos32xN(v: anytype) [2]@TypeOf(v) {
    const T = @TypeOf(v);

    var x = modAngle(v);
    var sign = andInt(x, splatNegativeZero(T));
    const c = orInt(sign, splat(T, math.pi));
    const absx = andNotInt(sign, x);
    const rflx = c - x;
    const comp = absx <= splat(T, 0.5 * math.pi);
    x = select(comp, x, rflx);
    sign = select(comp, splat(T, 1.0), splat(T, -1.0));
    const x2 = x * x;

    var sresult = mulAdd(splat(T, -2.3889859e-08), x2, splat(T, 2.7525562e-06));
    sresult = mulAdd(sresult, x2, splat(T, -0.00019840874));
    sresult = mulAdd(sresult, x2, splat(T, 0.0083333310));
    sresult = mulAdd(sresult, x2, splat(T, -0.16666667));
    sresult = x * mulAdd(sresult, x2, splat(T, 1.0));

    var cresult = mulAdd(splat(T, -2.6051615e-07), x2, splat(T, 2.4760495e-05));
    cresult = mulAdd(cresult, x2, splat(T, -0.0013888378));
    cresult = mulAdd(cresult, x2, splat(T, 0.041666638));
    cresult = mulAdd(cresult, x2, splat(T, -0.5));
    cresult = sign * mulAdd(cresult, x2, splat(T, 1.0));

    return .{ sresult, cresult };
}
test "zmath.sincos32xN" {
    const epsilon = 0.0001;

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const sc = sincos(splat(F32x4, f));
        const sc8 = sincos(splat(F32x8, f));
        const sc16 = sincos(splat(F32x16, f));
        const s4 = @sin(splat(F32x4, f));
        const s8 = @sin(splat(F32x8, f));
        const s16 = @sin(splat(F32x16, f));
        const c4 = @cos(splat(F32x4, f));
        const c8 = @cos(splat(F32x8, f));
        const c16 = @cos(splat(F32x16, f));
        try expect(approxEqAbs(sc[0], s4, epsilon));
        try expect(approxEqAbs(sc8[0], s8, epsilon));
        try expect(approxEqAbs(sc16[0], s16, epsilon));
        try expect(approxEqAbs(sc[1], c4, epsilon));
        try expect(approxEqAbs(sc8[1], c8, epsilon));
        try expect(approxEqAbs(sc16[1], c16, epsilon));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

fn asin32xN(v: anytype) @TypeOf(v) {
    // 7-degree minimax approximation
    const T = @TypeOf(v);

    const x = abs(v);
    const root = sqrt(maxFast(splat(T, 0.0), splat(T, 1.0) - x));

    var t0 = mulAdd(splat(T, -0.0012624911), x, splat(T, 0.0066700901));
    t0 = mulAdd(t0, x, splat(T, -0.0170881256));
    t0 = mulAdd(t0, x, splat(T, 0.0308918810));
    t0 = mulAdd(t0, x, splat(T, -0.0501743046));
    t0 = mulAdd(t0, x, splat(T, 0.0889789874));
    t0 = mulAdd(t0, x, splat(T, -0.2145988016));
    t0 = root * mulAdd(t0, x, splat(T, 1.5707963050));

    const t1 = splat(T, math.pi) - t0;
    return splat(T, 0.5 * math.pi) - select(v >= splat(T, 0.0), t0, t1);
}

fn acos32xN(v: anytype) @TypeOf(v) {
    // 7-degree minimax approximation
    const T = @TypeOf(v);

    const x = abs(v);
    const root = sqrt(maxFast(splat(T, 0.0), splat(T, 1.0) - x));

    var t0 = mulAdd(splat(T, -0.0012624911), x, splat(T, 0.0066700901));
    t0 = mulAdd(t0, x, splat(T, -0.0170881256));
    t0 = mulAdd(t0, x, splat(T, 0.0308918810));
    t0 = mulAdd(t0, x, splat(T, -0.0501743046));
    t0 = mulAdd(t0, x, splat(T, 0.0889789874));
    t0 = mulAdd(t0, x, splat(T, -0.2145988016));
    t0 = root * mulAdd(t0, x, splat(T, 1.5707963050));

    const t1 = splat(T, math.pi) - t0;
    return select(v >= splat(T, 0.0), t0, t1);
}

pub fn atan(v: anytype) @TypeOf(v) {
    // 17-degree minimax approximation
    const T = @TypeOf(v);

    const vabs = abs(v);
    const vinv = splat(T, 1.0) / v;
    var sign = select(v > splat(T, 1.0), splat(T, 1.0), splat(T, -1.0));
    const comp = vabs <= splat(T, 1.0);
    sign = select(comp, splat(T, 0.0), sign);
    const x = select(comp, v, vinv);
    const x2 = x * x;

    var result = mulAdd(splat(T, 0.0028662257), x2, splat(T, -0.0161657367));
    result = mulAdd(result, x2, splat(T, 0.0429096138));
    result = mulAdd(result, x2, splat(T, -0.0752896400));
    result = mulAdd(result, x2, splat(T, 0.1065626393));
    result = mulAdd(result, x2, splat(T, -0.1420889944));
    result = mulAdd(result, x2, splat(T, 0.1999355085));
    result = mulAdd(result, x2, splat(T, -0.3333314528));
    result = x * mulAdd(result, x2, splat(T, 1.0));

    const result1 = sign * splat(T, 0.5 * math.pi) - result;
    return select(sign == splat(T, 0.0), result, result1);
}
test "zmath.atan" {
    const epsilon = 0.0001;
    {
        const v = f32x4(0.25, 0.5, 1.0, 1.25);
        const e = f32x4(math.atan(v[0]), math.atan(v[1]), math.atan(v[2]), math.atan(v[3]));
        try expect(approxEqAbs(e, atan(v), epsilon));
    }
    {
        const v = f32x8(-0.25, 0.5, -1.0, 1.25, 100.0, -200.0, 300.0, 400.0);
        // zig fmt: off
        const e = f32x8(
            math.atan(v[0]), math.atan(v[1]), math.atan(v[2]), math.atan(v[3]),
            math.atan(v[4]), math.atan(v[5]), math.atan(v[6]), math.atan(v[7]),
        );
        // zig fmt: on
        try expect(approxEqAbs(e, atan(v), epsilon));
    }
    {
        // zig fmt: off
        const v = f32x16(
            -0.25, 0.5, -1.0, 0.0, 0.1, -0.2, 30.0, 400.0,
            -0.25, 0.5, -1.0, -0.0, -0.05, -0.125, 0.0625, 4000.0
        );
        const e = f32x16(
            math.atan(v[0]), math.atan(v[1]), math.atan(v[2]), math.atan(v[3]),
            math.atan(v[4]), math.atan(v[5]), math.atan(v[6]), math.atan(v[7]),
            math.atan(v[8]), math.atan(v[9]), math.atan(v[10]), math.atan(v[11]),
            math.atan(v[12]), math.atan(v[13]), math.atan(v[14]), math.atan(v[15]),
        );
        // zig fmt: on
        try expect(approxEqAbs(e, atan(v), epsilon));
    }
    {
        try expect(approxEqAbs(atan(splat(F32x4, math.inf_f32)), splat(F32x4, 0.5 * math.pi), epsilon));
        try expect(approxEqAbs(atan(splat(F32x4, -math.inf_f32)), splat(F32x4, -0.5 * math.pi), epsilon));
        try expect(all(isNan(atan(splat(F32x4, math.nan_f32))), 0) == true);
        try expect(all(isNan(atan(splat(F32x4, -math.nan_f32))), 0) == true);
    }
}

pub fn atan2(vy: anytype, vx: anytype) @TypeOf(vx) {
    const T = @TypeOf(vy);
    const Tu = @Vector(veclen(T), u32);

    const vx_is_positive =
        (@bitCast(Tu, vx) & @splat(veclen(T), @as(u32, 0x8000_0000))) == @splat(veclen(T), @as(u32, 0));

    const vy_sign = andInt(vy, splatNegativeZero(T));
    const c0_25pi = orInt(vy_sign, splat(T, 0.25 * math.pi));
    const c0_50pi = orInt(vy_sign, splat(T, 0.50 * math.pi));
    const c0_75pi = orInt(vy_sign, splat(T, 0.75 * math.pi));
    const c1_00pi = orInt(vy_sign, splat(T, 1.00 * math.pi));

    var r1 = select(vx_is_positive, vy_sign, c1_00pi);
    var r2 = select(vx == splat(T, 0.0), c0_50pi, splatInt(T, 0xffff_ffff));
    const r3 = select(vy == splat(T, 0.0), r1, r2);
    const r4 = select(vx_is_positive, c0_25pi, c0_75pi);
    const r5 = select(isInf(vx), r4, c0_50pi);
    const result = select(isInf(vy), r5, r3);
    const result_valid = @bitCast(Tu, result) == @splat(veclen(T), @as(u32, 0xffff_ffff));

    const v = vy / vx;
    const r0 = atan(v);

    r1 = select(vx_is_positive, splatNegativeZero(T), c1_00pi);
    r2 = r0 + r1;

    return select(result_valid, r2, result);
}
test "zmath.atan2" {
    // From DirectXMath XMVectorATan2():
    //
    // Return the inverse tangent of Y / X in the range of -Pi to Pi with the following exceptions:

    //     Y == 0 and X is Negative         -> Pi with the sign of Y
    //     y == 0 and x is positive         -> 0 with the sign of y
    //     Y != 0 and X == 0                -> Pi / 2 with the sign of Y
    //     Y != 0 and X is Negative         -> atan(y/x) + (PI with the sign of Y)
    //     X == -Infinity and Finite Y      -> Pi with the sign of Y
    //     X == +Infinity and Finite Y      -> 0 with the sign of Y
    //     Y == Infinity and X is Finite    -> Pi / 2 with the sign of Y
    //     Y == Infinity and X == -Infinity -> 3Pi / 4 with the sign of Y
    //     Y == Infinity and X == +Infinity -> Pi / 4 with the sign of Y

    const epsilon = 0.0001;
    try expect(approxEqAbs(atan2(splat(F32x4, 0.0), splat(F32x4, -1.0)), splat(F32x4, math.pi), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, -0.0), splat(F32x4, -1.0)), splat(F32x4, -math.pi), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, 1.0), splat(F32x4, 0.0)), splat(F32x4, 0.5 * math.pi), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, -1.0), splat(F32x4, 0.0)), splat(F32x4, -0.5 * math.pi), epsilon));
    try expect(approxEqAbs(
        atan2(splat(F32x4, 1.0), splat(F32x4, -1.0)),
        splat(F32x4, math.atan(@as(f32, -1.0)) + math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, -10.0), splat(F32x4, -2.0)),
        splat(F32x4, math.atan(@as(f32, 5.0)) - math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(atan2(splat(F32x4, 1.0), splat(F32x4, -math.inf_f32)), splat(F32x4, math.pi), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, -1.0), splat(F32x4, -math.inf_f32)), splat(F32x4, -math.pi), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, 1.0), splat(F32x4, math.inf_f32)), splat(F32x4, 0.0), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, -1.0), splat(F32x4, math.inf_f32)), splat(F32x4, -0.0), epsilon));
    try expect(approxEqAbs(
        atan2(splat(F32x4, math.inf_f32), splat(F32x4, 2.0)),
        splat(F32x4, 0.5 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, -math.inf_f32), splat(F32x4, 2.0)),
        splat(F32x4, -0.5 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, math.inf_f32), splat(F32x4, -math.inf_f32)),
        splat(F32x4, 0.75 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, -math.inf_f32), splat(F32x4, -math.inf_f32)),
        splat(F32x4, -0.75 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, math.inf_f32), splat(F32x4, math.inf_f32)),
        splat(F32x4, 0.25 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(splat(F32x4, -math.inf_f32), splat(F32x4, math.inf_f32)),
        splat(F32x4, -0.25 * math.pi),
        epsilon,
    ));
    try expect(approxEqAbs(
        atan2(
            f32x8(0.0, -math.inf_f32, -0.0, 2.0, math.inf_f32, math.inf_f32, 1.0, -math.inf_f32),
            f32x8(-2.0, math.inf_f32, 1.0, 0.0, 10.0, -math.inf_f32, 1.0, -math.inf_f32),
        ),
        f32x8(
            math.pi,
            -0.25 * math.pi,
            -0.0,
            0.5 * math.pi,
            0.5 * math.pi,
            0.75 * math.pi,
            math.atan(@as(f32, 1.0)),
            -0.75 * math.pi,
        ),
        epsilon,
    ));
    try expect(approxEqAbs(atan2(splat(F32x4, 0.0), splat(F32x4, 0.0)), splat(F32x4, 0.0), epsilon));
    try expect(approxEqAbs(atan2(splat(F32x4, -0.0), splat(F32x4, 0.0)), splat(F32x4, 0.0), epsilon));
    try expect(all(isNan(atan2(splat(F32x4, 1.0), splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(atan2(splat(F32x4, -1.0), splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(atan2(splat(F32x4, math.nan_f32), splat(F32x4, -1.0))), 0) == true);
    try expect(all(isNan(atan2(splat(F32x4, -math.nan_f32), splat(F32x4, 1.0))), 0) == true);
}

// ------------------------------------------------------------------------------
//
// 3. 2D, 3D, 4D vector functions
//
// ------------------------------------------------------------------------------

pub inline fn dot2(v0: Vec, v1: Vec) F32x4 {
    var xmm0 = v0 * v1; // | x0*x1 | y0*y1 | -- | -- |
    var xmm1 = swizzle(xmm0, .y, .x, .x, .x); // | y0*y1 | -- | -- | -- |
    xmm0 = F32x4{ xmm0[0] + xmm1[0], xmm0[1], xmm0[2], xmm0[3] }; // | x0*x1 + y0*y1 | -- | -- | -- |
    return swizzle(xmm0, .x, .x, .x, .x);
}
test "zmath.dot2" {
    const v0 = F32x4{ -1.0, 2.0, 300.0, -2.0 };
    const v1 = F32x4{ 4.0, 5.0, 600.0, 2.0 };
    var v = dot2(v0, v1);
    try expect(approxEqAbs(v, splat(F32x4, 6.0), 0.0001));
}

pub inline fn dot3(v0: Vec, v1: Vec) F32x4 {
    var dot = v0 * v1;
    var temp = swizzle(dot, .y, .z, .y, .z);
    dot = F32x4{ dot[0] + temp[0], dot[1], dot[2], dot[2] }; // addss
    temp = swizzle(temp, .y, .y, .y, .y);
    dot = F32x4{ dot[0] + temp[0], dot[1], dot[2], dot[2] }; // addss
    return swizzle(dot, .x, .x, .x, .x);
}
test "zmath.dot3" {
    const v0 = F32x4{ -1.0, 2.0, 3.0, 1.0 };
    const v1 = F32x4{ 4.0, 5.0, 6.0, 1.0 };
    var v = dot3(v0, v1);
    try expect(approxEqAbs(v, splat(F32x4, 24.0), 0.0001));
}

pub inline fn dot4(v0: Vec, v1: Vec) F32x4 {
    var xmm0 = v0 * v1; // | x0*x1 | y0*y1 | z0*z1 | w0*w1 |
    var xmm1 = swizzle(xmm0, .y, .x, .w, .x); // | y0*y1 | -- | w0*w1 | -- |
    xmm1 = xmm0 + xmm1; // | x0*x1 + y0*y1 | -- | z0*z1 + w0*w1 | -- |
    xmm0 = swizzle(xmm1, .z, .x, .x, .x); // | z0*z1 + w0*w1 | -- | -- | -- |
    xmm0 = F32x4{ xmm0[0] + xmm1[0], xmm0[1], xmm0[2], xmm0[2] }; // addss
    return swizzle(xmm0, .x, .x, .x, .x);
}
test "zmath.dot4" {
    const v0 = F32x4{ -1.0, 2.0, 3.0, -2.0 };
    const v1 = F32x4{ 4.0, 5.0, 6.0, 2.0 };
    var v = dot4(v0, v1);
    try expect(approxEqAbs(v, splat(F32x4, 20.0), 0.0001));
}

pub inline fn cross3(v0: Vec, v1: Vec) Vec {
    var xmm0 = swizzle(v0, .y, .z, .x, .w);
    var xmm1 = swizzle(v1, .z, .x, .y, .w);
    var result = xmm0 * xmm1;
    xmm0 = swizzle(xmm0, .y, .z, .x, .w);
    xmm1 = swizzle(xmm1, .z, .x, .y, .w);
    result = result - xmm0 * xmm1;
    return @bitCast(F32x4, @bitCast(U32x4, result) & u32x4_mask3);
}
test "zmath.cross3" {
    {
        const v0 = F32x4{ 1.0, 0.0, 0.0, 1.0 };
        const v1 = F32x4{ 0.0, 1.0, 0.0, 1.0 };
        var v = cross3(v0, v1);
        try expect(approxEqAbs(v, F32x4{ 0.0, 0.0, 1.0, 0.0 }, 0.0001));
    }
    {
        const v0 = F32x4{ 1.0, 0.0, 0.0, 1.0 };
        const v1 = F32x4{ 0.0, -1.0, 0.0, 1.0 };
        var v = cross3(v0, v1);
        try expect(approxEqAbs(v, F32x4{ 0.0, 0.0, -1.0, 0.0 }, 0.0001));
    }
    {
        const v0 = F32x4{ -3.0, 0, -2.0, 1.0 };
        const v1 = F32x4{ 5.0, -1.0, 2.0, 1.0 };
        var v = cross3(v0, v1);
        try expect(approxEqAbs(v, F32x4{ -2.0, -4.0, 3.0, 0.0 }, 0.0001));
    }
}

pub inline fn lengthSq2(v: Vec) F32x4 {
    return dot2(v, v);
}
pub inline fn lengthSq3(v: Vec) F32x4 {
    return dot3(v, v);
}
pub inline fn lengthSq4(v: Vec) F32x4 {
    return dot4(v, v);
}

pub inline fn length2(v: Vec) F32x4 {
    return sqrt(dot2(v, v));
}
pub inline fn length3(v: Vec) F32x4 {
    return sqrt(dot3(v, v));
}
pub inline fn length4(v: Vec) F32x4 {
    return sqrt(dot4(v, v));
}
test "zmath.length3" {
    {
        var v = length3(F32x4{ 1.0, -2.0, 3.0, 1000.0 });
        try expect(approxEqAbs(v, splat(F32x4, math.sqrt(14.0)), 0.001));
    }
    {
        var v = length3(F32x4{ 1.0, math.nan_f32, math.inf_f32, 1000.0 });
        try expect(all(isNan(v), 0));
    }
    {
        var v = length3(F32x4{ 1.0, math.inf_f32, 3.0, 1000.0 });
        try expect(all(isInf(v), 0));
    }
    {
        var v = length3(F32x4{ 3.0, 2.0, 1.0, math.nan_f32 });
        try expect(approxEqAbs(v, splat(F32x4, math.sqrt(14.0)), 0.001));
    }
}

pub inline fn normalize2(v: Vec) Vec {
    return v * splat(F32x4, 1.0) / sqrt(dot2(v, v));
}
pub inline fn normalize3(v: Vec) Vec {
    return v * splat(F32x4, 1.0) / sqrt(dot3(v, v));
}
pub inline fn normalize4(v: Vec) Vec {
    return v * splat(F32x4, 1.0) / sqrt(dot4(v, v));
}
test "zmath.normalize3" {
    {
        const v0 = F32x4{ 1.0, -2.0, 3.0, 1000.0 };
        var v = normalize3(v0);
        try expect(approxEqAbs(v, v0 * splat(F32x4, 1.0 / math.sqrt(14.0)), 0.0005));
    }
    {
        try expect(any(isNan(normalize3(F32x4{ 1.0, math.inf_f32, 1.0, 1.0 })), 0));
        try expect(any(isNan(normalize3(F32x4{ -math.inf_f32, math.inf_f32, 0.0, 0.0 })), 0));
        try expect(any(isNan(normalize3(F32x4{ -math.nan_f32, math.qnan_f32, 0.0, 0.0 })), 0));
        try expect(any(isNan(normalize3(splat(F32x4, 0.0))), 0));
    }
}
test "zmath.normalize4" {
    {
        const v0 = F32x4{ 1.0, -2.0, 3.0, 10.0 };
        var v = normalize4(v0);
        try expect(approxEqAbs(v, v0 * splat(F32x4, 1.0 / math.sqrt(114.0)), 0.0005));
    }
    {
        try expect(any(isNan(normalize4(F32x4{ 1.0, math.inf_f32, 1.0, 1.0 })), 0));
        try expect(any(isNan(normalize4(F32x4{ -math.inf_f32, math.inf_f32, 0.0, 0.0 })), 0));
        try expect(any(isNan(normalize4(F32x4{ -math.nan_f32, math.qnan_f32, 0.0, 0.0 })), 0));
        try expect(any(isNan(normalize4(splat(F32x4, 0.0))), 0));
    }
}

fn vecMulMat(v: Vec, m: Mat) Vec {
    var vx = @shuffle(f32, v, undefined, [4]i32{ 0, 0, 0, 0 });
    var vy = @shuffle(f32, v, undefined, [4]i32{ 1, 1, 1, 1 });
    var vz = @shuffle(f32, v, undefined, [4]i32{ 2, 2, 2, 2 });
    var vw = @shuffle(f32, v, undefined, [4]i32{ 3, 3, 3, 3 });
    return vx * m[0] + vy * m[1] + vz * m[2] + vw * m[3];
}
fn matMulVec(m: Mat, v: Vec) Vec {
    return .{ dot4(m[0], v)[0], dot4(m[1], v)[0], dot4(m[2], v)[0], dot4(m[3], v)[0] };
}
test "zmath.vecMulMat" {
    const m = Mat{
        f32x4(1.0, 0.0, 0.0, 0.0),
        f32x4(0.0, 1.0, 0.0, 0.0),
        f32x4(0.0, 0.0, 1.0, 0.0),
        f32x4(2.0, 3.0, 4.0, 1.0),
    };
    const vm = mul(f32x4(1.0, 2.0, 3.0, 1.0), m);
    const mv = mul(m, f32x4(1.0, 2.0, 3.0, 1.0));
    const v = mul(transpose(m), f32x4(1.0, 2.0, 3.0, 1.0));
    try expect(approxEqAbs(vm, f32x4(3.0, 5.0, 7.0, 1.0), 0.0001));
    try expect(approxEqAbs(mv, f32x4(1.0, 2.0, 3.0, 21.0), 0.0001));
    try expect(approxEqAbs(v, f32x4(3.0, 5.0, 7.0, 1.0), 0.0001));
}

// ------------------------------------------------------------------------------
//
// 4. Matrix functions
//
// ------------------------------------------------------------------------------

fn mulRetType(comptime Ta: type, comptime Tb: type) type {
    if (Ta == Mat and Tb == Mat) {
        return Mat;
    } else if (Ta == Quat and Tb == Quat) {
        return Quat;
    } else if ((Ta == f32 and Tb == Mat) or (Ta == Mat and Tb == f32)) {
        return Mat;
    } else if ((Ta == f32 and Tb == Vec) or (Ta == Vec and Tb == f32)) {
        return Vec;
    } else if ((Ta == Vec and Tb == Mat) or (Ta == Mat and Tb == Vec)) {
        return Vec;
    }
    @compileError("zmath.mul() not implemented for types: " ++ @typeName(Ta) ++ @typeName(Tb));
}

pub fn mul(a: anytype, b: anytype) mulRetType(@TypeOf(a), @TypeOf(b)) {
    const Ta = @TypeOf(a);
    const Tb = @TypeOf(b);
    if (Ta == Mat and Tb == Mat) {
        return mulMat(a, b);
    } else if (Ta == Quat and Tb == Quat) {
        return mulQuat(a, b);
    } else if (Ta == f32 and Tb == Mat) {
        const va = splat(F32x4, a);
        return Mat{ va * b[0], va * b[1], va * b[2], va * b[3] };
    } else if (Ta == Mat and Tb == f32) {
        const vb = splat(F32x4, b);
        return Mat{ a[0] * vb, a[1] * vb, a[2] * vb, a[3] * vb };
    } else if (Ta == f32 and Tb == Vec) {
        return splat(F32x4, a) * b;
    } else if (Ta == Vec and Tb == f32) {
        return a * splat(F32x4, b);
    } else if (Ta == Vec and Tb == Mat) {
        return vecMulMat(a, b);
    } else if (Ta == Mat and Tb == Vec) {
        return matMulVec(a, b);
    } else {
        @compileError("zmath.mul() not implemented for types: " ++ @typeName(Ta) ++ ", " ++ @typeName(Tb));
    }
}
test "zmath.mul" {
    {
        const s: f32 = 2.0;
        try expect(approxEqAbs(mul(s, f32x4(1.0, 2.0, 3.0, 4.0)), f32x4(2.0, 4.0, 6.0, 8.0), 0.0001));
        try expect(approxEqAbs(mul(f32x4(1.0, 2.0, 3.0, 4.0), s), f32x4(2.0, 4.0, 6.0, 8.0), 0.0001));
    }
    {
        const m = Mat{
            f32x4(0.1, 0.2, 0.3, 0.4),
            f32x4(0.5, 0.6, 0.7, 0.8),
            f32x4(0.9, 1.0, 1.1, 1.2),
            f32x4(1.3, 1.4, 1.5, 1.6),
        };
        const ms = mul(@as(f32, 2.0), m);
        try expect(approxEqAbs(ms[0], f32x4(0.2, 0.4, 0.6, 0.8), 0.0001));
        try expect(approxEqAbs(ms[1], f32x4(1.0, 1.2, 1.4, 1.6), 0.0001));
        try expect(approxEqAbs(ms[2], f32x4(1.8, 2.0, 2.2, 2.4), 0.0001));
        try expect(approxEqAbs(ms[3], f32x4(2.6, 2.8, 3.0, 3.2), 0.0001));
    }
}

fn mulMat(m0: Mat, m1: Mat) Mat {
    var result: Mat = undefined;
    comptime var row: u32 = 0;
    inline while (row < 4) : (row += 1) {
        var vx = @shuffle(f32, m0[row], undefined, [4]i32{ 0, 0, 0, 0 });
        var vy = @shuffle(f32, m0[row], undefined, [4]i32{ 1, 1, 1, 1 });
        var vz = @shuffle(f32, m0[row], undefined, [4]i32{ 2, 2, 2, 2 });
        var vw = @shuffle(f32, m0[row], undefined, [4]i32{ 3, 3, 3, 3 });
        vx = vx * m1[0];
        vy = vy * m1[1];
        vz = vz * m1[2];
        vw = vw * m1[3];
        vx = vx + vz;
        vy = vy + vw;
        vx = vx + vy;
        result[row] = vx;
    }
    return result;
}
test "zmath.matrix.mul" {
    const a = Mat{
        f32x4(0.1, 0.2, 0.3, 0.4),
        f32x4(0.5, 0.6, 0.7, 0.8),
        f32x4(0.9, 1.0, 1.1, 1.2),
        f32x4(1.3, 1.4, 1.5, 1.6),
    };
    const b = Mat{
        f32x4(1.7, 1.8, 1.9, 2.0),
        f32x4(2.1, 2.2, 2.3, 2.4),
        f32x4(2.5, 2.6, 2.7, 2.8),
        f32x4(2.9, 3.0, 3.1, 3.2),
    };
    const c = mul(a, b);
    try expect(approxEqAbs(c[0], f32x4(2.5, 2.6, 2.7, 2.8), 0.0001));
    try expect(approxEqAbs(c[1], f32x4(6.18, 6.44, 6.7, 6.96), 0.0001));
    try expect(approxEqAbs(c[2], f32x4(9.86, 10.28, 10.7, 11.12), 0.0001));
    try expect(approxEqAbs(c[3], f32x4(13.54, 14.12, 14.7, 15.28), 0.0001));
}

pub fn transpose(m: Mat) Mat {
    const temp1 = @shuffle(f32, m[0], m[1], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
    const temp3 = @shuffle(f32, m[0], m[1], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
    const temp2 = @shuffle(f32, m[2], m[3], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
    const temp4 = @shuffle(f32, m[2], m[3], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
    return .{
        @shuffle(f32, temp1, temp2, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
        @shuffle(f32, temp1, temp2, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
        @shuffle(f32, temp3, temp4, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
        @shuffle(f32, temp3, temp4, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
    };
}
test "zmath.matrix.transpose" {
    const m = Mat{
        f32x4(1.0, 2.0, 3.0, 4.0),
        f32x4(5.0, 6.0, 7.0, 8.0),
        f32x4(9.0, 10.0, 11.0, 12.0),
        f32x4(13.0, 14.0, 15.0, 16.0),
    };
    const mt = transpose(m);
    try expect(approxEqAbs(mt[0], f32x4(1.0, 5.0, 9.0, 13.0), 0.0001));
    try expect(approxEqAbs(mt[1], f32x4(2.0, 6.0, 10.0, 14.0), 0.0001));
    try expect(approxEqAbs(mt[2], f32x4(3.0, 7.0, 11.0, 15.0), 0.0001));
    try expect(approxEqAbs(mt[3], f32x4(4.0, 8.0, 12.0, 16.0), 0.0001));
}

pub fn rotationX(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(1.0, 0.0, 0.0, 0.0),
        f32x4(0.0, sc[1], sc[0], 0.0),
        f32x4(0.0, -sc[0], sc[1], 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}

pub fn rotationY(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(sc[1], 0.0, -sc[0], 0.0),
        f32x4(0.0, 1.0, 0.0, 0.0),
        f32x4(sc[0], 0.0, sc[1], 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}

pub fn rotationZ(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(sc[1], sc[0], 0.0, 0.0),
        f32x4(-sc[0], sc[1], 0.0, 0.0),
        f32x4(0.0, 0.0, 1.0, 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}

pub fn translation(x: f32, y: f32, z: f32) Mat {
    return .{
        f32x4(1.0, 0.0, 0.0, 0.0),
        f32x4(0.0, 1.0, 0.0, 0.0),
        f32x4(0.0, 0.0, 1.0, 0.0),
        f32x4(x, y, z, 1.0),
    };
}
pub fn translationV(v: Vec) Mat {
    return translation(v[0], v[1], v[2]);
}

pub fn scaling(x: f32, y: f32, z: f32) Mat {
    return .{
        f32x4(x, 0.0, 0.0, 0.0),
        f32x4(0.0, y, 0.0, 0.0),
        f32x4(0.0, 0.0, z, 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}
pub fn scalingV(v: Vec) Mat {
    return scaling(v[0], v[1], v[2]);
}

pub fn lookToLh(eyepos: Vec, eyedir: Vec, updir: Vec) Mat {
    const az = normalize3(eyedir);
    const ax = normalize3(cross3(updir, az));
    const ay = normalize3(cross3(az, ax));
    return transpose(.{
        f32x4(ax[0], ax[1], ax[2], -dot3(ax, eyepos)[0]),
        f32x4(ay[0], ay[1], ay[2], -dot3(ay, eyepos)[0]),
        f32x4(az[0], az[1], az[2], -dot3(az, eyepos)[0]),
        f32x4(0.0, 0.0, 0.0, 1.0),
    });
}
pub fn lookToRh(eyepos: Vec, eyedir: Vec, updir: Vec) Mat {
    return lookToLh(eyepos, -eyedir, updir);
}
pub fn lookAtLh(eyepos: Vec, focuspos: Vec, updir: Vec) Mat {
    return lookToLh(eyepos, focuspos - eyepos, updir);
}
pub fn lookAtRh(eyepos: Vec, focuspos: Vec, updir: Vec) Mat {
    return lookToLh(eyepos, eyepos - focuspos, updir);
}
test "zmath.matrix.lookToLh" {
    const m = lookToLh(f32x4(0.0, 0.0, -3.0, 1.0), f32x4(0.0, 0.0, 1.0, 0.0), f32x4(0.0, 1.0, 0.0, 0.0));
    try expect(approxEqAbs(m[0], f32x4(1.0, 0.0, 0.0, 0.0), 0.001));
    try expect(approxEqAbs(m[1], f32x4(0.0, 1.0, 0.0, 0.0), 0.001));
    try expect(approxEqAbs(m[2], f32x4(0.0, 0.0, 1.0, 0.0), 0.001));
    try expect(approxEqAbs(m[3], f32x4(0.0, 0.0, 3.0, 1.0), 0.001));
}

pub fn perspectiveFovLh(fovy: f32, aspect: f32, near: f32, far: f32) Mat {
    const scfov = sincos(0.5 * fovy);

    assert(near > 0.0 and far > 0.0 and far > near);
    assert(!math.approxEqAbs(f32, scfov[0], 0.0, 0.001));
    assert(!math.approxEqAbs(f32, far, near, 0.001));
    assert(!math.approxEqAbs(f32, aspect, 0.0, 0.01));

    const h = scfov[1] / scfov[0];
    const w = h / aspect;
    const r = far / (far - near);
    return .{
        f32x4(w, 0.0, 0.0, 0.0),
        f32x4(0.0, h, 0.0, 0.0),
        f32x4(0.0, 0.0, r, 1.0),
        f32x4(0.0, 0.0, -r * near, 0.0),
    };
}
pub fn perspectiveFovRh(fovy: f32, aspect: f32, near: f32, far: f32) Mat {
    const scfov = sincos(0.5 * fovy);

    assert(near > 0.0 and far > 0.0 and far > near);
    assert(!math.approxEqAbs(f32, scfov[0], 0.0, 0.001));
    assert(!math.approxEqAbs(f32, far, near, 0.001));
    assert(!math.approxEqAbs(f32, aspect, 0.0, 0.01));

    const h = scfov[1] / scfov[0];
    const w = h / aspect;
    const r = far / (near - far);
    return .{
        f32x4(w, 0.0, 0.0, 0.0),
        f32x4(0.0, h, 0.0, 0.0),
        f32x4(0.0, 0.0, r, -1.0),
        f32x4(0.0, 0.0, r * near, 0.0),
    };
}

pub fn determinant(m: Mat) F32x4 {
    var v0 = swizzle(m[2], .y, .x, .x, .x);
    var v1 = swizzle(m[3], .z, .z, .y, .y);
    var v2 = swizzle(m[2], .y, .x, .x, .x);
    var v3 = swizzle(m[3], .w, .w, .w, .z);
    var v4 = swizzle(m[2], .z, .z, .y, .y);
    var v5 = swizzle(m[3], .w, .w, .w, .z);

    var p0 = v0 * v1;
    var p1 = v2 * v3;
    var p2 = v4 * v5;

    v0 = swizzle(m[2], .z, .z, .y, .y);
    v1 = swizzle(m[3], .y, .x, .x, .x);
    v2 = swizzle(m[2], .w, .w, .w, .z);
    v3 = swizzle(m[3], .y, .x, .x, .x);
    v4 = swizzle(m[2], .w, .w, .w, .z);
    v5 = swizzle(m[3], .z, .z, .y, .y);

    p0 = mulAdd(-v0, v1, p0);
    p1 = mulAdd(-v2, v3, p1);
    p2 = mulAdd(-v4, v5, p2);

    v0 = swizzle(m[1], .w, .w, .w, .z);
    v1 = swizzle(m[1], .z, .z, .y, .y);
    v2 = swizzle(m[1], .y, .x, .x, .x);

    var s = m[0] * f32x4(1.0, -1.0, 1.0, -1.0);
    var r = v0 * p0;
    r = mulAdd(-v1, p1, r);
    r = mulAdd(v2, p2, r);
    return dot4(s, r);
}
test "zmath.matrix.determinant" {
    const m = Mat{
        f32x4(10.0, -9.0, -12.0, 1.0),
        f32x4(7.0, -12.0, 11.0, 1.0),
        f32x4(-10.0, 10.0, 3.0, 1.0),
        f32x4(1.0, 2.0, 3.0, 4.0),
    };
    try expect(approxEqAbs(determinant(m), splat(F32x4, 2939.0), 0.0001));
}

pub fn inverse(a: anytype) @TypeOf(a) {
    const T = @TypeOf(a);
    return switch (T) {
        Mat => inverseMat(a),
        Quat => inverseQuat(a),
        else => @compileError("zmath.inverse() not implemented for " ++ @typeName(T)),
    };
}

fn inverseMat(m: Mat) Mat {
    return inverseDet(m, null);
}

pub fn inverseDet(m: Mat, out_det: ?*F32x4) Mat {
    const mt = transpose(m);
    var v0: [4]F32x4 = undefined;
    var v1: [4]F32x4 = undefined;

    v0[0] = swizzle(mt[2], .x, .x, .y, .y);
    v1[0] = swizzle(mt[3], .z, .w, .z, .w);
    v0[1] = swizzle(mt[0], .x, .x, .y, .y);
    v1[1] = swizzle(mt[1], .z, .w, .z, .w);
    v0[2] = @shuffle(f32, mt[2], mt[0], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });
    v1[2] = @shuffle(f32, mt[3], mt[1], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });

    var d0 = v0[0] * v1[0];
    var d1 = v0[1] * v1[1];
    var d2 = v0[2] * v1[2];

    v0[0] = swizzle(mt[2], .z, .w, .z, .w);
    v1[0] = swizzle(mt[3], .x, .x, .y, .y);
    v0[1] = swizzle(mt[0], .z, .w, .z, .w);
    v1[1] = swizzle(mt[1], .x, .x, .y, .y);
    v0[2] = @shuffle(f32, mt[2], mt[0], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });
    v1[2] = @shuffle(f32, mt[3], mt[1], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });

    d0 = mulAdd(-v0[0], v1[0], d0);
    d1 = mulAdd(-v0[1], v1[1], d1);
    d2 = mulAdd(-v0[2], v1[2], d2);

    v0[0] = swizzle(mt[1], .y, .z, .x, .y);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ ~@as(i32, 1), 1, 3, 0 });
    v0[1] = swizzle(mt[0], .z, .x, .y, .x);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ 3, ~@as(i32, 1), 1, 2 });
    v0[2] = swizzle(mt[3], .y, .z, .x, .y);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ ~@as(i32, 3), 1, 3, 0 });
    v0[3] = swizzle(mt[2], .z, .x, .y, .x);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ 3, ~@as(i32, 3), 1, 2 });

    var c0 = v0[0] * v1[0];
    var c2 = v0[1] * v1[1];
    var c4 = v0[2] * v1[2];
    var c6 = v0[3] * v1[3];

    v0[0] = swizzle(mt[1], .z, .w, .y, .z);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ 3, 0, 1, ~@as(i32, 0) });
    v0[1] = swizzle(mt[0], .w, .z, .w, .y);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ 2, 1, ~@as(i32, 0), 0 });
    v0[2] = swizzle(mt[3], .z, .w, .y, .z);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ 3, 0, 1, ~@as(i32, 2) });
    v0[3] = swizzle(mt[2], .w, .z, .w, .y);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ 2, 1, ~@as(i32, 2), 0 });

    c0 = mulAdd(-v0[0], v1[0], c0);
    c2 = mulAdd(-v0[1], v1[1], c2);
    c4 = mulAdd(-v0[2], v1[2], c4);
    c6 = mulAdd(-v0[3], v1[3], c6);

    v0[0] = swizzle(mt[1], .w, .x, .w, .x);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ 2, ~@as(i32, 1), ~@as(i32, 0), 2 });
    v0[1] = swizzle(mt[0], .y, .w, .x, .z);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ ~@as(i32, 1), 0, 3, ~@as(i32, 0) });
    v0[2] = swizzle(mt[3], .w, .x, .w, .x);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ 2, ~@as(i32, 3), ~@as(i32, 2), 2 });
    v0[3] = swizzle(mt[2], .y, .w, .x, .z);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ ~@as(i32, 3), 0, 3, ~@as(i32, 2) });

    const c1 = mulAdd(-v0[0], v1[0], c0);
    const c3 = mulAdd(v0[1], v1[1], c2);
    const c5 = mulAdd(-v0[2], v1[2], c4);
    const c7 = mulAdd(v0[3], v1[3], c6);

    c0 = mulAdd(v0[0], v1[0], c0);
    c2 = mulAdd(-v0[1], v1[1], c2);
    c4 = mulAdd(v0[2], v1[2], c4);
    c6 = mulAdd(-v0[3], v1[3], c6);

    var mr = Mat{
        f32x4(c0[0], c1[1], c0[2], c1[3]),
        f32x4(c2[0], c3[1], c2[2], c3[3]),
        f32x4(c4[0], c5[1], c4[2], c5[3]),
        f32x4(c6[0], c7[1], c6[2], c7[3]),
    };

    const det = dot4(mr[0], mt[0]);
    if (out_det != null) {
        out_det.?.* = det;
    }

    if (math.approxEqAbs(f32, det[0], 0.0, 0.0001)) {
        return .{
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
        };
    }

    const scale = splat(F32x4, 1.0) / det;
    mr[0] *= scale;
    mr[1] *= scale;
    mr[2] *= scale;
    mr[3] *= scale;
    return mr;
}
test "zmath.matrix.inverse" {
    const m = Mat{
        f32x4(10.0, -9.0, -12.0, 1.0),
        f32x4(7.0, -12.0, 11.0, 1.0),
        f32x4(-10.0, 10.0, 3.0, 1.0),
        f32x4(1.0, 2.0, 3.0, 4.0),
    };
    var det: F32x4 = undefined;
    const mi = inverseDet(m, &det);
    try expect(approxEqAbs(det, splat(F32x4, 2939.0), 0.0001));

    try expect(approxEqAbs(mi[0], f32x4(-0.170806, -0.13576, -0.349439, 0.164001), 0.0001));
    try expect(approxEqAbs(mi[1], f32x4(-0.163661, -0.14801, -0.253147, 0.141204), 0.0001));
    try expect(approxEqAbs(mi[2], f32x4(-0.0871045, 0.00646478, -0.0785982, 0.0398095), 0.0001));
    try expect(approxEqAbs(mi[3], f32x4(0.18986, 0.103096, 0.272882, 0.10854), 0.0001));
}

pub fn matFromNormAxisAngle(axis: Vec, angle: f32) Mat {
    const sincos_angle = sincos(angle);

    const c2 = splat(F32x4, 1.0 - sincos_angle[1]);
    const c1 = splat(F32x4, sincos_angle[1]);
    const c0 = splat(F32x4, sincos_angle[0]);

    const n0 = swizzle(axis, .y, .z, .x, .w);
    const n1 = swizzle(axis, .z, .x, .y, .w);

    var v0 = c2 * n0 * n1;
    const r0 = c2 * axis * axis + c1;
    const r1 = c0 * axis + v0;
    var r2 = v0 - c0 * axis;

    v0 = @bitCast(F32x4, @bitCast(U32x4, r0) & u32x4_mask3);

    var v1 = @shuffle(f32, r1, r2, [4]i32{ 0, 2, ~@as(i32, 1), ~@as(i32, 2) });
    v1 = swizzle(v1, .y, .z, .w, .x);

    var v2 = @shuffle(f32, r1, r2, [4]i32{ 1, 1, ~@as(i32, 0), ~@as(i32, 0) });
    v2 = swizzle(v2, .x, .z, .x, .z);

    r2 = @shuffle(f32, v0, v1, [4]i32{ 0, 3, ~@as(i32, 0), ~@as(i32, 1) });
    r2 = swizzle(r2, .x, .z, .w, .y);

    var m: Mat = undefined;
    m[0] = r2;

    r2 = @shuffle(f32, v0, v1, [4]i32{ 1, 3, ~@as(i32, 2), ~@as(i32, 3) });
    r2 = swizzle(r2, .z, .x, .w, .y);
    m[1] = r2;

    v2 = @shuffle(f32, v2, v0, [4]i32{ 0, 1, ~@as(i32, 2), ~@as(i32, 3) });
    m[2] = v2;
    m[3] = f32x4(0.0, 0.0, 0.0, 1.0);
    return m;
}
pub fn matFromAxisAngle(axis: Vec, angle: f32) Mat {
    assert(!all(axis == splat(F32x4, 0.0), 3));
    assert(!all(isInf(axis), 3));
    const normal = normalize3(axis);
    return matFromNormAxisAngle(normal, angle);
}
test "zmath.matrix.matFromAxisAngle" {
    {
        const m0 = matFromAxisAngle(f32x4(1.0, 0.0, 0.0, 0.0), math.pi * 0.25);
        const m1 = rotationX(math.pi * 0.25);
        try expect(approxEqAbs(m0[0], m1[0], 0.001));
        try expect(approxEqAbs(m0[1], m1[1], 0.001));
        try expect(approxEqAbs(m0[2], m1[2], 0.001));
        try expect(approxEqAbs(m0[3], m1[3], 0.001));
    }
    {
        const m0 = matFromAxisAngle(f32x4(0.0, 1.0, 0.0, 0.0), math.pi * 0.125);
        const m1 = rotationY(math.pi * 0.125);
        try expect(approxEqAbs(m0[0], m1[0], 0.001));
        try expect(approxEqAbs(m0[1], m1[1], 0.001));
        try expect(approxEqAbs(m0[2], m1[2], 0.001));
        try expect(approxEqAbs(m0[3], m1[3], 0.001));
    }
    {
        const m0 = matFromAxisAngle(f32x4(0.0, 0.0, 1.0, 0.0), math.pi * 0.333);
        const m1 = rotationZ(math.pi * 0.333);
        try expect(approxEqAbs(m0[0], m1[0], 0.001));
        try expect(approxEqAbs(m0[1], m1[1], 0.001));
        try expect(approxEqAbs(m0[2], m1[2], 0.001));
        try expect(approxEqAbs(m0[3], m1[3], 0.001));
    }
}

pub fn matFromQuat(quat: Quat) Mat {
    var q0 = quat + quat;
    var q1 = quat * q0;

    var v0 = swizzle(q1, .y, .x, .x, .w);
    v0 = @bitCast(F32x4, @bitCast(U32x4, v0) & u32x4_mask3);

    var v1 = swizzle(q1, .z, .z, .y, .w);
    v1 = @bitCast(F32x4, @bitCast(U32x4, v1) & u32x4_mask3);

    var r0 = (f32x4(1.0, 1.0, 1.0, 0.0) - v0) - v1;

    v0 = swizzle(quat, .x, .x, .y, .w);
    v1 = swizzle(q0, .z, .y, .z, .w);
    v0 = v0 * v1;

    v1 = swizzle(quat, .w, .w, .w, .w);
    var v2 = swizzle(q0, .y, .z, .x, .w);
    v1 = v1 * v2;

    var r1 = v0 + v1;
    var r2 = v0 - v1;

    v0 = @shuffle(f32, r1, r2, [4]i32{ 1, 2, ~@as(i32, 0), ~@as(i32, 1) });
    v0 = swizzle(v0, .x, .z, .w, .y);
    v1 = @shuffle(f32, r1, r2, [4]i32{ 0, 0, ~@as(i32, 2), ~@as(i32, 2) });
    v1 = swizzle(v1, .x, .z, .x, .z);

    q1 = @shuffle(f32, r0, v0, [4]i32{ 0, 3, ~@as(i32, 0), ~@as(i32, 1) });
    q1 = swizzle(q1, .x, .z, .w, .y);

    var m: Mat = undefined;
    m[0] = q1;

    q1 = @shuffle(f32, r0, v0, [4]i32{ 1, 3, ~@as(i32, 2), ~@as(i32, 3) });
    q1 = swizzle(q1, .z, .x, .w, .y);
    m[1] = q1;

    q1 = @shuffle(f32, v1, r0, [4]i32{ 0, 1, ~@as(i32, 2), ~@as(i32, 3) });
    m[2] = q1;
    m[3] = f32x4(0.0, 0.0, 0.0, 1.0);
    return m;
}
test "zmath.matrix.matFromQuat" {
    {
        const m = matFromQuat(f32x4(0.0, 0.0, 0.0, 1.0));
        try expect(approxEqAbs(m[0], f32x4(1.0, 0.0, 0.0, 0.0), 0.0001));
        try expect(approxEqAbs(m[1], f32x4(0.0, 1.0, 0.0, 0.0), 0.0001));
        try expect(approxEqAbs(m[2], f32x4(0.0, 0.0, 1.0, 0.0), 0.0001));
        try expect(approxEqAbs(m[3], f32x4(0.0, 0.0, 0.0, 1.0), 0.0001));
    }
}

pub fn matFromRollPitchYaw(pitch: f32, yaw: f32, roll: f32) Mat {
    return matFromRollPitchYawV(f32x4(pitch, yaw, roll, 0.0));
}
pub fn matFromRollPitchYawV(angles: Vec) Mat {
    return matFromQuat(quatFromRollPitchYawV(angles));
}

pub fn matToQuat(m: Mat) Quat {
    return quatFromMat(m);
}

// ------------------------------------------------------------------------------
//
// 5. Quaternion functions
//
// ------------------------------------------------------------------------------

fn mulQuat(q0: Quat, q1: Quat) Quat {
    var result = swizzle(q1, .w, .w, .w, .w);
    var q1x = swizzle(q1, .x, .x, .x, .x);
    var q1y = swizzle(q1, .y, .y, .y, .y);
    var q1z = swizzle(q1, .z, .z, .z, .z);
    result = result * q0;
    var q0_shuf = swizzle(q0, .w, .z, .y, .x);
    q1x = q1x * q0_shuf;
    q0_shuf = swizzle(q0_shuf, .y, .x, .w, .z);
    result = mulAdd(q1x, f32x4(1.0, -1.0, 1.0, -1.0), result);
    q1y = q1y * q0_shuf;
    q0_shuf = swizzle(q0_shuf, .w, .z, .y, .x);
    q1y = q1y * f32x4(1.0, 1.0, -1.0, -1.0);
    q1z = q1z * q0_shuf;
    q1y = mulAdd(q1z, f32x4(-1.0, 1.0, 1.0, -1.0), q1y);
    return result + q1y;
}
test "zmath.quaternion.mul" {
    {
        const q0 = f32x4(2.0, 3.0, 4.0, 1.0);
        const q1 = f32x4(3.0, 2.0, 1.0, 4.0);
        try expect(approxEqAbs(mul(q0, q1), f32x4(16.0, 4.0, 22.0, -12.0), 0.0001));
    }
}

pub fn quatToMat(quat: Quat) Mat {
    return matFromQuat(quat);
}

pub fn quatToAxisAngle(quat: Quat, axis: *Vec, angle: *f32) void {
    axis.* = quat;
    angle.* = 2.0 * acos(quat[3]);
}
test "zmath.quaternion.quatToAxisAngle" {
    {
        const q0 = quatFromNormAxisAngle(f32x4(1.0, 0.0, 0.0, 0.0), 0.25 * math.pi);
        var axis: Vec = f32x4(4.0, 3.0, 2.0, 1.0);
        var angle: f32 = 10.0;
        quatToAxisAngle(q0, &axis, &angle);
        try expect(math.approxEqAbs(f32, axis[0], math.sin(@as(f32, 0.25) * math.pi * 0.5), 0.0001));
        try expect(axis[1] == 0.0);
        try expect(axis[2] == 0.0);
        try expect(math.approxEqAbs(f32, angle, 0.25 * math.pi, 0.0001));
    }
}

pub fn quatFromMat(m: Mat) Quat {
    const r0 = m[0];
    const r1 = m[1];
    const r2 = m[2];
    const r00 = swizzle(r0, .x, .x, .x, .x);
    const r11 = swizzle(r1, .y, .y, .y, .y);
    const r22 = swizzle(r2, .z, .z, .z, .z);

    const x2gey2 = (r11 - r00) <= splat(F32x4, 0.0);
    const z2gew2 = (r11 + r00) <= splat(F32x4, 0.0);
    const x2py2gez2pw2 = r22 <= splat(F32x4, 0.0);

    var t0 = mulAdd(r00, f32x4(1.0, -1.0, -1.0, 1.0), splat(F32x4, 1.0));
    var t1 = r11 * f32x4(-1.0, 1.0, -1.0, 1.0);
    var t2 = mulAdd(r22, f32x4(-1.0, -1.0, 1.0, 1.0), t0);
    const x2y2z2w2 = t1 + t2;

    t0 = @shuffle(f32, r0, r1, [4]i32{ 1, 2, ~@as(i32, 2), ~@as(i32, 1) });
    t1 = @shuffle(f32, r1, r2, [4]i32{ 0, 0, ~@as(i32, 0), ~@as(i32, 1) });
    t1 = swizzle(t1, .x, .z, .w, .y);
    const xyxzyz = t0 + t1;

    t0 = @shuffle(f32, r2, r1, [4]i32{ 1, 0, ~@as(i32, 0), ~@as(i32, 0) });
    t1 = @shuffle(f32, r1, r0, [4]i32{ 2, 2, ~@as(i32, 2), ~@as(i32, 1) });
    t1 = swizzle(t1, .x, .z, .w, .y);
    const xwywzw = (t0 - t1) * f32x4(-1.0, 1.0, -1.0, 1.0);

    t0 = @shuffle(f32, x2y2z2w2, xyxzyz, [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 0) });
    t1 = @shuffle(f32, x2y2z2w2, xwywzw, [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 0) });
    t2 = @shuffle(f32, xyxzyz, xwywzw, [4]i32{ 1, 2, ~@as(i32, 0), ~@as(i32, 1) });

    const tensor0 = @shuffle(f32, t0, t2, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });
    const tensor1 = @shuffle(f32, t0, t2, [4]i32{ 2, 1, ~@as(i32, 1), ~@as(i32, 3) });
    const tensor2 = @shuffle(f32, t2, t1, [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 2) });
    const tensor3 = @shuffle(f32, t2, t1, [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 1) });

    t0 = select(x2gey2, tensor0, tensor1);
    t1 = select(z2gew2, tensor2, tensor3);
    t2 = select(x2py2gez2pw2, t0, t1);

    return t2 / length4(t2);
}
test "zmath.quatFromMat" {
    {
        const q0 = quatFromAxisAngle(f32x4(1.0, 0.0, 0.0, 0.0), 0.25 * math.pi);
        const q1 = quatFromMat(rotationX(0.25 * math.pi));
        try expect(approxEqAbs(q0, q1, 0.0001));
    }
    {
        const q0 = quatFromAxisAngle(f32x4(1.0, 2.0, 0.5, 0.0), 0.25 * math.pi);
        const q1 = quatFromMat(matFromAxisAngle(f32x4(1.0, 2.0, 0.5, 0.0), 0.25 * math.pi));
        try expect(approxEqAbs(q0, q1, 0.0001));
    }
    {
        const q0 = quatFromRollPitchYaw(0.1 * math.pi, -0.2 * math.pi, 0.3 * math.pi);
        const q1 = quatFromMat(matFromRollPitchYaw(0.1 * math.pi, -0.2 * math.pi, 0.3 * math.pi));
        try expect(approxEqAbs(q0, q1, 0.0001));
    }
}

pub fn quatFromNormAxisAngle(axis: Vec, angle: f32) Quat {
    var n = f32x4(axis[0], axis[1], axis[2], 1.0);
    const sc = sincos(0.5 * angle);
    return n * f32x4(sc[0], sc[0], sc[0], sc[1]);
}
pub fn quatFromAxisAngle(axis: Vec, angle: f32) Quat {
    assert(!all(axis == splat(F32x4, 0.0), 3));
    assert(!all(isInf(axis), 3));
    const normal = normalize3(axis);
    return quatFromNormAxisAngle(normal, angle);
}
test "zmath.quaternion.quatFromNormAxisAngle" {
    {
        const q0 = quatFromAxisAngle(f32x4(1.0, 0.0, 0.0, 0.0), 0.25 * math.pi);
        const q1 = quatFromAxisAngle(f32x4(0.0, 1.0, 0.0, 0.0), 0.125 * math.pi);
        const m0 = rotationX(0.25 * math.pi);
        const m1 = rotationY(0.125 * math.pi);
        const mr0 = quatToMat(mul(q0, q1));
        const mr1 = mul(m0, m1);
        try expect(approxEqAbs(mr0[0], mr1[0], 0.0001));
        try expect(approxEqAbs(mr0[1], mr1[1], 0.0001));
        try expect(approxEqAbs(mr0[2], mr1[2], 0.0001));
        try expect(approxEqAbs(mr0[3], mr1[3], 0.0001));
    }
    {
        const m0 = quatToMat(quatFromAxisAngle(f32x4(1.0, 2.0, 0.5, 0.0), 0.25 * math.pi));
        const m1 = matFromAxisAngle(f32x4(1.0, 2.0, 0.5, 0.0), 0.25 * math.pi);
        try expect(approxEqAbs(m0[0], m1[0], 0.0001));
        try expect(approxEqAbs(m0[1], m1[1], 0.0001));
        try expect(approxEqAbs(m0[2], m1[2], 0.0001));
        try expect(approxEqAbs(m0[3], m1[3], 0.0001));
    }
}

pub fn conjugate(quat: Quat) Quat {
    return quat * f32x4(-1.0, -1.0, -1.0, 1.0);
}

fn inverseQuat(quat: Quat) Quat {
    const l = lengthSq4(quat);
    const conj = conjugate(quat);
    return select(l <= splat(F32x4, math.f32_epsilon), splat(F32x4, 0.0), conj / l);
}
test "zmath.quaternion.inverseQuat" {
    try expect(approxEqAbs(
        inverse(f32x4(2.0, 3.0, 4.0, 1.0)),
        f32x4(-1.0 / 15.0, -1.0 / 10.0, -2.0 / 15.0, 1.0 / 30.0),
        0.0001,
    ));
}

pub fn slerp(q0: Quat, q1: Quat, t: f32) Quat {
    return slerpV(q0, q1, splat(F32x4, t));
}
pub fn slerpV(q0: Quat, q1: Quat, t: F32x4) Quat {
    var cos_omega = dot4(q0, q1);
    const sign = select(cos_omega < splat(F32x4, 0.0), splat(F32x4, -1.0), splat(F32x4, 1.0));

    cos_omega = cos_omega * sign;
    const sin_omega = sqrt(splat(F32x4, 1.0) - cos_omega * cos_omega);

    const omega = atan2(sin_omega, cos_omega);

    var v01 = t;
    v01 = @bitCast(F32x4, (@bitCast(U32x4, v01) & u32x4_mask2) ^ u32x4_sign_mask1);
    v01 = f32x4(1.0, 0.0, 0.0, 0.0) + v01;

    var s0 = sin(v01 * omega) / sin_omega;
    s0 = select(cos_omega < splat(F32x4, 1.0 - 0.00001), s0, v01);

    var s1 = swizzle(s0, .y, .y, .y, .y);
    s0 = swizzle(s0, .x, .x, .x, .x);

    return q0 * s0 + sign * q1 * s1;
}
test "zmath.quaternion.slerp" {
    const from = f32x4(0.0, 0.0, 0.0, 1.0);
    const to = f32x4(0.5, 0.5, -0.5, 0.5);
    const result = slerp(from, to, 0.5);
    try expect(approxEqAbs(result, f32x4(0.28867513, 0.28867513, -0.28867513, 0.86602540), 0.0001));
}

pub fn quatFromRollPitchYaw(pitch: f32, yaw: f32, roll: f32) Quat {
    return quatFromRollPitchYawV(f32x4(pitch, yaw, roll, 0.0));
}
pub fn quatFromRollPitchYawV(angles: Vec) Quat { // | pitch | yaw | roll | 0 |
    const sc = sincos(splat(Vec, 0.5) * angles);
    const p0 = @shuffle(f32, sc[1], sc[0], [4]i32{ ~@as(i32, 0), 0, 0, 0 });
    const p1 = @shuffle(f32, sc[0], sc[1], [4]i32{ ~@as(i32, 0), 0, 0, 0 });
    const y0 = @shuffle(f32, sc[1], sc[0], [4]i32{ 1, ~@as(i32, 1), 1, 1 });
    const y1 = @shuffle(f32, sc[0], sc[1], [4]i32{ 1, ~@as(i32, 1), 1, 1 });
    const r0 = @shuffle(f32, sc[1], sc[0], [4]i32{ 2, 2, ~@as(i32, 2), 2 });
    const r1 = @shuffle(f32, sc[0], sc[1], [4]i32{ 2, 2, ~@as(i32, 2), 2 });
    const q1 = p1 * f32x4(1.0, -1.0, -1.0, 1.0) * y1;
    const q0 = p0 * y0 * r0;
    return mulAdd(q1, r1, q0);
}
test "zmath.quaternion.quatFromRollPitchYawV" {
    {
        const m0 = quatToMat(quatFromRollPitchYawV(f32x4(0.25 * math.pi, 0.0, 0.0, 0.0)));
        const m1 = rotationX(0.25 * math.pi);
        try expect(approxEqAbs(m0[0], m1[0], 0.0001));
        try expect(approxEqAbs(m0[1], m1[1], 0.0001));
        try expect(approxEqAbs(m0[2], m1[2], 0.0001));
        try expect(approxEqAbs(m0[3], m1[3], 0.0001));
    }
    {
        const m0 = quatToMat(quatFromRollPitchYaw(0.1 * math.pi, 0.2 * math.pi, 0.3 * math.pi));
        const m1 = mul(
            rotationZ(0.3 * math.pi),
            mul(rotationX(0.1 * math.pi), rotationY(0.2 * math.pi)),
        );
        try expect(approxEqAbs(m0[0], m1[0], 0.0001));
        try expect(approxEqAbs(m0[1], m1[1], 0.0001));
        try expect(approxEqAbs(m0[2], m1[2], 0.0001));
        try expect(approxEqAbs(m0[3], m1[3], 0.0001));
    }
}

// ------------------------------------------------------------------------------
//
// X. Misc functions
//
// ------------------------------------------------------------------------------

pub inline fn linePointDistance(linept0: Vec, linept1: Vec, pt: Vec) F32x4 {
    const ptvec = pt - linept0;
    const linevec = linept1 - linept0;
    const scale = dot3(ptvec, linevec) / lengthSq3(linevec);
    return length3(ptvec - linevec * scale);
}
test "zmath.linePointDistance" {
    {
        const linept0 = F32x4{ -1.0, -2.0, -3.0, 1.0 };
        const linept1 = F32x4{ 1.0, 2.0, 3.0, 1.0 };
        const pt = F32x4{ 1.0, 1.0, 1.0, 1.0 };
        var v = linePointDistance(linept0, linept1, pt);
        try expect(approxEqAbs(v, splat(F32x4, 0.654), 0.001));
    }
}

fn sin32(v: f32) f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    if (y > 0.5 * math.pi) {
        y = math.pi - y;
    } else if (y < -math.pi * 0.5) {
        y = -math.pi - y;
    }
    const y2 = y * y;

    // 11-degree minimax approximation
    var sinv = mulAdd(@as(f32, -2.3889859e-08), y2, 2.7525562e-06);
    sinv = mulAdd(sinv, y2, -0.00019840874);
    sinv = mulAdd(sinv, y2, 0.0083333310);
    sinv = mulAdd(sinv, y2, -0.16666667);
    return y * mulAdd(sinv, y2, 1.0);
}
fn cos32(v: f32) f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    const sign = blk: {
        if (y > 0.5 * math.pi) {
            y = math.pi - y;
            break :blk @as(f32, -1.0);
        } else if (y < -math.pi * 0.5) {
            y = -math.pi - y;
            break :blk @as(f32, -1.0);
        } else {
            break :blk @as(f32, 1.0);
        }
    };
    const y2 = y * y;

    // 10-degree minimax approximation
    var cosv = mulAdd(@as(f32, -2.6051615e-07), y2, 2.4760495e-05);
    cosv = mulAdd(cosv, y2, -0.0013888378);
    cosv = mulAdd(cosv, y2, 0.041666638);
    cosv = mulAdd(cosv, y2, -0.5);
    return sign * mulAdd(cosv, y2, 1.0);
}
fn sincos32(v: f32) [2]f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    const sign = blk: {
        if (y > 0.5 * math.pi) {
            y = math.pi - y;
            break :blk @as(f32, -1.0);
        } else if (y < -math.pi * 0.5) {
            y = -math.pi - y;
            break :blk @as(f32, -1.0);
        } else {
            break :blk @as(f32, 1.0);
        }
    };
    const y2 = y * y;

    // 11-degree minimax approximation
    var sinv = mulAdd(@as(f32, -2.3889859e-08), y2, 2.7525562e-06);
    sinv = mulAdd(sinv, y2, -0.00019840874);
    sinv = mulAdd(sinv, y2, 0.0083333310);
    sinv = mulAdd(sinv, y2, -0.16666667);
    sinv = y * mulAdd(sinv, y2, 1.0);

    // 10-degree minimax approximation
    var cosv = mulAdd(@as(f32, -2.6051615e-07), y2, 2.4760495e-05);
    cosv = mulAdd(cosv, y2, -0.0013888378);
    cosv = mulAdd(cosv, y2, 0.041666638);
    cosv = mulAdd(cosv, y2, -0.5);
    cosv = sign * mulAdd(cosv, y2, 1.0);

    return .{ sinv, cosv };
}
test "zmath.sincos32" {
    const epsilon = 0.0001;

    try expect(math.isNan(sincos32(math.inf_f32)[0]));
    try expect(math.isNan(sincos32(math.inf_f32)[1]));
    try expect(math.isNan(sincos32(-math.inf_f32)[0]));
    try expect(math.isNan(sincos32(-math.inf_f32)[1]));
    try expect(math.isNan(sincos32(math.nan_f32)[0]));
    try expect(math.isNan(sincos32(-math.nan_f32)[1]));

    try expect(math.isNan(sin32(math.inf_f32)));
    try expect(math.isNan(cos32(math.inf_f32)));
    try expect(math.isNan(sin32(-math.inf_f32)));
    try expect(math.isNan(cos32(-math.inf_f32)));
    try expect(math.isNan(sin32(math.nan_f32)));
    try expect(math.isNan(cos32(-math.nan_f32)));

    var f: f32 = -100.0;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const sc = sincos32(f);
        const s0 = sin32(f);
        const c0 = cos32(f);
        const s = @sin(f);
        const c = @cos(f);
        try expect(math.approxEqAbs(f32, sc[0], s, epsilon));
        try expect(math.approxEqAbs(f32, sc[1], c, epsilon));
        try expect(math.approxEqAbs(f32, s0, s, epsilon));
        try expect(math.approxEqAbs(f32, c0, c, epsilon));
        f += 0.12345 * @intToFloat(f32, i);
    }
}

fn asin32(v: f32) f32 {
    const x = @fabs(v);
    var omx = 1.0 - x;
    if (omx < 0.0) {
        omx = 0.0;
    }
    const root = @sqrt(omx);

    // 7-degree minimax approximation
    var result = mulAdd(@as(f32, -0.0012624911), x, 0.0066700901);
    result = mulAdd(result, x, -0.0170881256);
    result = mulAdd(result, x, 0.0308918810);
    result = mulAdd(result, x, -0.0501743046);
    result = mulAdd(result, x, 0.0889789874);
    result = mulAdd(result, x, -0.2145988016);
    result = root * mulAdd(result, x, 1.5707963050);

    return if (v >= 0.0) 0.5 * math.pi - result else result - 0.5 * math.pi;
}
test "zmath.asin32" {
    const epsilon = 0.0001;

    try expect(math.approxEqAbs(f32, asin(@as(f32, -1.1)), -0.5 * math.pi, epsilon));
    try expect(math.approxEqAbs(f32, asin(@as(f32, 1.1)), 0.5 * math.pi, epsilon));
    try expect(math.approxEqAbs(f32, asin(@as(f32, -1000.1)), -0.5 * math.pi, epsilon));
    try expect(math.approxEqAbs(f32, asin(@as(f32, 100000.1)), 0.5 * math.pi, epsilon));
    try expect(math.isNan(asin(math.inf_f32)));
    try expect(math.isNan(asin(-math.inf_f32)));
    try expect(math.isNan(asin(math.nan_f32)));
    try expect(math.isNan(asin(-math.nan_f32)));

    try expect(approxEqAbs(asin(splat(F32x8, -100.0)), splat(F32x8, -0.5 * math.pi), epsilon));
    try expect(approxEqAbs(asin(splat(F32x16, 100.0)), splat(F32x16, 0.5 * math.pi), epsilon));
    try expect(all(isNan(asin(splat(F32x4, math.inf_f32))), 0) == true);
    try expect(all(isNan(asin(splat(F32x4, -math.inf_f32))), 0) == true);
    try expect(all(isNan(asin(splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(asin(splat(F32x4, math.qnan_f32))), 0) == true);

    var f: f32 = -1.0;
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        const r0 = asin32(f);
        const r1 = math.asin(f);
        const r4 = asin(splat(F32x4, f));
        const r8 = asin(splat(F32x8, f));
        const r16 = asin(splat(F32x16, f));
        try expect(math.approxEqAbs(f32, r0, r1, epsilon));
        try expect(approxEqAbs(r4, splat(F32x4, r1), epsilon));
        try expect(approxEqAbs(r8, splat(F32x8, r1), epsilon));
        try expect(approxEqAbs(r16, splat(F32x16, r1), epsilon));
        f += 0.09 * @intToFloat(f32, i);
    }
}

fn acos32(v: f32) f32 {
    const x = @fabs(v);
    var omx = 1.0 - x;
    if (omx < 0.0) {
        omx = 0.0;
    }
    const root = @sqrt(omx);

    // 7-degree minimax approximation
    var result = mulAdd(@as(f32, -0.0012624911), x, 0.0066700901);
    result = mulAdd(result, x, -0.0170881256);
    result = mulAdd(result, x, 0.0308918810);
    result = mulAdd(result, x, -0.0501743046);
    result = mulAdd(result, x, 0.0889789874);
    result = mulAdd(result, x, -0.2145988016);
    result = root * mulAdd(result, x, 1.5707963050);

    return if (v >= 0.0) result else math.pi - result;
}
test "zmath.acos32" {
    const epsilon = 0.1;

    try expect(math.approxEqAbs(f32, acos(@as(f32, -1.1)), math.pi, epsilon));
    try expect(math.approxEqAbs(f32, acos(@as(f32, -10000.1)), math.pi, epsilon));
    try expect(math.approxEqAbs(f32, acos(@as(f32, 1.1)), 0.0, epsilon));
    try expect(math.approxEqAbs(f32, acos(@as(f32, 1000.1)), 0.0, epsilon));
    try expect(math.isNan(acos(math.inf_f32)));
    try expect(math.isNan(acos(-math.inf_f32)));
    try expect(math.isNan(acos(math.nan_f32)));
    try expect(math.isNan(acos(-math.nan_f32)));

    try expect(approxEqAbs(acos(splat(F32x8, -100.0)), splat(F32x8, math.pi), epsilon));
    try expect(approxEqAbs(acos(splat(F32x16, 100.0)), splat(F32x16, 0.0), epsilon));
    try expect(all(isNan(acos(splat(F32x4, math.inf_f32))), 0) == true);
    try expect(all(isNan(acos(splat(F32x4, -math.inf_f32))), 0) == true);
    try expect(all(isNan(acos(splat(F32x4, math.nan_f32))), 0) == true);
    try expect(all(isNan(acos(splat(F32x4, math.qnan_f32))), 0) == true);

    var f: f32 = -1.0;
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        const r0 = acos32(f);
        const r1 = math.acos(f);
        const r4 = acos(splat(F32x4, f));
        const r8 = acos(splat(F32x8, f));
        const r16 = acos(splat(F32x16, f));
        try expect(math.approxEqAbs(f32, r0, r1, epsilon));
        try expect(approxEqAbs(r4, splat(F32x4, r1), epsilon));
        try expect(approxEqAbs(r8, splat(F32x8, r1), epsilon));
        try expect(approxEqAbs(r16, splat(F32x16, r1), epsilon));
        f += 0.09 * @intToFloat(f32, i);
    }
}

pub fn modAngle32(in_angle: f32) f32 {
    const angle = in_angle + math.pi;
    var temp: f32 = math.fabs(angle);
    temp = temp - (2.0 * math.pi * @intToFloat(f32, @floatToInt(i32, temp / math.pi)));
    temp = temp - math.pi;
    if (angle < 0.0) {
        temp = -temp;
    }
    return temp;
}

// ------------------------------------------------------------------------------
//
// Private functions and constants
//
// ------------------------------------------------------------------------------

const f32x4_0x8000_0000: F32x4 = splatInt(F32x4, 0x8000_0000);
const f32x4_0x7fff_ffff: F32x4 = splatInt(F32x4, 0x7fff_ffff);
const f32x4_inf: F32x4 = splat(F32x4, math.inf_f32);
const u32x4_mask3: U32x4 = U32x4{ 0xffff_ffff, 0xffff_ffff, 0xffff_ffff, 0 };
const u32x4_mask2: U32x4 = U32x4{ 0xffff_ffff, 0xffff_ffff, 0, 0 };
const u32x4_sign_mask1: U32x4 = U32x4{ 0x8000_0000, 0, 0, 0 };

inline fn splatNegativeZero(comptime T: type) T {
    return @splat(veclen(T), @bitCast(f32, @as(u32, 0x8000_0000)));
}
inline fn splatNoFraction(comptime T: type) T {
    return @splat(veclen(T), @as(f32, 8_388_608.0));
}
inline fn splatAbsMask(comptime T: type) T {
    return @splat(veclen(T), @bitCast(f32, @as(u32, 0x7fff_ffff)));
}

fn floatToIntAndBack(v: anytype) @TypeOf(v) {
    // This routine won't handle nan, inf and numbers greater than 8_388_608.0 (will generate undefined values)
    @setRuntimeSafety(false);

    const T = @TypeOf(v);
    const len = veclen(T);

    var vi32: [len]i32 = undefined;
    comptime var i: u32 = 0;
    // vcvttps2dq
    inline while (i < len) : (i += 1) {
        vi32[i] = @floatToInt(i32, v[i]);
    }

    var vf32: [len]f32 = undefined;
    i = 0;
    // vcvtdq2ps
    inline while (i < len) : (i += 1) {
        vf32[i] = @intToFloat(f32, vi32[i]);
    }

    return vf32;
}
test "zmath.floatToIntAndBack" {
    {
        const v = floatToIntAndBack(F32x4{ 1.1, 2.9, 3.0, -4.5 });
        try expect(approxEqAbs(v, F32x4{ 1.0, 2.0, 3.0, -4.0 }, 0.0));
    }
    {
        const v = floatToIntAndBack(F32x8{ 1.1, 2.9, 3.0, -4.5, 2.5, -2.5, 1.1, -100.2 });
        try expect(approxEqAbs(v, F32x8{ 1.0, 2.0, 3.0, -4.0, 2.0, -2.0, 1.0, -100.0 }, 0.0));
    }
    {
        const v = floatToIntAndBack(F32x4{ math.inf_f32, 2.9, math.nan_f32, math.qnan_f32 });
        try expect(v[1] == 2.0);
    }
}

fn approxEqAbs(v0: anytype, v1: anytype, eps: f32) bool {
    const T = @TypeOf(v0);
    comptime var i: comptime_int = 0;
    inline while (i < veclen(T)) : (i += 1) {
        if (!math.approxEqAbs(f32, v0[i], v1[i], eps)) {
            return false;
        }
    }
    return true;
}

// ------------------------------------------------------------------------------
// This software is available under 2 licenses -- choose whichever you prefer.
// ------------------------------------------------------------------------------
// ALTERNATIVE A - MIT License
// Copyright (c) 2022 Michal Ziulek
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ------------------------------------------------------------------------------
// ALTERNATIVE B - Public Domain (www.unlicense.org)
// This is free and unencumbered software released into the public domain.
// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
// software, either in source code form or as a compiled binary, for any purpose,
// commercial or non-commercial, and by any means.
// In jurisdictions that recognize copyright laws, the author or authors of this
// software dedicate any and all copyright interest in the software to the public
// domain. We make this dedication for the benefit of the public at large and to
// the detriment of our heirs and successors. We intend this dedication to be an
// overt act of relinquishment in perpetuity of all present and future rights to
// this software under copyright law.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------------------------------
