const builtin = @import("builtin");
const std = @import("std");
const win32 = @import("win32");
const w = win32.base;
const d2d1 = win32.d2d1;
const d3d12 = win32.d3d12;
const dwrite = win32.dwrite;
const dml = win32.directml;
const common = @import("common");
const gr = common.graphics;
const lib = common.library;
const c = common.c;
const pix = common.pix;
const vm = common.vectormath;
const tracy = common.tracy;
const math = std.math;
const assert = std.debug.assert;
const hrPanic = lib.hrPanic;
const hrPanicOnFail = lib.hrPanicOnFail;
const Vec3 = vm.Vec3;
const Mat4 = vm.Mat4;
const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub export var D3D12SDKVersion: u32 = 4;
pub export var D3D12SDKPath: [*:0]const u8 = ".\\d3d12\\";

const window_name = "zig-gamedev: bullet physics test";
const window_width = 1920;
const window_height = 1080;
const camera_fovy: f32 = math.pi / @as(f32, 3.0);

const DemoState = struct {
    grfx: gr.GraphicsContext,
    gui: gr.GuiContext,
    frame_stats: lib.FrameStats,

    brush: *d2d1.ISolidColorBrush,
    info_txtfmt: *dwrite.ITextFormat,

    physics_debug_pso: gr.PipelineHandle,

    depth_texture: gr.ResourceHandle,
    depth_texture_dsv: d3d12.CPU_DESCRIPTOR_HANDLE,

    physics_debug: *PhysicsDebug,
    physics_world: c.CbtWorldHandle,
    sphere_shape: c.CbtShapeHandle,
    ground_shape: c.CbtShapeHandle,
    bodies: [2]c.CbtBodyHandle,

    camera: struct {
        position: Vec3,
        forward: Vec3,
        pitch: f32,
        yaw: f32,
    },
    mouse: struct {
        cursor_prev_x: i32,
        cursor_prev_y: i32,
    },
    pick: struct {
        body: c.CbtBodyHandle,
        constraint: c.CbtConstraintHandle,
        saved_activation_state: i32,
        saved_linear_damping: f32,
        saved_angular_damping: f32,
        distance: f32,
    },
};

const PsoPhysicsDebug_Vertex = struct {
    position: [3]f32,
    color: u32,
};

const PsoPhysicsDebug_FrameConst = struct {
    world_to_clip: Mat4,
};

const PhysicsDebug = struct {
    lines: std.ArrayList(PsoPhysicsDebug_Vertex),

    fn init(alloc: *std.mem.Allocator) PhysicsDebug {
        return .{ .lines = std.ArrayList(PsoPhysicsDebug_Vertex).init(alloc) };
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.lines.deinit();
        debug.* = undefined;
    }

    fn drawLine(debug: *PhysicsDebug, p0: Vec3, p1: Vec3, color: Vec3) void {
        const r = @floatToInt(u32, color.c[0] * 255.0);
        const g = @floatToInt(u32, color.c[1] * 255.0) << 8;
        const b = @floatToInt(u32, color.c[2] * 255.0) << 16;
        const rgb = r | g | b;
        debug.lines.append(.{ .position = p0.c, .color = rgb }) catch unreachable;
        debug.lines.append(.{ .position = p1.c, .color = rgb }) catch unreachable;
    }

    fn drawContactPoint(debug: *PhysicsDebug, point: Vec3, normal: Vec3, distance: f32, color: Vec3) void {
        debug.drawLine(point, point.add(normal.scale(distance)), color);
        debug.drawLine(point, point.add(normal.scale(0.01)), Vec3.init(0, 0, 0));
    }

    fn drawLineCallback(p0: [*c]const f32, p1: [*c]const f32, color: [*c]const f32, user: ?*c_void) callconv(.C) void {
        const ptr = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(PhysicsDebug), user.?));
        ptr.drawLine(
            Vec3.init(p0[0], p0[1], p0[2]),
            Vec3.init(p1[0], p1[1], p1[2]),
            Vec3.init(color[0], color[1], color[2]),
        );
    }

    fn drawContactPointCallback(
        point: [*c]const f32,
        normal: [*c]const f32,
        distance: f32,
        _: c_int,
        color: [*c]const f32,
        user: ?*c_void,
    ) callconv(.C) void {
        const ptr = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(PhysicsDebug), user.?));
        ptr.drawContactPoint(
            Vec3.init(point[0], point[1], point[2]),
            Vec3.init(normal[0], normal[1], normal[2]),
            distance,
            Vec3.init(color[0], color[1], color[2]),
        );
    }

    fn reportErrorWarningCallback(str: [*c]const u8, _: ?*c_void) callconv(.C) void {
        std.log.info("{s}", .{str});
    }
};

