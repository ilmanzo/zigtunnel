const std = @import("std");
const raylib = @import("raylib");

// Constants
const SCREEN_W = 800;
const SCREEN_H = 600;
const TEX_W = 256;
const TEX_H = 256;
const TUNNEL_RADIUS = 32.0;
const ANIMATION_ROTATION_SPEED_MAX = 2.0;
const ANIMATION_FORWARD_SPEED_MAX = 2.0;
const ANIMATION_CYCLE_TIME = 5.0; // seconds for full cycle

/// Convert HSL color space to RGB
fn hslToRgb(h: f32, s: f32, l: f32) raylib.Color {
    const c = (1.0 - @abs(2.0 * l - 1.0)) * s;
    const h_prime = h * 6.0;
    const x = c * (1.0 - @abs(@mod(h_prime, 2.0) - 1.0));

    const m = l - c / 2.0;

    const rgb_array = switch (@as(u3, @intFromFloat(h_prime))) {
        0 => [3]f32{ c, x, 0.0 },
        1 => [3]f32{ x, c, 0.0 },
        2 => [3]f32{ 0.0, c, x },
        3 => [3]f32{ 0.0, x, c },
        4 => [3]f32{ x, 0.0, c },
        else => [3]f32{ c, 0.0, x },
    };

    return raylib.Color{
        .r = @intFromFloat((rgb_array[0] + m) * 255.0),
        .g = @intFromFloat((rgb_array[1] + m) * 255.0),
        .b = @intFromFloat((rgb_array[2] + m) * 255.0),
        .a = 255,
    };
}

/// Generate procedural rainbow texture with grid pattern
fn generateTexture(pixels: []raylib.Color) void {
    for (0..TEX_H) |y| {
        for (0..TEX_W) |x| {
            const hue = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(TEX_W));
            const base_lightness = 0.3 + 0.4 * @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(TEX_H));

            const stripe = @as(f32, @floatFromInt((x / 8) % 2));
            const line = @as(f32, @floatFromInt((y / 16) % 2));
            const pattern = 0.15 * (stripe + line) - 0.1;
            const lightness = std.math.clamp(base_lightness + pattern, 0.0, 1.0);

            pixels[y * TEX_W + x] = hslToRgb(hue, 1.0, lightness);
        }
    }
}

/// Precompute lookup tables for tunnel coordinates
fn precomputeLookupTables(angle_lut: []u32, dist_lut: []u32) void {
    const center_x = SCREEN_W / 2.0;
    const center_y = SCREEN_H / 2.0;

    for (0..SCREEN_H) |y| {
        for (0..SCREEN_W) |x| {
            const idx = y * SCREEN_W + x;
            const dx = @as(f32, @floatFromInt(x)) - center_x;
            const dy = @as(f32, @floatFromInt(y)) - center_y;

            const distance = std.math.sqrt(dx * dx + dy * dy);
            const angle = std.math.atan2(dy, dx);
            const angle_norm = (angle + std.math.pi) / (2.0 * std.math.pi);

            angle_lut[idx] = @intFromFloat(angle_norm * @as(f32, TEX_W));

            const safe_dist = @max(distance, 1.0);
            dist_lut[idx] = @intFromFloat((TUNNEL_RADIUS * @as(f32, TEX_H)) / safe_dist);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize raylib
    raylib.initWindow(SCREEN_W, SCREEN_H, "Zig Tunnel");
    defer raylib.closeWindow();
    raylib.setConfigFlags(.{ .window_resizable = false });
    raylib.setTargetFPS(1000);

    // Generate texture
    const texture_pixels = try allocator.alloc(raylib.Color, TEX_W * TEX_H);
    defer allocator.free(texture_pixels);
    generateTexture(texture_pixels);

    // Allocate buffers
    const pixel_count = SCREEN_W * SCREEN_H;
    const screen_buffer = try allocator.alloc(raylib.Color, pixel_count);
    defer allocator.free(screen_buffer);

    const angle_lut = try allocator.alloc(u32, pixel_count);
    defer allocator.free(angle_lut);

    const dist_lut = try allocator.alloc(u32, pixel_count);
    defer allocator.free(dist_lut);

    precomputeLookupTables(angle_lut, dist_lut);

    // Create screen texture
    const screen_texture = try raylib.loadTextureFromImage(
        raylib.genImageColor(SCREEN_W, SCREEN_H, raylib.Color.black),
    );
    defer raylib.unloadTexture(screen_texture);

    var shift_x: f32 = 0.0;
    var shift_y: f32 = 0.0;
    var elapsed_time: f32 = 0.0;

    // Main loop
    while (!raylib.windowShouldClose()) {
        // Update animation
        const dt = raylib.getFrameTime();
        elapsed_time += dt;

        // Calculate sinusoidal variation from -1 to 1
        const angle = (elapsed_time / ANIMATION_CYCLE_TIME) * std.math.pi;
        const rotation_speed = ANIMATION_ROTATION_SPEED_MAX * std.math.sin(angle);
        const forward_speed = ANIMATION_FORWARD_SPEED_MAX * std.math.sin(angle);

        shift_x += rotation_speed * dt * 60.0;
        shift_y += forward_speed * dt * 120.0;

        const shift_u: u32 = @intFromFloat(shift_x);
        const shift_v: u32 = @intFromFloat(shift_y);

        // Render tunnel
        for (0..pixel_count) |i| {
            const u = (angle_lut[i] + shift_u) % TEX_W;
            const v = (dist_lut[i] + shift_v) % TEX_H;
            screen_buffer[i] = texture_pixels[v * TEX_W + u];
        }

        raylib.updateTexture(screen_texture, screen_buffer.ptr);

        // Draw!
        raylib.beginDrawing();
        raylib.clearBackground(raylib.Color.black);
        raylib.drawTexture(screen_texture, 0, 0, raylib.Color.white);
        raylib.drawFPS(10, 10); // FPS counter
        raylib.endDrawing();
    }
}
