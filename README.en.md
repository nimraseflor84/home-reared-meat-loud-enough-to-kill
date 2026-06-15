# Home Reared Meat – Loud Enough to Kill

[Deutsch](README.md) · English

> A Brotato-style roguelite rhythm game. Built with Godot 4.6. Metal and chaos.

A wave-survival roguelite where you fight off waves of enemies as a member of the metal band Home Reared Meat, to the beat of the music. 15 story waves with a continuous plot around the corporation SoundCorp and its CEO Dr. Victor Stille, plus an endless mode, the 6 band members, secret and bonus characters, many maps, local co-op and 5 languages (German, English, French, Spanish, Ukrainian).

---

## Download

Latest version: [Release v1.3.0](https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill/releases/tag/v1.3.0)

- **Windows:** unzip `HomeRearedMeat-Windows-v1.3.0.zip` and run `HomeRearedMeat.exe`. If Windows Defender warns you: "More info", then "Run anyway".
- **macOS:** unzip `HomeRearedMeat-macOS-v1.3.0.zip`, and on first launch right-click, "Open" (the app is unsigned).
- **Android:** in its own repo, [home-reared-meat-mobile](https://github.com/nimraseflor84/home-reared-meat-mobile).

Fresh start: the builds contain no save data. Only Manny is unlocked, everything else has to be earned again.

---

## Controls

| Action | Keyboard | Controller |
|--------|----------|------------|
| Move | WASD or arrow keys | Left stick / D-pad |
| Attack | Automatic | Automatic |
| Dash | Shift or right mouse button | B |
| Ultimate | E | X |
| Pause | ESC | B |

Player 2 (local co-op) requires a second controller.

---

## Characters

| Character | Instrument | Style |
|-----------|-----------|-------|
| Manny | Drums | Shockwaves, kills increase attack speed |
| Chicken | Growl vocals | Precision death beam |
| Nik | Inhale scream | Dreadlock whip, grabs and throws enemies |
| Andz | Lead guitar | Blades pierce multiple enemies |
| Grindhouse (Maik) | Rhythm guitar | Distortion fields slow enemies |
| Armin | Bass | Sub-bass waves, ground shockwaves on kills |

Plus secret characters and a bonus character, see [Unlocks](#easter-eggs-and-unlocks).

---

## Game modes

- **Story mode (15 waves):** continuous plot, an upgrade shop after every wave, story cutscenes and bosses. Local co-op for 2 players is only available here.
- **Endless mode:** infinite waves on a chosen map, a boss every 5 waves, its own leaderboard.
- **Network co-op:** over a local network.

---

## Difficulties

| Level | Name |
|-------|------|
| 0 | Access Denied |
| 1 | Vomit Blood |
| 2 | Brootal Destroy |
| 3 | Drink Fight Die! |
| 4 | Bolognese Bloodbath |

---

## Bosses

The boss roster includes Willi, the Big Farmer, the Conductor (who summons earlier bosses), the Trucker and the TV Star, among others. The Act IV final boss is Dr. Victor Stille, CEO of SoundCorp. Ten bosses rotate in endless mode.

---

## Easter eggs and unlocks

Secret characters, bonus content and hidden maps do not appear before they are unlocked. If you want to be surprised, don't open the spoiler.

<details>
<summary><b>Spoiler: show all unlocks</b></summary>

### Characters
- **Chicken / Nik / Andz / Grindhouse / Armin:** by reaching wave 3 / 5 / 7 / 10 / 12.
- **Pimmel (merch guy, secret):** take 12 upgrades in a single run.
- **Theo (stagehand, secret):** survive a boss wave without taking a single hit.
- **Toxo (bonus, mutated toxic hero):** beat the hardest difficulty (Bolognese Bloodbath) in story mode. Unlocks together with the Toxic City map.

### Maps
- **Santa's Village (Nikolausdorf):** 1,000 total kills, or play in December.
- **The Beach:** pause the game 30 times in total.
- **Toxic City (Giftstadt, bonus):** beat the hardest difficulty.

### Signature weapons
Each character unlocks a special second weapon by completing story mode with them on Drink Fight Die! (second-hardest) or higher. Toggle it in the character select screen.
Manny – Blast Beat Barrage · Chicken – Brown Note · Nik – Headbang Cyclone · Andz – Sweep Picking · Grindhouse/Maik – Feedback Drone · Armin – Standing Wave · Pimmel – Bauchladen Blitz · Theo – Backline Rig

### Misc
On death, one of 10 random taunts appears.

</details>

---

## Run from source

You only need Godot Engine 4.6: [godotengine.org/download](https://godotengine.org/download).

```bash
git clone https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill.git
```

Import it in Godot, open `project.godot`, press F5. No further dependencies.

### Exporting
Project, Export. Presets for Windows, macOS, Linux and Android are set up. For mobile the renderer must be set to Compatibility (`renderer/rendering_method.mobile="gl_compatibility"`, already set). Android requires the Android build templates, the Android SDK and JDK 17.

---

## System requirements

Windows 10 64-bit, macOS 10.15+ or Linux. 2 GB RAM. Around 200 MB storage. A Vulkan- or OpenGL-3.3-capable GPU (with the Compatibility renderer it also runs on older hardware).

---

## Known issues

- Music (MP3) may not be in the repository for copyright reasons; the game then runs without background music. Sound effects are generated procedurally.
- Connect controllers before starting the game.
- macOS: on first launch use right-click, Open.

---

## Built with

Godot 4.6, GDScript. Graphics drawn entirely procedurally. Audio from procedural WAV generation plus MP3 music. Localized in 5 languages.

*Home Reared Meat, Loud Enough to Kill, Copyright 2026 Armin Rolfes / Home Reared Meat*
