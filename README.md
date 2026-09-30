<p align="center">
  <img src="docs/assets/banner.png" alt="Sidedoor: a dock with app launchers and a weather card at the edge of the screen" width="100%">
</p>

<h1 align="center">Sidedoor</h1>

<p align="center">
  A second dock that hides at the edge of your screen.<br>
  App launchers and live widget cards, one flick of the pointer away.
</p>

<p align="center">
  <a href="https://github.com/lassejlv/sidedoor/releases/latest"><img src="https://img.shields.io/github/v/release/lassejlv/sidedoor?include_prereleases&label=release" alt="Latest release"></a>
  <a href="https://github.com/lassejlv/sidedoor/actions/workflows/macos.yml"><img src="https://github.com/lassejlv/sidedoor/actions/workflows/macos.yml/badge.svg" alt="macOS"></a>
  <a href="https://github.com/lassejlv/sidedoor/actions/workflows/linux.yml"><img src="https://github.com/lassejlv/sidedoor/actions/workflows/linux.yml/badge.svg" alt="Linux"></a>
  <a href="https://github.com/lassejlv/sidedoor/actions/workflows/windows.yml"><img src="https://github.com/lassejlv/sidedoor/actions/workflows/windows.yml/badge.svg" alt="Windows"></a>
</p>

---