fn init(gpa: *std.mem.Allocator) DemoState {
    const tracy_zone = tracy.zone(@src(), 1);
    defer tracy_zone.end();

    var physics_debug = gpa.create(PhysicsDebug) catch unreachable;
    physics_debug.* = PhysicsDebug.init(gpa);

    const physics_world = c.cbtWorldCreate();
    c.cbtWorldSetGravity(physics_world, &Vec3.init(0.0, -10.0, 0.0).c);

    c.cbtWorldDebugSetCallbacks(physics_world, &.{
        .drawLine = PhysicsDebug.drawLineCallback,
        .drawContactPoint = PhysicsDebug.drawContactPointCallback,
        .reportErrorWarning = PhysicsDebug.reportErrorWarningCallback,
        .user_data = physics_debug,
    });

    const sphere_shape = c.cbtShapeAllocate(c.CBT_SHAPE_TYPE_SPHERE);
    c.cbtShapeSphereCreate(sphere_shape, 0.5);

    const ground_shape = c.cbtShapeAllocate(c.CBT_SHAPE_TYPE_BOX);
    c.cbtShapeBoxCreate(ground_shape, &Vec3.init(20.0, 0.2, 20.0).c);

    var bodies: [2]c.CbtBodyHandle = undefined;

    c.cbtBodyAllocate(bodies.len, &bodies);

    c.cbtBodyCreate(bodies[0], 5.0, &Mat4.initTranslation(Vec3.init(0, 1.5, 5)).toArray4x3(), sphere_shape);
    c.cbtBodySetDamping(bodies[0], 0.2, 0.2);

    c.cbtBodyDestroy(bodies[0]);

    c.cbtBodyCreate(bodies[0], 5.0, &Mat4.initTranslation(Vec3.init(0, 3.5, 5)).toArray4x3(), sphere_shape);
    c.cbtBodySetDamping(bodies[0], 0.2, 0.2);

    c.cbtWorldAddBody(physics_world, bodies[0]);

    c.cbtBodyCreate(bodies[1], 0.0, &Mat4.initIdentity().toArray4x3(), ground_shape);
    c.cbtWorldAddBody(physics_world, bodies[1]);

    assert(c.cbtShapeGetType(sphere_shape) == c.CBT_SHAPE_TYPE_SPHERE);
    assert(c.cbtShapeGetType(ground_shape) == c.CBT_SHAPE_TYPE_BOX);

    const window = lib.initWindow(gpa, window_name, window_width, window_height) catch unreachable;

    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    defer arena_allocator.deinit();

    _ = pix.loadGpuCapturerLibrary();
    _ = pix.setTargetWindow(window);
    _ = pix.beginCapture(
        pix.CAPTURE_GPU,
        &pix.CaptureParameters{ .gpu_capture_params = .{ .FileName = L("capture.wpix") } },
    );

    var grfx = gr.GraphicsContext.init(window);
    grfx.present_flags = 0;
    grfx.present_interval = 1;

    const brush = blk: {
        var brush: *d2d1.ISolidColorBrush = undefined;
        hrPanicOnFail(grfx.d2d.context.CreateSolidColorBrush(
            &.{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 0.5 },
            null,
            @ptrCast(*?*d2d1.ISolidColorBrush, &brush),
        ));
        break :blk brush;
    };

    const info_txtfmt = blk: {
        var info_txtfmt: *dwrite.ITextFormat = undefined;
        hrPanicOnFail(grfx.dwrite_factory.CreateTextFormat(
            L("Verdana"),
            null,
            dwrite.FONT_WEIGHT.BOLD,
            dwrite.FONT_STYLE.NORMAL,
            dwrite.FONT_STRETCH.NORMAL,
            32.0,
            L("en-us"),
            @ptrCast(*?*dwrite.ITextFormat, &info_txtfmt),
        ));
        break :blk info_txtfmt;
    };
    hrPanicOnFail(info_txtfmt.SetTextAlignment(.LEADING));
    hrPanicOnFail(info_txtfmt.SetParagraphAlignment(.NEAR));

    const physics_debug_pso = blk: {
        var pso_desc = d3d12.GRAPHICS_PIPELINE_STATE_DESC.initDefault();
        pso_desc.RTVFormats[0] = .R8G8B8A8_UNORM;
        pso_desc.NumRenderTargets = 1;
        pso_desc.BlendState.RenderTarget[0].RenderTargetWriteMask = 0xf;
        pso_desc.PrimitiveTopologyType = .LINE;
        pso_desc.DSVFormat = .D32_FLOAT;

        break :blk grfx.createGraphicsShaderPipeline(
            &arena_allocator.allocator,
            &pso_desc,
            "content/shaders/physics_debug.vs.cso",
            "content/shaders/physics_debug.ps.cso",
        );
    };

    const depth_texture = grfx.createCommittedResource(
        .DEFAULT,
        d3d12.HEAP_FLAG_NONE,
        &blk: {
            var desc = d3d12.RESOURCE_DESC.initTex2d(.D32_FLOAT, grfx.viewport_width, grfx.viewport_height, 1);
            desc.Flags = d3d12.RESOURCE_FLAG_ALLOW_DEPTH_STENCIL | d3d12.RESOURCE_FLAG_DENY_SHADER_RESOURCE;
            break :blk desc;
        },
        d3d12.RESOURCE_STATE_DEPTH_WRITE,
        &d3d12.CLEAR_VALUE.initDepthStencil(.D32_FLOAT, 1.0, 0),
    ) catch |err| hrPanic(err);

    const depth_texture_dsv = grfx.allocateCpuDescriptors(.DSV, 1);
    grfx.device.CreateDepthStencilView(grfx.getResource(depth_texture), null, depth_texture_dsv);

    //
    // Begin frame to init/upload resources to the GPU.
    //
    grfx.beginFrame();
    grfx.endFrame();
    grfx.beginFrame();

    pix.beginEventOnCommandList(@ptrCast(*d3d12.IGraphicsCommandList, grfx.cmdlist), "GPU init");

    var gui = gr.GuiContext.init(&arena_allocator.allocator, &grfx);

    _ = pix.endEventOnCommandList(@ptrCast(*d3d12.IGraphicsCommandList, grfx.cmdlist));

    grfx.endFrame();
    grfx.finishGpuCommands();

    _ = pix.endCapture();

    return .{
        .grfx = grfx,
        .gui = gui,
        .frame_stats = lib.FrameStats.init(),
        .brush = brush,
        .info_txtfmt = info_txtfmt,
        .physics_world = physics_world,
        .physics_debug = physics_debug,
        .sphere_shape = sphere_shape,
        .ground_shape = ground_shape,
        .bodies = bodies,
        .physics_debug_pso = physics_debug_pso,
        .depth_texture = depth_texture,
        .depth_texture_dsv = depth_texture_dsv,
        .camera = .{
            .position = Vec3.init(0.0, 1.0, 0.0),
            .forward = Vec3.initZero(),
            .pitch = 0.0,
            .yaw = 0.0 * math.pi,
        },
        .mouse = .{
            .cursor_prev_x = 0,
            .cursor_prev_y = 0,
        },
        .pick = .{
            .body = null,
            .saved_activation_state = 0,
            .saved_linear_damping = 0.0,
            .saved_angular_damping = 0.0,
            .constraint = null,
            .distance = 0.0,
        },
    };
}

