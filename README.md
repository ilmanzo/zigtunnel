# Zigtunnel

A mesmerizing 3D tunnel effect written in [Zig](https://ziglang.org/), powered by [Raylib](https://www.raylib.com/).

## Demo

![Demo](screencast.gif)

## Overview

Zigtunnel renders a procedurally generated, colorful tunnel with a pulsing, breathing animation. The tunnel features:

- **Rainbow gradient texture** with dynamic HSL-to-RGB color conversion
- **Grid pattern** that creates depth and motion perception
- **Sinusoidal animation** that makes the tunnel smoothly accelerate and decelerate
- **Polar coordinate mapping** for authentic tunnel perspective

The entire texture is generated procedurally—no image files required. All rendering math is precomputed for blazing-fast frame rates.

## Features

- 🎨 Vibrant rainbow colors with dynamic patterns
- 🌊 Smooth sinusoidal animation with reversible motion
- ⚡ Optimized rendering with lookup tables
- 🎯 Procedural texture generation
- 🔧 Resizable window support
- 📊 Real-time FPS counter

## Building

### Prerequisites

- [Zig](https://ziglang.org/) (master branch recommended)
- A C compiler (gcc, clang, or MSVC)

### Build & Run

```bash
zig build run
```

### Release Build

```bash
zig build -Doptimize=ReleaseFast run
```

## How It Works

1. **Texture Generation**: A 256×256 procedural texture is created with:
   - Hue gradient across the X-axis (rainbow colors)
   - Brightness gradient across the Y-axis
   - Repeating stripe and line patterns for visual depth

2. **Coordinate Mapping**: For each screen pixel:
   - Calculate angle and distance from screen center
   - Map to polar coordinates (U, V texture coordinates)
   - Add animated shifts to create motion

3. **Animation**: Speed varies sinusoidally over time, creating a natural "breathing" tunnel effect that accelerates, reverses, and decelerates smoothly.

## Controls

- **Close window**: Exit the tunnel
- **Resize window**: Window is fully resizable
- **FPS counter**: Displayed in top-left corner

## Customization

Edit these constants in `src/main.zig` to tweak the experience:

```zig
const TUNNEL_RADIUS = 32.0;              // Affects tunnel "tightness"
const ANIMATION_CYCLE_TIME = 4.0;        // Seconds for full animation cycle
const STRIPE_WIDTH = 8;                  // Grid stripe thickness
const LINE_HEIGHT = 16;                  // Grid line height
```

## Performance

- **Precomputed lookup tables**: Angle and distance calculations happen once at startup
- **Efficient rendering**: Single-pass linear buffer iteration
- **Smooth 60 FPS**: Optimized for modern hardware

## Technical Stack

- **Language**: [Zig](https://ziglang.org/)
- **Graphics**: [Raylib 5.x](https://www.raylib.com/)
- **Build System**: Zig build system

## License

MIT

## Credits

Built with ❤️ using Zig and Raylib
