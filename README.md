<div align="center">

# BrutalDots

**A neo-brutalist Hyprland desktop, built on [Quickshell](https://quickshell.org).**

Hard 2px borders. Solid offset shadows, never blurred. Flat pastel blocks on warm linen.

</div>

---

## What this is

A complete Wayland desktop for Hyprland — bar, launcher, clipboard history,
control-centre dashboard, desktop widgets, notifications, OSD, system tray,
polkit prompts, idle handling, lock screen, screenshots and recording — written
in QML against Quickshell, with one design-token file driving the whole look.

Doing it all in the shell means one config, one theme, one process to restart.
No `hyprlock.conf` to keep in step with the palette, no `hypridle.conf` whose
timings disagree with the lock, no launcher that looks like a different desktop:

| Instead of | BrutalDots uses |
| --- | --- |
| `hyprlock` | `Modules/Lock` — the Wayland session-lock protocol, PAM for auth |
| `hypridle` | `Services/Idle` — idle-notify; dim → lock → screen off → suspend |
| `polkit-kde-agent` / `polkit-gnome` | `Modules/Polkit` — the session's agent |
| `swww` / `hyprpaper` / `swaybg` | `Modules/Wallpaper` — a background surface, with a picker |
| `fuzzel` / `rofi` / `wofi` | `Modules/Launcher` — apps, `>` commands, clipboard |
| `waybar` + a tray plugin | `Modules/Bar` — tray icons and their DBus menus |

The visual language follows [Darkkal44's **Bruteon**](https://github.com/Darkkal44/Bruteon).
Bruteon's dotfiles were never published, so this is a clean-room implementation
built from the preview images; all code here is original.

## Preview

![The dashboard, on its Overview tab](Preview/3.png)

| | |
| --- | --- |
| ![The Settings tab](Preview/4.png) | ![The Keybinds tab, searchable](Preview/5.png) |
| ![The desktop widget layer: tasks, pomodoro, clock, calendar, weather](Preview/2.png) | ![The terminal: kitty, the starship prompt and the fetch](Preview/1.png) |

Toggle the surfaces with `SUPER+Space` (launcher), `SUPER+D` (dashboard),
`SUPER+W` (widgets), `SUPER+V` (clipboard) and `SUPER+ESC` (power menu).

## Requirements

`quickshell` (≥ 0.2), `hyprland` (≥ 0.50) and **JetBrainsMono Nerd Font**. The
installer brings in everything else it needs — kitty, starship, fastfetch,
neovim, zsh, playerctl, cava, wireplumber, brightnessctl, cliphist,
wl-clipboard, grim, slurp, satty, wf-recorder, hyprpicker, hyprsunset, nautilus
— in one `pacman` transaction. That is not optional: the desktop is opinionated
about what it contains. Install them yourself beforehand and there is nothing
left for it to do.

Every startup command and shell action still checks for its tool first, so
removing one later switches its feature off rather than breaking the shell.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/fezzik-the-giant/BrutalDots/main/install.sh | bash
```

That fetches the repository into `~/.cache/brutaldots/checkout` and runs the
installer out of it — the script needs its modules and the configuration beside
it. Arguments go after `bash -s --`. Or clone it and read it first:

```sh
git clone https://github.com/fezzik-the-giant/BrutalDots.git
cd BrutalDots
./install.sh          # pick what to install from a checklist
```

The Hyprland and Quickshell configuration is always installed; the login screen
is the one choice on the checklist. The configuration is **copied**, so the
checkout is yours to delete — pass `--link` to symlink it out of a clone
instead, which is what you want if you are working *on* BrutalDots. `--yes`
takes the defaults without asking.

Two things ask for a password, both announced first: the login screen, which is
all that writes outside your home directory, and the package install. The
installer also makes zsh your login shell — that is the shell the prompt and
fetch are wired into — and writes a small `~/.zshrc` if you have none. An
existing one is never overwritten. Undo just that with `chsh -s /bin/bash`.

### Trying it first

```sh
./scripts/test-nested.sh    # the whole desktop in a nested compositor
qs -c brutal                # or run the shell over your live session
```

The nested compositor touches nothing and has its own workspaces and layer
surfaces, so your real windows never move; quit it with `SUPER + SHIFT + E`.
Running `qs -c brutal` from the repo installs nothing either — it reserves no
space, so it overlaps whatever bar you already have rather than fighting it.

### Going back

```sh
./install.sh --uninstall    # restores the newest ~/.config/hypr.bak.*
```

Nothing is ever deleted without being moved aside first, so every step is
recoverable. Name a backup explicitly to restore a specific one:
`./install.sh --uninstall ~/.config/hypr.bak.20260101120000`.

## What you get

| | |
| --- | --- |
| **Dark mode** | `SUPER + SHIFT + T`. Carries the terminal, GTK/Qt apps, neovim and the login screen with it. |
| **Launcher** | `SUPER + Space`. Apps, `>` to run a command. |
| **Clipboard** | `SUPER + V`, backed by cliphist; `TAB` switches text and images. |
| **Dashboard** | `SUPER + D` — palette, audio, network, keybinds, system meters. |
| **Widgets** | `SUPER + W` — tasks, pomodoro, clock, calendar, weather. |
| **Wallpaper** | `SUPER + SHIFT + W` opens a picker over your wallpaper directory. `~` and `$HOME` are expanded in paths. |
| **Audio** | The speaker glyph opens a device pane; middle-click mutes, scroll changes volume. |
| **Wi-Fi / Bluetooth** | Glyphs in the right island open device lists; middle-click flips the radio. |
| **Screenshots** | `grim` + `slurp`, handed to `satty` to annotate before saving. |
| **Terminal** | kitty, `.config/starship.toml`, `.config/fastfetch/` and the neovim colourscheme, all themed from the same palette so the editor and the terminal around it cannot drift. |

Everything is scriptable over IPC:

```sh
qs -c brutal ipc call shell audio                              # open the audio pane
qs -c brutal ipc call shell setSink "G733"                     # switch device by name
qs -c brutal ipc call shell setWallpaper ~/Pictures/other.png
```

`qs -c brutal ipc show` lists the rest.

### Hyprland is configured in Lua

`~/.config/hypr/hyprland.lua`, not `hyprland.conf`. Your own changes go in
`~/.config/hypr/custom/` — `env.lua`, `execs.lua`, `general.lua`, `rules.lua`
and `keybinds.lua` are each sourced after the shipped file, so an override
survives reinstalling. Rebinding from the dashboard writes there too; the full
catalogue is at `~/.local/state/brutaldots/keybinds-catalogue.json`.

### The lock screen

Authenticates against PAM (`/etc/pam.d/login` by default — change
`lock.pamConfig` for another). Test it in the nested compositor before trusting
it: `./scripts/test-nested.sh`, then `SUPER + ALT + L`.

### The login screen

Optional, and assembled from the shell at install time rather than maintained
separately, so it cannot fall behind the desktop. It follows whatever palette
your session is in, reading `/var/lib/brutaldots/theme.conf`, which the shell
rewrites on every toggle. It also installs `/etc/sddm/weston.ini` and switches
SDDM's compositor to weston's desktop-shell, without which the greeter appears
on only one monitor.

```sh
./install.sh --test-sddm    # open it in SDDM's own greeter, in a window
```

That needs no privileges and changes nothing — do it before installing.

## Layout

```
hypr/
├── hyprland.lua         main config — Hyprland loads this directly
└── hyprland/
    ├── env.lua          environment variables
    ├── execs.lua        startup: shell, portals, clipboard, lock bridge, wallpaper
    ├── general.lua      monitors, frame, motion, input
    ├── rules.lua        window and layer rules
    └── keybinds.lua     window management, workspaces, shell, media keys

quickshell/brutal/
├── shell.qml            entry point: surfaces, IPC handlers, global shortcuts
├── Config/
│   ├── Theme.qml        every colour, radius, border, shadow and type size
│   ├── Icons.qml        named Nerd Font glyphs
│   ├── Settings.qml     user config, persisted as JSON
│   └── Env.qml          launch-time flags read from the environment
├── Components/          the brutalist primitives (box, button, pill, slider…)
├── Services/            system state: audio, network, mpris, weather, tasks…
└── Modules/
    ├── Bar/             three floating islands, tray, tray menus
    ├── Launcher/        apps, `>` commands, clipboard history
    ├── Media/           the mini player, with a cava level meter
    ├── Audio/           the device pane under the right island
    ├── Bluetooth/       the device menu under the right island
    ├── Wallpaper/       the desktop background, and the picker
    ├── Dashboard/       the control centre
    ├── Widgets/         desktop widgets
    ├── Common/          pieces shared between surfaces
    ├── Notifications/   toasts and history
    ├── Osd/             volume and brightness overlay
    ├── Lock/            session lock and the pre-lock dim
    ├── Polkit/          authentication prompts
    └── Power/           session menu
```


## Configuration

First run creates `~/.config/brutaldots/settings.json`. It is watched, so edits
apply live:

```jsonc
{
  "userName": "achlys",
  "theme": {
    "dark": false,               // SUPER+SHIFT+T toggles it
    "syncApps": true             // also set the GTK/portal colour scheme
  },
  "weatherLocation": "",        // blank = locate from IP
  "weatherMetric": true,
  "apps": { "terminal": "kitty", "browser": "firefox", ... },

  "bar": {
    "height": 42, "sideMargin": 20, "topMargin": 10,
    "trayHidePassive": false,   // true follows the spec and hides "passive" icons
    "trayIgnored": []           // StatusNotifierItem ids to leave out
  },

  // Seconds of inactivity before each step. 0 turns that step off.
  "idle": {
    "dimAfter": 300, "lockAfter": 600,
    "screenOffAfter": 900, "suspendAfter": 0,
    "dimOpacity": 0.55,
    "inhibitFullscreen": true   // hold all four off while fullscreen
  },

  "lock": {
    "pamConfig": "login",       // a file in /etc/pam.d
    "message": ""               // shown under your name on the lock screen
  },

  "capture": {
    "directory": "",            // blank = ~/Pictures/Screenshots
    "annotate": false           // true opens each shot in satty or swappy
  },

  "media": {
    "visualizer": true,
    "visualizerBars": 28,
    "visualizerSmoothing": 20
  },

  "wallpaper": {
    "enabled": true,
    "path": "",                 // blank = the generated pattern below
    "mode": "fill",             // fill | fit | stretch | center | tile
    "directory": "~/Pictures/Wallpapers",
    "pattern": "grid",          // grid | dots | diagonal | solid
    "patternSpacing": 44,
    "patternOpacity": 0.06
  },

  "nightLight": { "temperature": 4000 },

  "widgets": { "layer": "top" },  // "bottom" = true desktop widgets, under windows
  "quickLinks": [
    // icon: a name from Config/Icons.qml; color: a palette name
    { "name": "GitHub", "icon": "github", "color": "grey", "url": "https://github.com" }
  ],
  "pomodoro": { "focus": 25, "shortBreak": 5, "longBreak": 15 }
}
```

> [!TIP]
> A quick link's `icon` is a **name** from `Config/Icons.qml` — `youtube`,
> `github`, `terminal`, `calendar`, any of them. A literal Nerd Font glyph
> still works if you want one that is not in there.

> [!NOTE]
> Setting `lockAfter` to `0` disables the automatic lock entirely — the manual
> bind and `loginctl lock-session` still work. Setting `suspendAfter` on a
> desktop is usually not what you want; it is `0` by default.

## Keybinds

`SUPER` throughout. Everything below lives in `.config/hypr/hyprland/keybinds.lua`.

| Bind | Action |
| --- | --- |
| `SUPER + Space` | Launcher — type to search, `>` to run a command |
| `SUPER + V` | Clipboard history (`TAB` switches between the two) |
| `SUPER + SHIFT + W` | Wallpaper picker |
| `SUPER + D` | Dashboard |
| `SUPER + W` | Widgets (tasks, pomodoro, calendar, weather) |
| `SUPER + ESC` | Power menu |
| `SUPER + ALT + L` | Lock the session |
| `SUPER + Return` | Terminal |
| `SUPER + B` / `E` | Browser / files |
| `SUPER + Q` | Close window |
| `SUPER + F` / `M` | Fullscreen / maximise |
| `SUPER + ALT + Space` | Float or tile |
| `SUPER + ←↑→↓` or `HJKL` | Focus |
| `SUPER + SHIFT + ←↑→↓` | Move window |
| `SUPER + 1…0` | Switch workspace |
| `SUPER + SHIFT + 1…0` | Send window to workspace |
| `SUPER + S` | Scratchpad |
| `Print` | Screenshot a region |
| `SHIFT + Print` | Screenshot the focused output |
| `ALT + Print` | Screenshot the active window |
| `SUPER + SHIFT + R` | Start/stop recording a region |
| `SUPER + ALT + R` | Start/stop recording the screen |
| `SUPER + SHIFT + P` | Pick a colour into the clipboard |
| `SUPER + SHIFT + N` | Night light |
| `SUPER + SHIFT + T` | Dark mode |
| `SUPER + SHIFT + I` | Keep awake (idle inhibitor) |
| `CTRL + SUPER + R` | Restart the shell |

`SUPER + L` is deliberately *not* the lock: it is "focus right" in the vim-style
binds, so the lock sits one modifier away at `SUPER + ALT + L`.

Every action is also reachable over IPC, which is handy for scripting:

```sh
qs -c brutal ipc call shell dashboard
qs -c brutal ipc call shell launcher
qs -c brutal ipc call shell clipboard
qs -c brutal ipc call shell lock
qs -c brutal ipc call shell darkMode
qs -c brutal ipc call shell setTheme dark        # or light, if you must be sure
qs -c brutal ipc call shell screenshot region     # or screen, window
qs -c brutal ipc call shell record region         # again to stop
qs -c brutal ipc call shell pickColour
qs -c brutal ipc call shell keepAwake
qs -c brutal ipc call shell nightLight
qs -c brutal ipc call shell close
```

## Network access

The weather service is the only thing that talks to the internet. It calls
[Open-Meteo](https://open-meteo.com) for the forecast, and — only when
`weatherLocation` is blank — one IP-geolocation lookup to find your city. Set a
location in `settings.json` to skip the lookup, or delete `Services/Weather.qml`
and the weather cards to opt out entirely.

## Credits

- Design concept: [Darkkal44/Bruteon](https://github.com/Darkkal44/Bruteon)
- Built on [Quickshell](https://quickshell.org) by outfoxxed

## License

[GPL-3.0](LICENSE)