Sidedoor stays off screen until the pointer touches its edge, then slides in
with your apps and a few small widgets. Click an app, glance at a card, and
it's gone again, without taking focus from the app you were in. It's built
in Rust with [GPUI Kit](https://crates.io/crates/gpui-kit) and aims to look
like it shipped with the OS.

## Features

- **Hides until you reach for it.** The dock appears at the screen edge you
  choose and gets out of the way the moment you leave. The reveal logic
  ignores a pointer that just drifts past.
- **App launchers.** Drag apps in, reorder them, see which are running, and
  give any item a global keyboard shortcut.
- **Widget cards.** Hover an item to open its card. **Weather**, **Stats**
  (CPU, memory, disk) and **Clipboard** come built in.
- **Clipboard History.** Text and images you copy, searchable, a shortcut
  away: <kbd>⌃</kbd><kbd>⌘</kbd><kbd>V</kbd> on a Mac,
  <kbd>Ctrl</kbd><kbd>Alt</kbd><kbd>V</kbd> on Windows and Linux.
- **Plugins in TSX.** Write your own widgets with the
  [Sidedoor SDK](sdk/README.md). They're drawn with native GPUI elements,
  with no web view, and reload as you save. Install others' plugins from a
  GitHub, Git or archive link.
- **Native feel.** It follows light and dark mode, Reduce Motion, Reduce
  Transparency and Increase Contrast. See [DESIGN.md](DESIGN.md).

## Download

Get the latest build from
[**Releases**](https://github.com/lassejlv/sidedoor/releases/latest). Every
package includes Bun and the plugin SDK, so there's nothing else to install.

| Platform | File | |
| --- | --- | --- |
| macOS (Apple Silicon) | `Sidedoor-macos-arm64.dmg` | Open and drag `Sidedoor.app` to Applications |
| macOS portable | `Sidedoor-macos-arm64.zip` | Unzip and move `Sidedoor.app` to Applications |
| Debian / Ubuntu (x86_64, X11) | `Sidedoor-linux-x86_64.deb` | `sudo apt install ./Sidedoor-linux-x86_64.deb` |
| Fedora / RPM (x86_64, X11) | `Sidedoor-linux-x86_64.rpm` | `sudo dnf install ./Sidedoor-linux-x86_64.rpm` |
| Linux portable (x86_64, X11) | `Sidedoor-linux-x86_64.tar.gz` | Extract and run `./Sidedoor-linux-x86_64/sidedoor` |
| Windows (x64) | `Sidedoor-windows-x64-setup.exe` | Run setup (administrator access required) |
| Windows MSI (x64) | `Sidedoor-windows-x64.msi` | Install with Windows Installer (administrator access required) |
| Windows portable (x64) | `Sidedoor-windows-x64.zip` | Extract the whole folder and run `Sidedoor.exe` |

Each file has a `.sha256` checksum next to it.

Windows installers are unsigned and install into `Program Files\Sidedoor`,
with a Start menu shortcut and an uninstall entry. The setup EXE embeds the
MSI and works offline. Settings and plugins stay in your user data folder.
Linux packages are built on Ubuntu 24.04; RPM dependencies also require a
distribution with compatible library versions, an X11 session, and a Vulkan driver.

> [!NOTE]
> macOS releases built with the current workflow are signed and notarized.
> Older releases may still be unsigned. See the
> [macOS signing guide](docs/macos-signing.md) for setup and verification.

## Using it

- **Settings:** right-click the dock and choose **Dock Settings…**, or use
  the menu bar or tray icon.
- **Add apps:** drag them onto the dock, or use **Settings › Items**.
- **Add widgets:** turn them on under **Settings › Plugins**.
  **New Plugin** creates a working widget and opens its code.
- **Where things are kept:**

  | Platform | Settings and plugins |
  | --- | --- |
  | macOS | `~/Library/Application Support/Sidedoor` |
  | Linux | `~/.local/share/sidedoor` |
  | Windows | `%APPDATA%\Sidedoor` |

## Writing a plugin

A plugin is a folder with an `index.tsx`:

```tsx
import { Button, Card, definePlugin, useState } from "@sidedoor/sdk";

export default definePlugin({
  name: "Counter",
  icon: "hash",
  card() {
    const [count, setCount] = useState(0);
    return (
      <Card title="Counter">
        <div text_size={32} font_weight="semibold">{count}</div>
        <Button variant="primary" label="Add" on_click={() => setCount(count + 1)} />
      </Card>
    );
  },
});
```

Plugins run with the same access as the app, so only add ones from people
you trust. The [SDK guide](sdk/README.md) covers settings, tiles, windows,
native data, testing and sharing.

Building with an AI coding agent? The
[`sidedoor-plugins` skill](skills/sidedoor-plugins/SKILL.md) teaches it the
SDK, the workflow and the pitfalls. Claude Code picks it up automatically in
this repository. To use it elsewhere, copy the folder into your agent's
skills directory (for Claude Code, `~/.claude/skills/`).

## Platform notes

### macOS

Needs macOS 15 or later. Build and install from source with
`./scripts/package/macos.sh --install`.

### Linux

Sidedoor runs on X11 desktops and has been checked on GNOME (Mutter), KDE
(KWin) and Xfce. Wayland doesn't let an app follow the pointer or place a
dock, so under Wayland it runs through XWayland, where revealing the dock
isn't reliable yet. Choose the X11 session (for example "GNOME on Xorg") at
login.

The tray icon (Settings, Launch at Login, Reload, Quit) appears on desktops
that show StatusNotifierItems. The dock's context menu always has **Dock
Settings…**. Text uses [Inter](https://rsms.me/inter/) when it's installed.

`./scripts/package/linux.sh --install` installs for the current user into
`~/.local/opt/sidedoor`, with a launcher entry and an icon.

### Windows

The Windows port is still being tested on real desktops. The
[Windows test checklist](docs/windows-testing.md) covers installation, data
paths and what to check. Use the tray icon for Settings.

## Building from source

You need [Rust](https://rustup.rs) (stable) and [Bun](https://bun.sh) 1.4.

```sh
cd sdk && bun install --frozen-lockfile && cd ..
cargo run
```

<details>
<summary><b>Linux build libraries</b></summary>

```sh
sudo apt install libxkbcommon-dev libxkbcommon-x11-dev libwayland-dev \
  libvulkan-dev libfontconfig-dev libx11-xcb-dev libxcb-xkb-dev fonts-inter
```

</details>

<details>
<summary><b>Windows build tools</b></summary>

Install Rust with the MSVC toolchain, Visual Studio C++ Build Tools with a
Windows SDK (including `fxc.exe`), and Bun. Then:

```powershell
cd sdk
bun install --frozen-lockfile
cd ..
./scripts/package/windows.ps1
```

</details>

### Packaging

| Script | Output |
| --- | --- |
| `scripts/package/macos.sh` | `target/release/bundle/Sidedoor.app`, ZIP, DMG, checksums |
| `scripts/package/linux.sh` | `target/release/bundle/Sidedoor-linux-<arch>.tar.gz`, checksum |
| `scripts/package/linux.sh --packages` | Also DEB, RPM, checksums (needs `dpkg-dev rpm desktop-file-utils`) |
| `scripts/package/windows.ps1` | `target/windows-bundle/Sidedoor-windows-x64.zip`, checksum |
| `scripts/package/windows.ps1 -Installers` | Also MSI, setup EXE, checksums (downloads pinned WiX 3.14.1) |

Publishing a GitHub release as a **pre-release** builds every format with the
[Release workflow](.github/workflows/release.yml), attaches them, and marks
the release as latest.

The workflow checks out the release tag, so the tag must include these packaging
changes. Re-running a release for an older tag uses its older scripts. Installer
versions come from the tag via `SIDEDOOR_VERSION`; local builds use the workspace
version. Windows Installer compares only the numeric `major.minor.patch`, so
use a new numeric version for each Windows upgrade. DEB and RPM preserve
prerelease ordering with `~`.

### Updates

Sidedoor checks stable GitHub releases at startup and every six hours. Open
**Settings › General › Updates** to check manually, download an update, and
choose **Install and restart**. Automatic checks can be turned off there.
Downloads are checked against the release manifest's size and SHA-256 digest;
an interrupted or invalid download leaves the installation untouched.

macOS updates replace the complete app bundle, including Bun and plugins.
Portable Windows/Linux updates replace the complete application folder. These
installs retain a backup until the new process reports that startup succeeded,
and restore it if replacement or startup fails. The installation's parent
folder must be writable. MSI and setup installations use their respective
Windows installers; DEB and RPM installations use `apt-get` and `dnf` through
`pkexec`. These managed installs request system authentication and rely on the
installer/package manager for recovery. Linux package updates need `pkexec`
and a desktop authentication agent.

Settings, plugins, and clipboard history remain in the user data folder.
Update logs are kept in the app's cache under `updates/last-update.log`.
Updates trust this repository's GitHub release metadata over HTTPS; the
checksum manifest is not an independent publisher signature. macOS verifies
the complete bundle's existing signature and identity. Current releases are
still ad hoc signed on macOS and unsigned on Windows.

The release workflow publishes `sidedoor-update.json` after checking all eight
payloads and their checksums, then promotes the release to latest. Older
releases without this manifest must be downloaded manually. Only packaged
installations can update in place; development binaries keep using the checkout.

## Project layout

The root is a virtual Cargo workspace. `cargo run` starts the `desktop`
crate's `sidedoor` binary.

| Crate | Responsibility |
| --- | --- |
| [`desktop`](crates/desktop) | Startup, app state, shared GPUI views, built-in TSX plugins, icons |
| [`domain`](crates/domain) | Pure models, config schema and migrations, clipboard rules, geometry, motion |
| [`platform`](crates/platform) | macOS, Windows and Linux APIs, native windows, clipboard, shortcuts, tray, paths |
| [`services`](crates/services) | Config and history storage, weather, system stats, image downloads |
| [`plugin-host`](crates/plugin-host) | Plugin manifests, protocol, discovery, installs from links, reload, Bun supervisor |
| [`sdk`](sdk) | The TypeScript plugin SDK, a separate Bun package |

See [architecture](docs/architecture.md) for dependency rules and
[DESIGN.md](DESIGN.md) for how it should look and feel.

## Checks

```sh
cargo fmt --all --check
cargo test --workspace --locked
cargo clippy --workspace --locked --all-targets -- -D warnings
cd sdk && bun test && bun run check
```

On an isolated Windows test session, CI also checks native clipboard round
trips and launches the packaged app. The clipboard test is ignored by default
because it replaces the session's clipboard contents.