fn deinit(demo: *DemoState, gpa: *std.mem.Allocator) void {
    demo.grfx.finishGpuCommands();
    _ = demo.brush.Release();
    _ = demo.info_txtfmt.Release();
    _ = demo.grfx.releasePipeline(demo.physics_debug_pso);
    _ = demo.grfx.releaseResource(demo.depth_texture);
    demo.gui.deinit(&demo.grfx);
    demo.grfx.deinit();
    lib.deinitWindow(gpa);
    if (demo.pick.constraint != null) {
        c.cbtWorldRemoveConstraint(demo.physics_world, demo.pick.constraint);
        c.cbtConDestroy(demo.pick.constraint);
    }
    for (demo.bodies) |body| {
        c.cbtWorldRemoveBody(demo.physics_world, body);
        c.cbtBodyDestroy(body);
    }
    c.cbtBodyDeallocate(demo.bodies.len, &demo.bodies);
    c.cbtShapeDestroy(demo.sphere_shape);
    c.cbtShapeDestroy(demo.ground_shape);
    c.cbtShapeDeallocate(demo.ground_shape);
    c.cbtShapeDeallocate(demo.sphere_shape);
    demo.physics_debug.deinit();
    gpa.destroy(demo.physics_debug);
    c.cbtWorldDestroy(demo.physics_world);
    demo.* = undefined;
}

