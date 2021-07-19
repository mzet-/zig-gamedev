const builtin = @import("builtin");
const std = @import("std");
const w = struct {
    usingnamespace std.os.windows;
    usingnamespace @import("windows/windows.zig");
    usingnamespace @import("windows/d3d12.zig");
    usingnamespace @import("windows/d3d12sdklayers.zig");
    usingnamespace @import("windows/d3dcommon.zig");
    usingnamespace @import("windows/dxgi.zig");
};

pub export var D3D12SDKVersion: u32 = 4;
pub export var D3D12SDKPath: [*c]const u8 = ".\\D3D12\\";

pub fn main() !void {
    try w.dxgi_load_dll();
    try w.d3d12_load_dll();

    const factory = blk: {
        var maybe_factory: ?*w.IDXGIFactory1 = null;
        _ = w.CreateDXGIFactory2(1, &w.IID_IDXGIFactory1, @ptrCast(*?*c_void, &maybe_factory));
        break :blk maybe_factory.?;
    };

    const debug = blk: {
        var maybe_debug: ?*w.ID3D12Debug1 = null;
        _ = w.D3D12GetDebugInterface(&w.IID_ID3D12Debug1, @ptrCast(*?*c_void, &maybe_debug));
        break :blk maybe_debug.?;
    };
    debug.EnableDebugLayer();
    debug.SetEnableGPUBasedValidation(w.TRUE);
    _ = debug.Release();

    const device = blk: {
        var maybe_device: ?*w.ID3D12Device = null;
        _ = w.D3D12CreateDevice(null, ._11_1, &w.IID_ID3D12Device, @ptrCast(*?*c_void, &maybe_device));
        break :blk maybe_device.?;
    };

    const cmdqueue = blk: {
        var maybe_cmdqueue: ?*w.ID3D12CommandQueue = null;
        _ = device.CreateCommandQueue(&.{
            .Type = .DIRECT,
            .Priority = @enumToInt(w.D3D12_COMMAND_QUEUE_PRIORITY.NORMAL),
            .Flags = .{},
            .NodeMask = 0,
        }, &w.IID_ID3D12CommandQueue, @ptrCast(*?*c_void, &maybe_cmdqueue));
        break :blk maybe_cmdqueue.?;
    };

    _ = factory.Release();
    _ = cmdqueue.Release();
    _ = device.Release();

    std.debug.print("All OK!\n", .{});
}
