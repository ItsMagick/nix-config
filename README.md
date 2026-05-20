# NixOS Hyprland Configuration

A declarative, reproducible NixOS system configuration featuring **Hyprland** (Wayland compositor), **Quickshell** (QML-based widget framework), and **Matugen** (dynamic color theming). Optimized for laptop usage with power management, hibernation, and efficient resource utilization.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Configuration](#core-configuration)
   - [Flake](#flake)
   - [System Configuration](#system-configuration)
   - [Home Configuration](#home-configuration)
4. [Modules](#modules)
   - [4.1 Rofi](#41-rofi-launcher)
   - [4.2 Neovim](#42-neovim-editor)
   - [4.3 Hyprland](#43-hyprland-compositor)
   - [4.4 Waybar](#44-waybar-statusbar)
   - [Matugen](#matugen-color-generation)
   - [Zsh Shell](#zsh-shell)
5. [Scripts](#scripts)
   - [5.1 Quickshell Widget System](#51-quickshell-widget-system)
   - [Script Manager](#qs_managersh-ipc-orchestrator)
6. [Power Management](#power-management--laptop-optimization)
7. [How It All Works](#how-it-all-works)

---

## Overview

This flake-based NixOS config transforms your system into a beautiful, cohesive desktop environment combining:

- **Hyprland**: Modern Wayland compositor with dynamic tiling and gap management
- **Quickshell**: QML-based widget system for custom applets (battery, calendar, music, network, wallpaper picker)
- **Matugen**: Dynamic color palette generation from wallpapers (Material Design 3)
- **Catppuccin**: Pre-built color schemes (Macchiato + Lavender accent)
- **Waybar**: Top status bar for workspace, clock, battery, network, and audio controls
- **FiraCode Nerd Font**: Unified typography across all applications

**Key optimizations for laptops:**
- TLP for CPU frequency scaling and thermal management
- 32GB swapfile + hibernation support
- Battery charge thresholds (40–80%) to extend battery lifespan
- Suspend-then-hibernate on lid close (power-efficient default)

---

## Architecture

### High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  Hyprland (Compositor)                      │
│ - Monitors & workspaces                                     │
│ - Keybinds trigger qs_manager.sh or rofi                    │
└────────┬────────────────────────────────────────────────────┘
│
├─► qs_manager.sh (IPC Orchestrator)
│   - Parses keybind args (open/toggle/close)
│   - Writes widget state to /tmp/qs_widget_state
│   - Manages wallpaper thumbnail generation
│
└─► Main.qml (Quickshell Singleton)
- Polls /tmp/qs_widget_state for IPC
- Manages widget lifecycle (mount/unmount)
- Handles morphing animations & focus
- Tracks active widget in /tmp/qs_active_widget
│
└─► Individual Widgets (QML applets)
├── BatteryPopup.qml
├── CalendarPopup.qml
├── MusicPopup.qml
├── NetworkPopup.qml
├── WallpaperPicker.qml
└── ... (6 total widgets)
```

### Color Flow

```
Wallpaper → Matugen (color extraction) → Generated palettes
├── hyprland-colors.conf
├── waybar.css
└── rofi.rasi

Catppuccin (static) → System fallback if Matugen unavailable
```

### Configuration Layering

1. **NixOS System** ([`configuration.nix`](#configuration-nix)) — Hardware, boot, services, system packages
2. **Home Manager** ([`home.nix`](#home-nix)) — User environment, CLI tools, UI theming
3. **Modules** ([`modules/`](#modules)) — Modular config for Hyprland, Waybar, Rofi, etc.
4. **Scripts** ([`scripts/`](#scripts)) — Shell orchestrators, QML widgets, helper tools
5. **Matugen** ([`modules/matugen/`](#matugen)) — Color template generation and output directories

---

## Core Configuration

### [Flake (`flake.nix`)](./flake.nix)

The entry point for NixOS + Home Manager integration.

**Function:**
- Declares inputs: `nixpkgs`, `home-manager`, `catppuccin`, `matugen`, `spicetify-nix`, `zen-browser`
- Outputs single system config: `nixosConfigurations.TPS`
- Passes `inputs` to modules for direct flake reference access

**Key setup:**
```nix
inputs.nixpkgs.follows = "nixpkgs"  # Keep all flakes on same nixpkgs version
useGlobalPkgs = true                 # Use system nixpkgs, avoid duplication
useUserPackages = true               # User environment uses system packages
```

**Extension point:** Add new flake inputs here (e.g., `stylix`, `niri-compositor`), then forward to modules.

---

### [System Configuration (`configuration.nix`)](./configuration.nix)

Declarative system-wide settings (requires `sudo nixos-rebuild switch`).

**Sections:**

| Section              | Purpose                                     | Key Settings                                                                  |
|----------------------|---------------------------------------------|-------------------------------------------------------------------------------|
| **Boot**             | UEFI, kernel params, resume for hibernation | `resume_offset`, `mem_sleep_default=deep`, `systemd-boot`                     |
| **Hardware**         | CPU, GPU, Bluetooth, Firmware               | AMD CPU microcode, graphics enabled, Bluetooth auto-connect                   |
| **Networking**       | Hostname, NetworkManager                    | `hostName = "TPS"`                                                            |
| **Services**         | System daemons                              | Hyprland, SDDM, PipeWire audio, TLP (power), Blueman                          |
| **Power Management** | Laptop efficiency                           | TLP CPU gov, battery charge thresholds (40–80%), lid → suspend-then-hibernate |
| **Fonts**            | System-wide glyphs                          | `Nerd Fonts Fira Code`                                                        |
| **Virtualization**   | Docker support                              | Enabled with user in `docker` group                                           |

**Hibernation setup:**
- Swapfile at `/var/lib/swapfile` (32 GB, defined in `swapDevices`)
- Kernel resumption via `resume_offset` UUID
- Governed by logind settings (lid switch → `suspend-then-hibernate`)

---

### [Home Configuration (`home.nix`)](./home.nix)

User-level packages and session setup (managed by Home Manager).

**Session Variables:**
- `GTK_THEME = "catppuccin-macchiato-lavender-standard"`
- `COLORTERM = "truecolor"` (enable true color in terminals)

**Key packages:**
- **UI**: Kitty (terminal), Vesktop (Discord), Zotero (research)
- **Theming**: Pywal, Matugen, Catppuccin
- **Quickshell ecosystem**: `quickshell`, `awww` (wallpaper setter)
- **System tools**: Brightnessctl, Playerctl, Btop, NetworkManager

**XDG Portal + GTK config:**
- Dark theme enforced for GTK3/GTK4
- Qt6 uses Kvantum style
- Icon theme defaults to Papirus-Dark (set in modules)

**Imports:**
- `./modules` — All modular Nix configurations
- `./scripts` — Script packages and symlink definitions

---

## Modules

All modules live in [`modules/`](./modules) and are imported via [`modules/default.nix`](./modules/default.nix).

### _Module Imports Hierarchy_

```
home.nix
  ├── modules/default.nix
  │   ├── spicetify.nix      (Spotify customization)
  │   ├── hyprland.nix       (Compositor + keybinds)
  │   ├── kitty.nix          (Terminal)
  │   ├── zsh.nix            (Shell)
  │   ├── waybar.nix         (Status bar)
  │   ├── rofi.nix           (App launcher)
  │   ├── swayidle.nix       (Idle/lock daemon)
  │   ├── network-manager.nix (WiFi/Bluetooth UI)
  │   ├── catppuccin.nix     (Color scheme defaults)
  │   ├── nvim.nix           (Neovim editor)
  │   ├── eww/default.nix    (Eww widgets – legacy)
  │   ├── matugen/default.nix(Color generation)
  │   └── quickshell-symlinks.nix (QS symlinks)
```

---

### 4.1 Rofi (Launcher)

**File:** [`modules/rofi.nix`](./modules/rofi.nix) | **Dir:** [`modules/rofi/`](./modules/rofi)

Rofi is a highly customizable launcher, window switcher, and menu system. In this config, it serves three roles:

1. **Application Launcher** (`Super+R`) — fuzzy search installed programs
2. **Window Switcher** (`Alt+Tab`) — switch between open windows
3. **Theme/Wallpaper Menu** — manual fallback UI (triggered by [`rofi_show.sh`](./scripts/rofi_show.sh))

**Configuration:**
- Theme sourced from [`modules/rofi/theme.rasi`](./modules/rofi/theme.rasi)
- Color palette auto-regenerated by Matugen → `~/.config/rofi/matugen.rasi`
- Icons use **Catppuccin Papirus** for consistent theming

**Integration points:**
- **Hyprland keybind:** `$mainMod, R, exec, rofi -show drun`
- **Window switcher:** `ALT, TAB, exec, rofi -show window`
- **Secondary:** Called by [`scripts/rofi_show.sh`](./scripts/rofi_show.sh) for custom configurations (rarely used; Quickshell is primary UI)

**File references:**
- Config: `~/.config/rofi/config.rasi` ← [`modules/rofi/config.rasi`](./modules/rofi/config.rasi)
- Theme: `~/.config/rofi/theme.rasi` ← [`modules/rofi/theme.rasi`](./modules/rofi/theme.rasi)

---

### 4.2 Neovim (Editor)

**File:** [`modules/nvim.nix`](./modules/nvim.nix) | **Dir:** [`modules/nvim/`](./modules/nvim)

Declarative Neovim setup with LSPs, formatters, and plugin manager integration.

**Key features:**
- **LSP support:** lua-language-server, nil (Nix), stylua (formatter)
- **Build tools:** gcc, nodejs, python3 (for plugin compatibility)
- **Default editor:** `nvim` becomes system default editor

**Configuration:**
- Init file: [`modules/nvim/init.lua`](./modules/nvim/init.lua)
- Plugin system: Managed via [`modules/nvim/lua/custom/plugins.lua`](./modules/nvim/lua/custom/plugins.lua) (Chad's NvChad distribution)
- Core config: [`modules/nvim/lua/core/init.lua`](./modules/nvim/lua/core/init.lua)

**Usage:**
```bash
nvim <file>  # Opens file in configured Neovim
```

---

### 4.3 Hyprland (Compositor)

**File:** [`modules/hyprland.nix`](./modules/hyprland.nix) | **Dir:** [`modules/hyprland/`](./modules/hyprland)

Hyprland is the Wayland compositor orchestrating windows, workspaces, animations, and keyboard input.

**Architecture:**
```
Hyprland Settings (nix)
├── Monitor configuration (display output names, resolution, DPI)
├── Input handling (keyboard layout, touchpad, mouse)
├── General window properties (gaps, borders, layout engine)
├── Decorations (rounding, shadows, blur, opacity)
├── Animations (bezier curves, transition timings)
└── Keybinds (Super+*, Alt+*, XF86 keys) & exec-once startup
```

**Key Sections:**

| Setting      | Value                                                     | Purpose                                                     |
|--------------|-----------------------------------------------------------|-------------------------------------------------------------|
| **Monitor**  | `eDP-1, 1920x1080@59.98`                                  | Laptop display (built-in)                                   |
| **Input**    | `kb_layout = "de"`, `natural_scroll = true`               | German keyboard, touchpad                                   |
| **Border**   | `col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg` | Lavender→Blue gradient for active window (Matugen override) |
| **Rounding** | `10px`                                                    | Smooth window corners                                       |
| **Blur**     | `enabled = true, size = 3`                                | Background blur for depth                                   |
| **Gaps**     | `gaps_in = 5, gaps_out = 20`                              | Inner/outer spacing                                         |

**Keybinds:**

| Bind                               | Action                                       | Purpose                            |
|------------------------------------|----------------------------------------------|------------------------------------|
| `Super+Q`                          | `exec, kitty`                                | Terminal                           |
| `Super+R`                          | `exec, rofi -show drun`                      | App launcher                       |
| `Super+W`                          | `qs_manager.sh toggle wallpaper`             | Wallpaper picker (Quickshell)      |
| `Super+N`                          | `qs_manager.sh toggle network wifi`          | WiFi manager (Quickshell)          |
| `Super+Shift+N`                    | `qs_manager.sh toggle network bt`            | Bluetooth manager                  |
| `Super+D`                          | `qs_manager.sh toggle calendar`              | Calendar & events                  |
| `Super+Y`                          | `qs_manager.sh toggle music`                 | Music player (auto-starts Spotify) |
| `Super+P`                          | `qs_manager.sh toggle battery`               | Battery/power stats                |
| `Super+Escape`                     | `qs_manager.sh close`                        | Close active widget                |
| `Super+C`                          | `killactive`                                 | Kill focused window                |
| `Super+L`                          | `lock-screen`                                | Lock screen (swaylock-effects)     |
| `Super+1-5`                        | `workspace 1-5`                              | Switch workspace                   |
| `Super+Shift+1-9`                  | `movetoworkspace 1-9`                        | Move window to workspace           |
| `XF86MonBrightnessUp/Down`         | `brightnessctl set 5%±`                      | Screen brightness                  |
| `XF86AudioRaiseVolume/LowerVolume` | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%±`  | Audio volume                       |
| `XF86AudioMute`                    | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | Mute audio                         |
| `Print`                            | `grim -g "$(slurp)" - \| wl-copy`            | Screenshot to clipboard            |

**Startup (`exec-once`):**
```nix
exec-once = [
  "zsh ~/.config/hypr/scripts/session_start.sh"  # Initialize environment & Quickshell
  "zsh jetbrains-toolbox"  # Start IDE toolbox
];
```

**Matugen Integration:**
```nix
extraConfig = ''
  source = ${config.xdg.configHome}/hypr/matugen-colors.conf
''
```
Dynamically applies Matugen-generated color palette to window borders.

---

### 4.4 Waybar (Status Bar)

**File:** [`modules/waybar.nix`](./modules/waybar.nix)

Top-bar status indicator showing workspaces, time, battery, network, audio, and system stats in beautiful "island" containers.

**Layout:**
```
[Left Island: Workspaces I-VI] | [Right Island: Network/BT/CPU/Memory/Temp] [Battery: XX%] [Clock: HH:MM:SS]
```

**Module Groups:**

| Group     | Modules                                                                       | Purpose                                        |
|-----------|-------------------------------------------------------------------------------|------------------------------------------------|
| **Left**  | Workspaces + separator                                                        | Navigate between 6 workspaces (Roman numerals) |
| **Right** | Tray icons, network, status (BT/audio), system (CPU/mem/temp), battery, clock | System info & quick status                     |

**Styling:**
- **Island containers** → rounded capsule design (25px border-radius semicircles on ends)
- **Color scheme** → Matugen-generated CSS variables (`waybar_text`, `waybar_active`, etc.)
- **Font** → FiraCode Nerd Font Mono (13px, bold)
- **Interactive** → Left-click/scroll for workspace nav, right-click for network editor

**CSS Variables** (from `~/.config/waybar/matugen.css`):
```css
@define-color waybar_text #cdd6f4;              /* Main text */
@define-color waybar_active #cba6f7;           /* Active workspace (lavender) */
@define-color waybar_bg_island rgba(30,30,46,0.9); /* Semi-transparent Crust */
@define-color waybar_battery_charging #a6e3a1; /* Green when plugged */
@define-color waybar_clock_text #f0a0d0;       /* Pink clock text */
```

**Refresh behavior:**
- Battery updates every **3 seconds**
- Clock updates every **1 second**
- Network/BT status on-demand (dbus signal)

---

### Matugen (Color Generation)

**File:** [`modules/matugen/default.nix`](./modules/matugen/default.nix) | **Dir:** [`modules/matugen/`](./modules/matugen)

Dynamic color palette extraction from wallpapers using Material Design 3 algorithms.

**Workflow:**

1. **Watch wallpaper change** → Trigger Matugen
2. **Extract color scheme** → 30+ colors (primary, secondary, neutral, error, tonal palettes)
3. **Render templates** → Generate config fragments:
    - `hyprland-colors.conf` — Border colors, opacity, animations
    - `waybar.css` — CSS variable definitions for bar styling
    - `rofi.rasi` — Rofi theme colors

**Template files:**
- [`modules/matugen/templates/hyprland-colors.conf`](./modules/matugen/templates/hyprland-colors.conf)
- [`modules/matugen/templates/waybar.css`](./modules/matugen/templates/waybar.css)
- [`modules/matugen/templates/rofi.rasi`](./modules/matugen/templates/rofi.rasi)

**Output directories** (created auto on activation):
```bash
~/.config/hypr/matugen-colors.conf    # Sourced by Hyprland
~/.config/waybar/matugen.css          # Imported by Waybar CSS
~/.config/rofi/matugen.rasi           # Theme for Rofi
```

**Fallback:** If Matugen is unavailable, static Catppuccin Macchiato (Lavender) colors apply.

**Invoke manually:**
```bash
matugen image ~/Pictures/wallpaper.png  # Extract & generate configs
```

---

### Zsh Shell

**File:** [`modules/zsh.nix`](./modules/zsh.nix)

Z Shell configuration with Oh-My-Zsh integration, aliases, and history.

**Features:**
- **Completion:** Auto-completion for commands & flags
- **Autosuggestion:** Fish-like suggestions as you type
- **History:** 1000 local, 2000 saved; ignore duplicates & leading spaces
- **Theme:** Agnoster (displays git branch, user, host)
- **Aliases:** `ll`, `la`, `update` (nixos-rebuild)

**Key alias:**
```bash
update = "sudo nixos-rebuild switch --flake ~/Documents/nix-config/#TPS"
```
Quick one-liner to rebuild system after config changes.

---

## Scripts

All scripts are symlinked from [`scripts/`](./scripts) to `~/.config/hypr/scripts/` via [`modules/quickshell-symlinks.nix`](./modules/quickshell-symlinks.nix).

### 5.1 Quickshell Widget System

**Dir:** [`scripts/quickshell/`](./scripts/quickshell)

Quickshell is a **QML-based widget framework** for Wayland. This config uses it as the primary UI for desktop applets.

#### **Main.qml — Singleton Widget Manager**

**File:** [`scripts/quickshell/Main.qml`](./scripts/quickshell/Main.qml)

The **orchestrator** that manages all widgets. Think of it as the "parent process" that never dies.

**Architecture:**
```qml
FloatingWindow (qs-master)
├── currentActive property (hidden | battery | calendar | music | network | stewart | wallpaper | monitors | focustime)
├── IPC Poller (polls /tmp/qs_widget_state every ~50ms)
├── StackView (dynamically loads/unloads widget QML files)
└── Animations (morphing, fade, scale effects)
```

**Lifecycle:**

1. **Startup** (`exec-once` from Hyprland):
    - `Main.qml` loads, sets `visible=true`
    - Immediately moves off-screen via Hyprland dispatch (`movewindowpixel exact -5000 -5000`)
    - Sets `currentActive = "hidden"`

2. **Widget Request** (e.g., `Super+W`):
    - Keybind triggers: `qs_manager.sh toggle wallpaper`
    - `qs_manager.sh` writes `wallpaper` to `/tmp/qs_widget_state`
    - `Main.qml` poller detects change → sets `currentActive = "wallpaper"`
    - `StackView` loads `wallpaper/WallpaperPicker.qml`, animates into view
    - Window morphs to `1920x500` (full-width wallpaper picker)

3. **Widget Close** (e.g., `Super+Escape` or selection made):
    - Widget or `qs_manager.sh` writes `close` to `/tmp/qs_widget_state`
    - `Main.qml` sets `currentActive = "hidden"`
    - `StackView` unloads widget, window shrinks back off-screen
    - `/tmp/qs_active_widget` updates to `hidden` (state file for external scripts)

**Key properties:**

| Property          | Type   | Purpose                                                        |
|-------------------|--------|----------------------------------------------------------------|
| `currentActive`   | string | Tracks which widget is displayed; polls `/tmp/qs_widget_state` |
| `layouts`         | object | Maps widget names → dimensions, position, QML path             |
| `isVisible`       | bool   | Tracks visibility state (off-screen = false)                   |
| `morphDuration`   | int    | Animation speed (500ms default, 100ms for fast transitions)    |
| `screenW/screenH` | int    | Display dimensions (1920x1080 for single monitor)              |

**Widget Layout Definition:**
```qml
layouts: {
    "battery":   { w: 480, h: 760, x: screenW-500, y: 70, comp: "battery/BatteryPopup.qml" },
    "calendar":  { w: 1450, h: 750, x: 235, y: 70, comp: "calendar/CalendarPopup.qml" },
    "music":     { w: 700, h: 620, x: 12, y: 70, comp: "music/MusicPopup.qml" },
    "network":   { w: 900, h: 700, x: screenW-920, y: 70, comp: "network/NetworkPopup.qml" },
    "wallpaper": { w: 1920, h: 500, x: 0, y: 290, comp: "wallpaper/WallpaperPicker.qml" },
    ...
}
```

**State Files:**
- **Input:** `/tmp/qs_widget_state` — IPC file written by `qs_manager.sh`
- **Output:** `/tmp/qs_active_widget` — Widget name written by `Main.qml` for external scripts to read

**Animation Flow:**
```
morphDuration = 500ms (default), 100ms (fast for wallpaper)
├── Width morph: 1→target (500ms)
├── Height morph: 1→target (500ms)
├── Opacity fade: 0→1 (300-350ms, slightly faster)
└── Child widget crossfades in/out (350ms each)
```

#### **Individual Widget QML Files**

Each widget is a self-contained QML component:

| Widget        | File                                                                                  | Purpose                                                    |
|---------------|---------------------------------------------------------------------------------------|------------------------------------------------------------|
| **Battery**   | [`battery/BatteryPopup.qml`](./scripts/quickshell/battery/BatteryPopup.qml)           | Battery %, health, charge/discharge rate                   |
| **Calendar**  | [`calendar/CalendarPopup.qml`](./scripts/quickshell/calendar/CalendarPopup.qml)       | Month/year calendar + diary entries + schedule integration |
| **Music**     | [`music/MusicPopup.qml`](./scripts/quickshell/music/MusicPopup.qml)                   | Spotify player controls (requires Spicetify + mpris)       |
| **Network**   | [`network/NetworkPopup.qml`](./scripts/quickshell/network/NetworkPopup.qml)           | WiFi/BT panel with connection switching                    |
| **Wallpaper** | [`wallpaper/WallpaperPicker.qml`](./scripts/quickshell/wallpaper/WallpaperPicker.qml) | Grid of 3×2 wallpaper thumbnails, click to apply           |
| **Monitors**  | [`monitors/MonitorPopup.qml`](./scripts/quickshell/monitors/MonitorPopup.qml)         | Display arrangement & resolution (future use)              |
| **FocusTime** | [`focustime/FocusTimePopup.qml`](./scripts/quickshell/focustime/FocusTimePopup.qml)   | Pomodoro timer + distraction blocker                       |
| **Stewart**   | [`stewart/stewart.qml`](./scripts/quickshell/stewart/stewart.qml)                     | Calendar overlay (event details)                           |

**Widget Communication:**
- Widgets read state from `~/.cache/` or shell command outputs
- Most widgets call shell scripts (e.g., `network/wifi_panel_logic.sh`) to toggle connections
- Wallpaper picker calls `awww` to apply wallpaper, then triggers Matugen regeneration

---

### qs_manager.sh — IPC Orchestrator

**File:** [`scripts/qs_manager.sh`](./scripts/qs_manager.sh)

The **coordinator** between Hyprland keybinds and Quickshell widgets. Receives commands, manages state, generates resources.

**Function:**
```bash
qs_manager.sh <ACTION> <TARGET> [SUBTARGET]

ACTION:   open | toggle | close | generate-thumbs
TARGET:   battery | calendar | music | network | wallpaper | monitors | focustime | stewart | close
SUBTARGET: wifi | bt (for network target)
```

**Common invocations:**
```bash
qs_manager.sh toggle wallpaper        # Open wallpaper picker, or close if open
qs_manager.sh open network wifi       # Force-open WiFi manager
qs_manager.sh close                   # Close active widget
qs_manager.sh generate-thumbs         # Pre-generate wallpaper thumbnails
```

**Internal workflow (simplified):**

1. **Parse arguments** → Extract `ACTION`, `TARGET`, `SUBTARGET`
2. **Read state** → Check `/tmp/qs_active_widget` to know if widget is open
3. **Handle action:**
    - **`open`**: Write `TARGET` to `/tmp/qs_widget_state`
    - **`toggle`**: If `TARGET` is active, write `close`; else write `TARGET`
    - **`close`**: Write `close` to `/tmp/qs_widget_state`
    - **`generate-thumbs`**: Pre-generate wallpaper thumbnails in `~/.cache/wallpaper_picker/thumbs/`
4. **Special handling:**
    - **Network**: Track WiFi vs. BT mode in `/tmp/qs_network_mode`
    - **Wallpaper**: Compute current wallpaper, call `generate_wallpaper_thumbs()`, set `$WALLPAPER_THUMB` env var

**Wallpaper thumbnail generation:**
```bash
# For images: resize to h=420px
magick "$img" -resize x420 -quality 70 "$thumb"

# For videos: extract frame at 5s
ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 "$thumb"
```

**State file format:**
```bash
/tmp/qs_widget_state       # Single line: widget name or "close"
/tmp/qs_active_widget      # Single line: currently active widget (read-only output)
/tmp/qs_network_mode       # Single line: "wifi" or "bt" (for network widget)
```

---

### Other Key Scripts

| Script                                             | Purpose                                                                        |
|----------------------------------------------------|--------------------------------------------------------------------------------|
| [`session_start.sh`](./scripts/session_start.sh)   | Runs at Hyprland startup via `exec-once`; initializes Quickshell, Waybar, etc. |
| [`rofi_show.sh`](./scripts/rofi_show.sh)           | Legacy launcher fallback; rarely used (Quickshell is primary)                  |
| [`screenshot.sh`](./scripts/screenshot.sh)         | Wrapper for Grim + Slurp for screenshot regions                                |
| [`volume.sh`](./scripts/volume.sh)                 | Audio volume control wrapper (uses Pipewire)                                   |
| [`brightness.sh`](./scripts/brightness.sh)         | Screen brightness control wrapper (uses Brightnessctl)                         |
| [`bluetooth_mgr.sh`](./scripts/bluetooth_mgr.sh)   | Bluetooth device manager (toggle, scan, connect)                               |
| [`usb.sh`](./scripts/usb.sh)                       | USB device management (udevadm)                                                |
| [`power-profiles.sh`](./scripts/power-profiles.sh) | Power mode switcher (performance/balanced/power-saver)                         |

---

## Power Management & Laptop Optimization

### Hibernation & Suspend

**Configuration:** [`configuration.nix` lines 11–23](./configuration.nix#L11)

```nix
boot = {
  kernelParams = [
    "resume_offset=72464384"        # Swap offset for hibernation
    "mem_sleep_default=deep"        # Deep sleep (S4 state)
  ];
  resumeDevice = "/dev/disk/by-uuid/...";  # Root disk UUID
};
```

**Swap setup:** [`configuration.nix` lines 296–299](./configuration.nix#L296)

```nix
swapDevices = [{
  device = "/var/lib/swapfile";
  size = 32*1024;  # 32 GB
}];
```

**Triggers:** [`configuration.nix` lines 104–111](./configuration.nix#L104)

| Event                 | Action                 | Via                        |
|-----------------------|------------------------|----------------------------|
| Lid closed            | suspend-then-hibernate | logind `LidSwitch`         |
| Power button pressed  | hibernate immediately  | logind `PowerKey`          |
| Power button held 5s+ | power-off              | logind `PowerKeyLongPress` |

### CPU Frequency Scaling (TLP)

**Configuration:** [`configuration.nix` lines 85–102](./configuration.nix#L85)

```nix
tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";     # Max speed when plugged
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";      # Throttle on battery
    CPU_MAX_PERF_ON_BAT = 20;                       # Cap at 20% on battery
    START_CHARGE_THRESH_BAT0 = 40;                  # Start charging at 40%
    STOP_CHARGE_THRESH_BAT0 = 80;                   # Stop charging at 80%
  };
};
```

**Benefits:**
- AC power: Full CPU speed for workloads
- Battery: Capped at 20% to save power
- Battery health: Charge cycle stops at 80% to extend lifespan

---

## How It All Works

### Initialization Flow (Boot → Desktop)

```
1. NixOS Boot
   ↓
2. SDDM Login (autologin as charon)
   ↓
3. Hyprland starts (exec-once triggered)
   ├─ session_start.sh runs
   │  └─ Launches Quickshell Main.qml (singleton manager)
   │  └─ Launches Waybar (status bar)
   │  └─ Launches Jetbrains Toolbox
   └─ Hyprland compositor ready → Desktop visible
   ↓
4. User presses Super+W (wallpaper keybind)
   ├─ Hyprland keybind dispatcher catches it
   ├─ Executes: qs_manager.sh toggle wallpaper
   │  └─ Writes "wallpaper" to /tmp/qs_widget_state
   → Main.qml IPC poller reads it (every ~100ms)
   → Sets currentActive = "wallpaper"
   → StackView loads wallpaper/WallpaperPicker.qml
   → Window animates: 1px → 1920x500 (morphing 500ms)
   → Wallpaper picker visible on screen
   ↓
5. User selects wallpaper
   ├─ WallpaperPicker calls awww to set wallpaper
   ├─ awww triggers Matugen in background
   ├─ Matugen extracts colors → generates configs
   ├─ Hyprland border colors update (next window focus)
   ├─ Waybar CSS reloads → new theme colors
   └─ Rofi theme regenerated (for next launch)
```

### Widget Close Flow

```
Super+Escape pressed
→ Hyprland executes: qs_manager.sh close
→ Writes "close" to /tmp/qs_widget_state
→ Main.qml reads → currentActive = "hidden"
→ StackView unloads widget
→ Window morphs: 1920x500 → 1px
→ Window moves off-screen
→ currentActive property writes "hidden" to /tmp/qs_active_widget
→ Desktop returns to clean state
```

### Color Update Flow (Wallpaper → UI)

```
User picks wallpaper
→ awww sets background image
→ Matugen watches file change
→ Extracts Material 3 color palette (30+ colors)
→ Renders templates:
   ├─ hyprland-colors.conf (Hyprland sources it)
   ├─ waybar.css (CSS variables for bar colors)
   └─ rofi.rasi (Rofi theme colors)
→ Next Hyprland source command applies border colors
→ Waybar reloads CSS → Bar recolored
→ Rofi theme ready for next invocation
→ Entire system visually cohesive with new wallpaper
```

---

## Key Files Reference

| File                                                                                                     | Purpose                                                |
|----------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| [`flake.nix`](./flake.nix)                                                                               | Nix Flake entry point; declares inputs & system output |
| [`configuration.nix`](./configuration.nix)                                                               | System-level config (boot, hardware, services)         |
| [`home.nix`](./home.nix)                                                                                 | Home Manager user config; imports modules              |
| [`modules/default.nix`](./modules/default.nix)                                                           | Module imports index                                   |
| [`modules/hyprland.nix`](./modules/hyprland.nix)                                                         | Hyprland compositor + keybinds                         |
| [`modules/waybar.nix`](./modules/waybar.nix)                                                             | Waybar status bar + styling                            |
| [`modules/rofi.nix`](./modules/rofi.nix)                                                                 | Rofi launcher config                                   |
| [`modules/nvim.nix`](./modules/nvim.nix)                                                                 | Neovim editor setup                                    |
| [`modules/zsh.nix`](./modules/zsh.nix)                                                                   | Zsh shell config                                       |
| [`modules/catppuccin.nix`](./modules/catppuccin.nix)                                                     | Catppuccin color scheme defaults                       |
| [`modules/matugen/default.nix`](./modules/matugen/default.nix)                                           | Matugen integration & color generation                 |
| [`modules/quickshell-symlinks.nix`](./modules/quickshell-symlinks.nix)                                   | Symlinks scripts to `.config/hypr/scripts/`            |
| [`scripts/qs_manager.sh`](./scripts/qs_manager.sh)                                                       | Quickshell IPC orchestrator                            |
| [`scripts/quickshell/Main.qml`](./scripts/quickshell/Main.qml)                                           | Quickshell singleton widget manager                    |
| [`scripts/quickshell/wallpaper/WallpaperPicker.qml`](./scripts/quickshell/wallpaper/WallpaperPicker.qml) | Wallpaper picker widget                                |
| [`scripts/session_start.sh`](./scripts/session_start.sh)                                                 | Hyprland startup initialization                        |

---

## Quick Start

### Prerequisites
- NixOS 25.11 or later
- Git, Flakes enabled (`nix.settings.experimental-features = ["nix-command" "flakes"]`)

### Installation
```bash
git clone https://github.com/ItsMagick/nix-config 
cd nix-config
sudo nixos-rebuild switch --flake .#TPS
```

### Default Keybinds
- `Super+Q` → Terminal (Kitty)
- `Super+R` → App launcher (Rofi)
- `Super+W` → Wallpaper picker (Quickshell)
- `Super+D` → Calendar (Quickshell)
- `Super+Y` → Music (Spotify/Quickshell)
- `Super+C` → Close widget

### Rebuild after Changes
```bash
update  # Alias for: sudo nixos-rebuild switch --flake ~/Documents/nix-config/#TPS
```

---

## Future Enhancements

- [ ] Stylix integration (unified color management across all apps)
- [ ] Multi-monitor support (extended layouts, per-display configs)
- [ ] Custom Hyprland animations (polish window transitions)
- [ ] Voice control integration (hotword detection)
- [ ] Power profile auto-switch (based on battery %)
- [ ] Make hardware setup more generic/modular (for easier adaptation to other machines)
- [ ] Add ansible for remote management of config across multiple devices
---

**Last updated:** 2026-05-20 | **Maintainer:** Charon
```

---
Special thanks for the inspiration by [ilyamiro](https://github.com/ilyamiro).
I essentially cloned the quickshell stuff and tailored it mo my needs. Looking awesome! 