fn update(demo: *DemoState) void {
    const dt = demo.frame_stats.delta_time;

    demo.frame_stats.update();
    lib.newImGuiFrame(dt);

    _ = c.cbtWorldStepSimulation(demo.physics_world, dt, 1, 1.0 / 60.0);

    // Handle camera rotation with mouse.
    {
        var pos: w.POINT = undefined;
        _ = w.GetCursorPos(&pos);
        const delta_x = @intToFloat(f32, pos.x) - @intToFloat(f32, demo.mouse.cursor_prev_x);
        const delta_y = @intToFloat(f32, pos.y) - @intToFloat(f32, demo.mouse.cursor_prev_y);
        demo.mouse.cursor_prev_x = pos.x;
        demo.mouse.cursor_prev_y = pos.y;

        if (w.GetAsyncKeyState(w.VK_RBUTTON) < 0) {
            demo.camera.pitch += 0.0025 * delta_y;
            demo.camera.yaw += 0.0025 * delta_x;
            demo.camera.pitch = math.min(demo.camera.pitch, 0.48 * math.pi);
            demo.camera.pitch = math.max(demo.camera.pitch, -0.48 * math.pi);
            demo.camera.yaw = vm.modAngle(demo.camera.yaw);
        }
    }

    // Handle camera movement with 'WASD' keys.
    {
        const speed: f32 = 5.0;
        const delta_time = demo.frame_stats.delta_time;
        const transform = Mat4.initRotationX(demo.camera.pitch).mul(Mat4.initRotationY(demo.camera.yaw));
        var forward = Vec3.init(0.0, 0.0, 1.0).transform(transform).normalize();

        demo.camera.forward = forward;
        const right = Vec3.init(0.0, 1.0, 0.0).cross(forward).normalize().scale(speed * delta_time);
        forward = forward.scale(speed * delta_time);

        if (w.GetAsyncKeyState('W') < 0) {
            demo.camera.position = demo.camera.position.add(forward);
        } else if (w.GetAsyncKeyState('S') < 0) {
            demo.camera.position = demo.camera.position.sub(forward);
        }
        if (w.GetAsyncKeyState('D') < 0) {
            demo.camera.position = demo.camera.position.add(right);
        } else if (w.GetAsyncKeyState('A') < 0) {
            demo.camera.position = demo.camera.position.sub(right);
        }
    }

    const mouse_button_is_down = w.GetAsyncKeyState(w.VK_LBUTTON) < 0;

    const ray_from = demo.camera.position;
    const ray_to = blk: {
        var ui = c.igGetIO().?;
        const mousex = ui.*.MousePos.x;
        const mousey = ui.*.MousePos.y;

        const far_plane: f32 = 10000.0;
        const tanfov = math.tan(0.5 * camera_fovy);
        const width = @intToFloat(f32, demo.grfx.viewport_width);
        const height = @intToFloat(f32, demo.grfx.viewport_height);
        const aspect = width / height;

        const ray_forward = demo.camera.forward.scale(far_plane);

        var hor = Vec3.init(0, 1, 0).cross(ray_forward).normalize();
        var vertical = hor.cross(ray_forward).normalize();

        hor = hor.scale(2.0 * far_plane * tanfov * aspect);
        vertical = vertical.scale(2.0 * far_plane * tanfov);

        const ray_to_center = ray_from.add(ray_forward);
        const dhor = hor.scale(1.0 / width);
        const dvert = vertical.scale(1.0 / height);

        var ray_to = ray_to_center.sub(hor.scale(0.5)).sub(vertical.scale(0.5));
        ray_to = ray_to.add(dhor.scale(mousex));
        ray_to = ray_to.add(dvert.scale(mousey));

        break :blk ray_to;
    };

    if (demo.pick.constraint == null and mouse_button_is_down) {
        var result: c.CbtRayCastResult = undefined;
        const hit = c.cbtRayTestClosest(
            demo.physics_world,
            &ray_from.c,
            &ray_to.c,
            c.CBT_COLLISION_FILTER_DEFAULT,
            c.CBT_COLLISION_FILTER_ALL,
            c.CBT_RAYCAST_FLAG_USE_USE_GJK_CONVEX_TEST,
            &result,
        );

        if (hit == c.CBT_TRUE and result.body != null and c.cbtBodyIsStaticOrKinematic(result.body) == c.CBT_FALSE) {
            demo.pick.body = result.body;

            demo.pick.saved_linear_damping = c.cbtBodyGetLinearDamping(result.body);
            demo.pick.saved_angular_damping = c.cbtBodyGetLinearDamping(result.body);
            c.cbtBodySetDamping(result.body, 0.4, 0.4);

            demo.pick.saved_activation_state = c.cbtBodyGetActivationState(result.body);
            if (demo.pick.saved_activation_state == c.CBT_ISLAND_SLEEPING) {
                demo.pick.saved_activation_state = c.CBT_ACTIVE_TAG;
            }
            c.cbtBodySetActivationState(result.body, c.CBT_DISABLE_DEACTIVATION);
            c.cbtBodySetDeactivationTime(result.body, 0.0);

            var inv_trans: [4]c.CbtVector3 = undefined;
            c.cbtBodyGetInvCenterOfMassTransform(result.body, &inv_trans);
            const hit_point_world = Vec3{ .c = result.hit_point_world };
            const pivot_a = hit_point_world.transform(Mat4.initArray4x3(inv_trans));

            const p2p = c.cbtConCreatePoint2Point(
                result.body,
                c.cbtConGetFixedBody(),
                &pivot_a.c,
                &result.hit_point_world,
            );
            c.cbtWorldAddConstraint(demo.physics_world, p2p, 1);
            demo.pick.constraint = p2p;
            demo.pick.distance = hit_point_world.sub(ray_from).length();

            c.cbtConPoint2PointSetImpulseClamp(p2p, 30.0);
            c.cbtConPoint2PointSetTau(p2p, 0.001);
        }
    } else if (demo.pick.constraint != null) {
        const to = ray_from.add(ray_to.normalize().scale(demo.pick.distance));
        c.cbtConPoint2PointSetPivotB(demo.pick.constraint, &to.c);
    }

    if (!mouse_button_is_down and demo.pick.constraint != null) {
        c.cbtWorldRemoveConstraint(demo.physics_world, demo.pick.constraint);
        c.cbtConDestroy(demo.pick.constraint);
        c.cbtBodyForceActivationState(demo.pick.body, demo.pick.saved_activation_state);
        c.cbtBodySetDamping(demo.pick.body, demo.pick.saved_linear_damping, demo.pick.saved_angular_damping);
        demo.pick.constraint = null;
        demo.pick.body = null;
    }
}

