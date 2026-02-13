# hack-do

A matrix-themed task manager built with Flutter. Features vi-keybind text editing, time tracking, and peer-to-peer task syncing across devices on your local network.

## Features

- **Diagonal & tiling layouts** — view tasks stacked in a 4-quadrant card deck or a responsive grid
- **Vi-mode text editor** — write progress notes with normal/insert modes, motions (`hjkl`, `w`, `b`, `gg`, `dd`), yank/paste
- **Time tracking** — per-task play/pause/reset timer with cumulative elapsed time
- **Markdown progress notes** — write and preview markdown in task descriptions
- **Priority & color coding** — low/medium/high priority badges, 6 card color themes
- **Filters** — cycle between all / ongoing / done views
- **Local network sync** — discover and sync tasks with other hack-do instances on the same LAN, LocalSend-style

## Sync

hack-do includes peer-to-peer task syncing with zero configuration:

- **Auto-discovery** — UDP broadcast finds other hack-do instances on your local network
- **Tap to sync** — open the sync screen to see nearby devices on an animated radar, tap any device to sync
- **Conflict resolution** — last-modified-wins merge strategy with soft-delete propagation
- **No server required** — each instance runs an embedded HTTP server, all communication stays on your LAN

## Gestures

### Diagonal Layout (default)

| Gesture | Action |
|---|---|
| **Tap** card | Reveal card to center + open edit dialog |
| **Double-tap** card | Reveal/unreveal card without opening editor |
| **Long press** card | Delete confirmation |
| **Swipe left/right** | Navigate through card layers |
| **Scroll wheel** (desktop) | Navigate through card layers |
| **Right-click** (desktop) | Reveal/unreveal card |
| **Tap empty area** | Dismiss revealed card |

### On-card controls (both layouts)

| Gesture | Action |
|---|---|
| Tap **checkbox** (top-right circle) | Toggle complete |
| Tap **X** button (desktop only) | Delete |
| **Long press** card | Delete confirmation |
| Tap **play/pause** button | Start/stop timer |
| Tap **reset** button | Reset timer to zero |

### App bar

| Gesture | Action |
|---|---|
| Tap **filter pill** (center) | Cycle: ALL → ONGOING → DONE |
| Tap **sync icon** | Open sync screen |
| Tap **layout icon** | Toggle diagonal ↔ tiling layout |
| Tap **+** FAB | Create new task |

## Building

```sh
flutter pub get
flutter run
```

### Arch Linux

```sh
makepkg -si
```

## Tech

- Flutter + Dart
- Hive (local NoSQL storage)
- `dart:io` for all networking (HTTP server, UDP broadcast) — no external network dependencies

## License

GPL-3.0
