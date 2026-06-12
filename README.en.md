# HOME REARED MEAT – Loud Enough to Kill

> **Brotato-style roguelite rhythm game** · Built with Godot 4.6 · Metal & Chaos

**Deutsch:** [README.md](README.md) · **English:** this file

A wave-survival roguelite where you fight waves of enemies as a member of the metal band **Home Reared Meat** – to the beat of the music. 15 story waves, endless mode, 6 playable characters and local co-op for 2 players.

---

## Contents

- [Play (prebuilt version)](#play-prebuilt-version)
- [Run from source](#run-from-source)
- [Export the game (build your own .exe)](#export-the-game-build-your-own-exe)
- [System requirements](#system-requirements)
- [Controls](#controls)
- [Characters](#characters)
- [Game modes](#game-modes)
- [Known issues](#known-issues)

---

## Play (prebuilt version)

If someone already shared a prebuilt `.exe` / executable with you:

### Windows
1. Unzip the archive (right-click → Extract All)
2. Double-click `HRM-LoudEnoughToKill.exe`
3. If Windows Defender warns you: **"More info" → "Run anyway"**
   *(The game is not a virus – Windows warns about unknown publishers)*

### macOS
1. Unzip the archive
2. Drag `HRM-LoudEnoughToKill.app` into your Applications folder *(optional)*
3. On first launch: **right-click → Open** (not double-click!)
4. In the "unidentified developer" dialog click **Open**
5. If that fails: System Settings → Privacy & Security → **"Open Anyway"**

### Linux
```bash
chmod +x HRM-LoudEnoughToKill.x86_64
./HRM-LoudEnoughToKill.x86_64
```

---

## Run from source

### What you need

| Tool | Version | Download |
|------|---------|----------|
| **Godot Engine** | 4.3 or newer (4.6 recommended) | [godotengine.org/download](https://godotengine.org/download) |

No other tools required. No npm, no Python, no compiler.

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill.git

# 2. Enter the folder
cd "home-reared-meat-loud-enough-to-kill"
```

3. **Open Godot**
4. In the Godot project manager: **"Import"** → select the cloned folder → choose `project.godot` → **Open**
5. Press **▶ Play** (F5) in the top right of the editor

That's it. The game runs directly – no dependencies, no setup steps.

> **Note on music files:** For copyright reasons the MP3 files in `assets/music/` may not be included in the repository. The game still runs without them – just without background music. Sound effects are generated procedurally and always work.

---

## Export the game (build your own .exe)

How to build a standalone executable that runs without Godot:

### Install export templates (once)

1. Open Godot
2. Menu: **Editor → Manage Export Templates**
3. In the dialog: click **Download** next to your Godot version
4. Wait for the download to finish (~200 MB)

### Windows export

1. Menu: **Project → Export**
2. **"Add..."** → select **Windows Desktop**
3. Choose a path, e.g. `export/windows/HRM-LoudEnoughToKill.exe`
4. Click **"Export Project"**

**Important:** The generated `.exe` must stay in the same folder as the `.pck` file (or export with "Embed PCK").

### macOS export

1. **Project → Export → Add → macOS**
2. Choose a path: `export/macos/HRM-LoudEnoughToKill.zip`
3. Click **"Export Project"**
4. The `.app` is inside the ZIP

> A signed macOS build (without security warnings) requires an Apple Developer account. Not needed for private use.

### macOS code signing & notarization (for distribution)

For distributing to others (Steam, itch.io, your own website) the app should be signed and notarized:

1. Create an **Apple Developer account** (99 USD/year): [developer.apple.com](https://developer.apple.com)
2. Create a **"Developer ID Application" certificate** in Xcode or on developer.apple.com and import it into your keychain
3. In Godot under **Project → Export → macOS**:
   - Enable `codesign/enable`, enter the name of your Developer ID certificate as identity
   - Enable `notarization/enable`, enter your Apple ID, team ID and an app-specific password (create one at appleid.apple.com)
4. Export – Godot signs and submits the build for notarization automatically
5. Check status: `xcrun notarytool history --apple-id YOUR_APPLE_ID`

> For the **Mac App Store** you need an "Apple Distribution" certificate plus a provisioning profile instead. For Steam, Developer ID + notarization is enough.

### Linux export

1. **Project → Export → Add → Linux/X11**
2. Path: `export/linux/HRM-LoudEnoughToKill.x86_64`
3. Click **"Export Project"**

### Compatibility renderer (for older GPUs)

If the game does not start on an older PC (GPU without Vulkan support):

1. In the export dialog: enable **"Embed PCK"**
2. Under **"Rendering Method"** select `gl_compatibility`
3. Re-export → runs on practically any hardware since 2012

---

## System requirements

### Minimum

| | Windows | macOS | Linux |
|---|---|---|---|
| **OS** | Windows 10 64-bit | macOS 10.15 (Catalina) | Ubuntu 20.04 / equivalent |
| **CPU** | dual-core 2 GHz | Intel/Apple Silicon | x86_64 dual-core |
| **RAM** | 2 GB | 2 GB | 2 GB |
| **GPU** | Vulkan-capable (GTX 600 / RX 400 +) | Metal-capable | Vulkan or OpenGL 3.3 |
| **Disk** | ~200 MB | ~200 MB | ~200 MB |

### With compatibility renderer (OpenGL)

| | Windows | macOS | Linux |
|---|---|---|---|
| **OS** | Windows 8.1+ | macOS 10.12+ | Ubuntu 18.04+ |
| **GPU** | OpenGL 3.3 capable (GTX 400 / HD 4000 +) | any | OpenGL 3.3 |

> **Windows 7:** No longer officially supported by Godot 4.

---

## Controls

### Player 1

| Action | Keyboard | Controller (joypad 1) |
|--------|----------|----------------------|
| Move | WASD or arrow keys | left stick / D-pad |
| Attack | automatic | automatic |
| Dash | Shift or right mouse button | B |
| Ultimate | E | X |
| Pause | ESC | B |

### Player 2 (local co-op)

| Action | Controller (joypad 2) |
|--------|----------------------|
| Move | left stick / D-pad |
| Attack | automatic |
| Ultimate | X |

> Player 2 requires a **second controller**. Keyboard controls for P2 are not available.

### Remapping controller buttons

In the main menu: **Options → Gameplay → Controller** – all joypad buttons can be remapped there.

---

## Characters

| Character | Instrument | Ability |
|-----------|-----------|---------|
| **Manny** | drums | kills increase attack speed |
| **Chicken** | growler/vocals | precision death beam, low frequency |
| **Nik** | inhale screamer | dreadlock whip, grabs & throws enemies |
| **Andz** | lead guitar | blades pierce multiple enemies |
| **Grindhouse** | rhythm guitar | distortion fields slow enemies |
| **Armin** | bass | sub-bass waves, ground shockwaves on kills |

More characters are unlocked by completing story waves.

---

## Game modes

### Story mode (15 waves)
- Waves 1–15 with rising difficulty
- After each wave: upgrade shop (3 random upgrades)
- At waves 5, 10 and 15: story cutscenes
- Bosses at certain waves

### Endless mode
- Endless waves on a selectable map
- Every 5 waves: upgrade shop
- Every 5th wave: boss rotation (10 different bosses)
- High score leaderboard

### Local co-op (2 players)
- Story mode only
- On the character select screen: enable the **"2 PLAYERS"** button
- Player 2 picks their character with `<` / `>`
- Player 2 **must** have a second controller connected
- Game over only when **both** players are down

---

## Difficulty levels

| Level | Name | HP multiplier | Damage | Enemy count |
|-------|------|--------------|--------|-------------|
| 0 | Access Denied | ×0.35 | ×0.35 | ×0.45 |
| 1 | Vomit Blood | ×0.65 | ×0.65 | ×0.70 |
| 2 | Brootal Destroy | ×1.0 | ×1.0 | ×1.0 |
| 3 | Drink Fight Die! | ×1.6 | ×1.4 | ×1.45 |
| 4 | Bolognese Bloodbath | ×2.8 | ×2.0 | ×2.1 |

---

## Known issues

- **Music missing after cloning:** MP3 files may not be included in the repository – the game runs without music
- **Controller not detected:** Connect the joypad **before** starting the game; USB controllers are more reliable than Bluetooth
- **macOS security warning:** On first launch use right-click → Open (see above)
- **Black screen on Linux:** Install `libvulkan`: `sudo apt install libvulkan1`

---

## Built with

- **Engine:** [Godot 4.6](https://godotengine.org)
- **Language:** GDScript
- **Graphics:** fully procedural (no external sprites)
- **Audio:** procedural WAV generation + MP3 music
- **Localization:** German, English, French, Spanish, Ukrainian

---

*Home Reared Meat – Loud Enough to Kill © 2026 Home Reared Meat*