fn draw(demo: *DemoState) void {
    var grfx = &demo.grfx;
    grfx.beginFrame();

    const cam_world_to_view = Mat4.initLookToLh(
        demo.camera.position,
        demo.camera.forward,
        Vec3.init(0.0, 1.0, 0.0),
    );
    const cam_view_to_clip = Mat4.initPerspectiveFovLh(
        camera_fovy,
        @intToFloat(f32, grfx.viewport_width) / @intToFloat(f32, grfx.viewport_height),
        0.1,
        50.0,
    );
    const cam_world_to_clip = cam_world_to_view.mul(cam_view_to_clip);

    const back_buffer = grfx.getBackBuffer();

    grfx.addTransitionBarrier(back_buffer.resource_handle, d3d12.RESOURCE_STATE_RENDER_TARGET);
    grfx.flushResourceBarriers();

    grfx.cmdlist.OMSetRenderTargets(
        1,
        &[_]d3d12.CPU_DESCRIPTOR_HANDLE{back_buffer.descriptor_handle},
        w.TRUE,
        &demo.depth_texture_dsv,
    );
    grfx.cmdlist.ClearDepthStencilView(demo.depth_texture_dsv, d3d12.CLEAR_FLAG_DEPTH, 1.0, 0, 0, null);
    grfx.cmdlist.ClearRenderTargetView(
        back_buffer.descriptor_handle,
        &[4]f32{ 0.1, 0.2, 0.4, 1.0 },
        0,
        null,
    );

    c.cbtWorldDebugDraw(demo.physics_world);
    if (demo.physics_debug.lines.items.len > 0) {
        grfx.setCurrentPipeline(demo.physics_debug_pso);
        grfx.cmdlist.IASetPrimitiveTopology(.LINELIST);
        {
            const mem = grfx.allocateUploadMemory(Mat4, 1);
            mem.cpu_slice[0] = cam_world_to_clip.transpose();
            grfx.cmdlist.SetGraphicsRootConstantBufferView(0, mem.gpu_base);
        }
        const num_vertices = @intCast(u32, demo.physics_debug.lines.items.len);
        {
            const mem = grfx.allocateUploadMemory(PsoPhysicsDebug_Vertex, num_vertices);
            for (demo.physics_debug.lines.items) |p, i| {
                mem.cpu_slice[i] = p;
            }
            grfx.cmdlist.SetGraphicsRootShaderResourceView(1, mem.gpu_base);
        }
        grfx.cmdlist.DrawInstanced(num_vertices, 1, 0, 0);
        demo.physics_debug.lines.resize(0) catch unreachable;
    }

    demo.gui.draw(grfx);

    grfx.beginDraw2d();
    {
        const stats = &demo.frame_stats;
        var buffer = [_]u8{0} ** 64;
        const text = std.fmt.bufPrint(
            buffer[0..],
            "FPS: {d:.1}\nCPU time: {d:.3} ms",
            .{ stats.fps, stats.average_cpu_time },
        ) catch unreachable;

        demo.brush.SetColor(&.{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 });
        lib.drawText(
            grfx.d2d.context,
            text,
            demo.info_txtfmt,
            &d2d1.RECT_F{
                .left = 10.0,
                .top = 10.0,
                .right = @intToFloat(f32, grfx.viewport_width),
                .bottom = @intToFloat(f32, grfx.viewport_height),
            },
            @ptrCast(*d2d1.IBrush, demo.brush),
        );
    }
    grfx.endDraw2d();

    grfx.endFrame();
}

pub fn main() !void {
    lib.init();
    defer lib.deinit();

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa_allocator.deinit();
        std.debug.assert(leaked == false);
    }
    const gpa = &gpa_allocator.allocator;

    var demo = init(gpa);
    defer deinit(&demo, gpa);

    while (true) {
        var message = std.mem.zeroes(w.user32.MSG);
        const has_message = w.user32.peekMessageA(&message, null, 0, 0, w.user32.PM_REMOVE) catch false;
        if (has_message) {
            _ = w.user32.translateMessage(&message);
            _ = w.user32.dispatchMessageA(&message);
            if (message.message == w.user32.WM_QUIT) {
                break;
            }
        } else {
            update(&demo);
            draw(&demo);
        }
    }
}
