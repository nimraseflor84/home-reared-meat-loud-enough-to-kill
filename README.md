# HOME REARED MEAT – Loud Enough to Kill

> **Brotato-style Roguelite Rhythm Game** · Entwickelt mit Godot 4.6 · Metal & Chaos

Ein Wave-Survival-Roguelite in dem du als Mitglied der Metal-Band **Home Reared Meat** gegen Wellen von Feinden kämpfst – im Takt der Musik. 15 Story-Waves, Endless Mode, 6 spielbare Charaktere und lokaler Co-op für 2 Spieler.

---

## Inhalt

- [Spielen (fertig gebaute Version)](#spielen-fertig-gebaute-version)
- [Aus dem Quellcode starten](#aus-dem-quellcode-starten)
- [Spiel exportieren (eigene .exe bauen)](#spiel-exportieren-eigene-exe-bauen)
- [Systemvoraussetzungen](#systemvoraussetzungen)
- [Steuerung](#steuerung)
- [Charaktere](#charaktere)
- [Spielmodi](#spielmodi)
- [Bekannte Probleme](#bekannte-probleme)

---

## Spielen (fertig gebaute Version)

Wenn jemand bereits eine fertige `.exe` / ausführbare Datei weitergegeben hat:

### Windows
1. ZIP entpacken (Rechtsklick → Alle extrahieren)
2. `HRM-LoudEnoughToKill.exe` doppelklicken
3. Falls Windows Defender warnt: **„Weitere Informationen" → „Trotzdem ausführen"**
   *(Das Spiel ist kein Virus – Windows warnt bei unbekannten Entwicklern)*

### macOS
1. ZIP entpacken
2. `HRM-LoudEnoughToKill.app` in den Programme-Ordner ziehen *(optional)*
3. Beim ersten Start: **Rechtsklick → Öffnen** (nicht Doppelklick!)
4. Im Dialog „Von unbekanntem Entwickler" → **Öffnen** klicken
5. Falls das nicht klappt: Systemeinstellungen → Datenschutz & Sicherheit → **„Trotzdem öffnen"**

### Linux
```bash
chmod +x HRM-LoudEnoughToKill.x86_64
./HRM-LoudEnoughToKill.x86_64
```

---

## Aus dem Quellcode starten

### Was du brauchst

| Tool | Version | Download |
|------|---------|----------|
| **Godot Engine** | 4.3 oder neuer (4.6 empfohlen) | [godotengine.org/download](https://godotengine.org/download) |

Kein weiteres Tool nötig. Kein npm, kein Python, kein Compiler.

### Schritte

```bash
# 1. Repository klonen
git clone https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill.git

# 2. In den Ordner wechseln
cd "home-reared-meat-loud-enough-to-kill"
```

3. **Godot öffnen**
4. Im Godot Project Manager: **„Importieren"** → den geklonten Ordner auswählen → `project.godot` wählen → **Öffnen**
5. Oben rechts im Editor: **▶ Spielen** (F5) drücken

Das war's. Das Spiel läuft direkt – keine Abhängigkeiten, keine Setup-Schritte.

> **Hinweis zu Musik-Dateien:** Die MP3-Dateien im `assets/music/`-Ordner sind aus urheberrechtlichen Gründen möglicherweise nicht im Repository enthalten. Ohne sie startet das Spiel trotzdem – nur ohne Hintergrundmusik. Die Soundeffekte werden prozedural generiert und funktionieren immer.

---

## Spiel exportieren (eigene .exe bauen)

So baust du eine eigenständige Datei die ohne Godot läuft:

### Export-Templates installieren (einmalig)

1. Godot öffnen
2. Menü: **Editor → Manage Export Templates**
3. Im Dialog: **Download** neben der aktuellen Godot-Version klicken
4. Warten bis der Download fertig ist (~200 MB)

### Windows-Export

1. Menü: **Project → Export**
2. **„Add..."** → **Windows Desktop** wählen
3. Pfad wählen z.B. `export/windows/HRM-LoudEnoughToKill.exe`
4. **„Export Project"** klicken

**Wichtig:** Die erzeugte `.exe` muss zusammen mit der `.pck`-Datei im selben Ordner bleiben (oder als „Embedded" exportieren).

### macOS-Export

1. **Project → Export → Add → macOS**
2. Pfad wählen: `export/macos/HRM-LoudEnoughToKill.zip`
3. **„Export Project"** klicken
4. Die `.app`-Datei ist im ZIP enthalten

> Für einen signierten macOS-Build (ohne Sicherheitswarnungen) wird ein Apple Developer Account benötigt. Für privaten Gebrauch ist das nicht nötig.

### Linux-Export

1. **Project → Export → Add → Linux/X11**
2. Pfad: `export/linux/HRM-LoudEnoughToKill.x86_64`
3. **„Export Project"** klicken

### Compatibility-Renderer (für ältere GPUs)

Falls das Spiel auf einem älteren PC nicht startet (GPU unterstützt kein Vulkan):

1. Im Export-Dialog: **„Embed PCK"** aktivieren
2. Unter **„Rendering Method"**: `gl_compatibility` wählen
3. Neu exportieren → läuft dann auf praktisch jeder Hardware seit 2012

---

## Systemvoraussetzungen

### Minimum

| | Windows | macOS | Linux |
|---|---|---|---|
| **OS** | Windows 10 64-bit | macOS 10.15 (Catalina) | Ubuntu 20.04 / äquivalent |
| **CPU** | Dual-Core 2 GHz | Intel/Apple Silicon | x86_64 Dual-Core |
| **RAM** | 2 GB | 2 GB | 2 GB |
| **GPU** | Vulkan-fähig (GTX 600 / RX 400 +) | Metal-fähig | Vulkan oder OpenGL 3.3 |
| **Speicher** | ~200 MB | ~200 MB | ~200 MB |

### Mit Compatibility-Renderer (OpenGL)

| | Windows | macOS | Linux |
|---|---|---|---|
| **OS** | Windows 8.1+ | macOS 10.12+ | Ubuntu 18.04+ |
| **GPU** | OpenGL 3.3 fähig (GTX 400 / HD 4000 +) | Beliebig | OpenGL 3.3 |

> **Windows 7:** Wird von Godot 4 offiziell nicht mehr unterstützt.

---

## Steuerung

### Spieler 1

| Aktion | Tastatur | Controller (Joypad 1) |
|--------|----------|----------------------|
| Bewegen | WASD oder Pfeiltasten | Linker Stick / D-Pad |
| Angriff | Automatisch | Automatisch |
| Ultimate | E | X |
| Pause | ESC | B |

### Spieler 2 (Local Co-op)

| Aktion | Controller (Joypad 2) |
|--------|----------------------|
| Bewegen | Linker Stick / D-Pad |
| Angriff | Automatisch |
| Ultimate | X |

> Spieler 2 benötigt zwingend einen **zweiten Controller**. Tastatur-Steuerung für P2 ist nicht verfügbar.

### Controller-Belegung anpassen

Im Hauptmenü: **Optionen → Gameplay → Controller** – dort können alle Joypad-Buttons neu belegt werden.

---

## Charaktere

| Charakter | Instrument | Fähigkeit |
|-----------|-----------|-----------|
| **Manny** | Schlagzeug | Kills erhöhen Angriffsgeschwindigkeit |
| **Chicken** | Growler/Vocals | Präzisions-Todesstrahl, niedrige Frequenz |
| **Nik** | Inhale Screamer | Dreadlock-Peitsche, Feinde greifen & werfen |
| **Andz** | Lead Guitar | Klingen durchdringen mehrere Feinde |
| **Grindhouse** | Rhythm Guitar | Verzerrungsfelder verlangsamen Feinde |
| **Armin** | Bass | Sub-Bass-Wellen, Erdbebenstöße bei Kills |

Weitere Charaktere werden durch das Abschließen von Story-Waves freigeschaltet.

---

## Spielmodi

### Story Mode (15 Waves)
- Wave 1–15 mit steigender Schwierigkeit
- Nach jeder Wave: Upgrade-Shop (3 zufällige Upgrades)
- Bei Wave 5, 10 und 15: Story-Zwischensequenzen
- Bosse bei bestimmten Waves

### Endless Mode
- Unendliche Waves auf einer wählbaren Map
- Alle 5 Waves: Upgrade-Shop
- Jede 5. Wave: Boss-Rotation (10 verschiedene Bosse)
- Highscore-Bestenliste

### Local Co-op (2 Spieler)
- Nur im Story Mode verfügbar
- Im Charakter-Auswahl-Bildschirm: **„👥 2 SPIELER"** Button aktivieren
- Spieler 2 wählt seinen Charakter mit `<` / `>`
- Spieler 2 **muss** einen zweiten Controller angeschlossen haben
- Game Over erst wenn **beide** Spieler tot sind

---

## Schwierigkeitsgrade

| Stufe | Name | HP-Multiplikator | Schaden | Gegneranzahl |
|-------|------|-----------------|---------|--------------|
| 0 | Access Denied | ×0.35 | ×0.35 | ×0.45 |
| 1 | Vomit Blood | ×0.65 | ×0.65 | ×0.70 |
| 2 | Brootal Destroy | ×1.0 | ×1.0 | ×1.0 |
| 3 | Drink Fight Die! | ×1.6 | ×1.4 | ×1.45 |
| 4 | Bolognese Bloodbath | ×2.8 | ×2.0 | ×2.1 |

---

## Bekannte Probleme

- **Musik fehlt beim Klonen:** MP3-Dateien eventuell nicht im Repository enthalten – Spiel läuft ohne Musik
- **Controller wird nicht erkannt:** Joypad muss **vor** dem Spielstart angeschlossen sein; USB-Controller funktionieren zuverlässiger als Bluetooth
- **macOS Sicherheitswarnung:** Beim ersten Start Rechtsklick → Öffnen verwenden (siehe oben)
- **Schwarzer Screen unter Linux:** `libvulkan` installieren: `sudo apt install libvulkan1`

---

## Entwickelt mit

- **Engine:** [Godot 4.6](https://godotengine.org)
- **Sprache:** GDScript
- **Grafik:** Vollständig prozedural gezeichnet (keine externen Sprites)
- **Audio:** Prozedurale WAV-Generierung + MP3-Musik

---

*Home Reared Meat – Loud Enough to Kill © 2025 Home Reared Meat*
