const std = @import("std");
usingnamespace std.os.windows;
usingnamespace @import("win.zig");

pub const D3D_PRIMITIVE_TOPOLOGY = enum(UINT) {
    UNDEFINED = 0,
    POINTLIST = 1,
    LINELIST = 2,
    LINESTRIP = 3,
    TRIANGLELIST = 4,
    TRIANGLESTRIP = 5,
    LINELIST_ADJ = 10,
    LINESTRIP_ADJ = 11,
    TRIANGLELIST_ADJ = 12,
    TRIANGLESTRIP_ADJ = 13,
    _1_CONTROL_POINT_PATCHLIST = 33,
    _2_CONTROL_POINT_PATCHLIST = 34,
    _3_CONTROL_POINT_PATCHLIST = 35,
    _4_CONTROL_POINT_PATCHLIST = 36,
    _5_CONTROL_POINT_PATCHLIST = 37,
    _6_CONTROL_POINT_PATCHLIST = 38,
    _7_CONTROL_POINT_PATCHLIST = 39,
    _8_CONTROL_POINT_PATCHLIST = 40,
    _9_CONTROL_POINT_PATCHLIST = 41,
    _10_CONTROL_POINT_PATCHLIST = 42,
    _11_CONTROL_POINT_PATCHLIST = 43,
    _12_CONTROL_POINT_PATCHLIST = 44,
    _13_CONTROL_POINT_PATCHLIST = 45,
    _14_CONTROL_POINT_PATCHLIST = 46,
    _15_CONTROL_POINT_PATCHLIST = 47,
    _16_CONTROL_POINT_PATCHLIST = 48,
    _17_CONTROL_POINT_PATCHLIST = 49,
    _18_CONTROL_POINT_PATCHLIST = 50,
    _19_CONTROL_POINT_PATCHLIST = 51,
    _20_CONTROL_POINT_PATCHLIST = 52,
    _21_CONTROL_POINT_PATCHLIST = 53,
    _22_CONTROL_POINT_PATCHLIST = 54,
    _23_CONTROL_POINT_PATCHLIST = 55,
    _24_CONTROL_POINT_PATCHLIST = 56,
    _25_CONTROL_POINT_PATCHLIST = 57,
    _26_CONTROL_POINT_PATCHLIST = 58,
    _27_CONTROL_POINT_PATCHLIST = 59,
    _28_CONTROL_POINT_PATCHLIST = 60,
    _29_CONTROL_POINT_PATCHLIST = 61,
    _30_CONTROL_POINT_PATCHLIST = 62,
    _31_CONTROL_POINT_PATCHLIST = 63,
    _32_CONTROL_POINT_PATCHLIST = 64,
};

pub const D3D_FEATURE_LEVEL = enum(UINT) {
    _1_0_CORE = 0x1000,
    _9_1 = 0x9100,
    _9_2 = 0x9200,
    _9_3 = 0x9300,
    _10_0 = 0xa000,
    _10_1 = 0xa100,
    _11_0 = 0xb000,
    _11_1 = 0xb100,
    _12_0 = 0xc000,
    _12_1 = 0xc100,
    _12_2 = 0xc200,
};

pub const ID3DBlob = extern struct {
    const Self = @This();
    vtbl: *const extern struct {
        unknown: IUnknown.VTable(Self),
        blob: VTable(Self),
    },
    usingnamespace IUnknown.Methods(Self);
    usingnamespace Methods(Self);

    fn Methods(comptime T: type) type {
        return extern struct {
            pub inline fn GetBufferPointer(self: *T) *c_void {
                return self.v.blob.GetBufferPointer(self);
            }
            pub inline fn GetBufferSize(self: *T) SIZE_T {
                return self.v.blob.GetBufferSize(self);
            }
        };
    }

    fn VTable(comptime T: type) type {
        return extern struct {
            GetBufferPointer: fn (*T) callconv(WINAPI) *c_void,
            GetBufferSize: fn (*T) callconv(WINAPI) SIZE_T,
        };
    }
};