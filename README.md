# HOME REARED MEAT – Loud Enough to Kill

> Brotato-artiges Roguelite-Rhythm-Game. Entwickelt mit Godot 4.6. Metal und Chaos.

**PC / Windows / macOS / Linux Version.** Die Android-Version liegt im eigenen Repo: [home-reared-meat-mobile](https://github.com/nimraseflor84/home-reared-meat-mobile).

Ein Wave-Survival-Roguelite, in dem du als Mitglied der Metal-Band **Home Reared Meat** im Takt der Musik gegen Wellen von Feinden kämpfst. 15 Story-Wellen mit durchgehender Handlung, Endless-Mode, 6 spielbare Charaktere plus 2 versteckte Geheimcharaktere, 10 Maps plus 2 Geheim-Maps, lokaler Co-op und 5 Sprachen.

---

## Inhalt

- [Worum geht es](#worum-geht-es)
- [Spielen (fertige Version)](#spielen-fertige-version)
- [Aus dem Quellcode starten](#aus-dem-quellcode-starten)
- [Steuerung](#steuerung)
- [Charaktere](#charaktere)
- [Spielmodi](#spielmodi)
- [Schwierigkeitsgrade](#schwierigkeitsgrade)
- [Bosse](#bosse)
- [Easter Eggs und Geheimnisse](#easter-eggs-und-geheimnisse)
- [Was zuletzt gemacht wurde](#was-zuletzt-gemacht-wurde)
- [Spiel exportieren](#spiel-exportieren)
- [Systemvoraussetzungen](#systemvoraussetzungen)
- [Bekannte Probleme](#bekannte-probleme)

---

## Worum geht es

Die Band Home Reared Meat gerät ins Visier von **SoundCorp** und dessen Chef **Dr. Victor Stille**, der mit einem Mutationsakkord die Welt zum Schweigen bringen will. Über vier Akte und 15 Wellen spielt ihr euch durch SoundCorps Tonstudios, Dörfer und Bühnen, bis zum Showdown gegen den CEO selbst.

Die Story wird in Zwischensequenzen bei Welle 5, 10 und 15 erzählt und durch kurze Band-Funk-Dialoge vor jeder Welle weitergetragen. Bei Erstkontakt mit einem neuen Gegnertyp erscheint ein kleiner Lore-Hinweis mit Namen und Hintergrund (alle 21 Gegnertypen).

---

## Spielen (fertige Version)

Wenn dir jemand eine fertig gebaute Datei weitergegeben hat:

### Windows
1. ZIP entpacken (Rechtsklick, Alle extrahieren)
2. `HomeRearedMeat.exe` doppelklicken
3. Falls Windows Defender warnt: "Weitere Informationen", dann "Trotzdem ausführen". Das Spiel ist kein Virus, Windows warnt nur bei unbekannten Entwicklern.

### macOS
1. ZIP entpacken
2. App in den Programme-Ordner ziehen (optional)
3. Beim ersten Start: Rechtsklick, Öffnen (nicht Doppelklick)
4. Im Dialog "Von unbekanntem Entwickler" auf Öffnen klicken
5. Falls das nicht klappt: Systemeinstellungen, Datenschutz und Sicherheit, "Trotzdem öffnen"

### Linux
```bash
chmod +x HomeRearedMeat.x86_64
./HomeRearedMeat.x86_64
```

---

## Aus dem Quellcode starten

Du brauchst nur die **Godot Engine 4.3 oder neuer** (4.6 empfohlen): [godotengine.org/download](https://godotengine.org/download). Kein npm, kein Python, kein Compiler.

```bash
git clone https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill.git
cd "home-reared-meat-loud-enough-to-kill"
```

Dann Godot öffnen, im Project Manager auf "Importieren", den Ordner und die `project.godot` wählen, öffnen, und oben rechts auf Spielen (F5) drücken. Das Spiel läuft direkt, ohne weitere Abhängigkeiten.

> Hinweis zur Musik: Die MP3-Dateien in `assets/music/` sind aus urheberrechtlichen Gründen eventuell nicht im Repository. Ohne sie startet das Spiel trotzdem, nur ohne Hintergrundmusik. Die Soundeffekte werden prozedural erzeugt und funktionieren immer.

---

## Steuerung

### Spieler 1

| Aktion | Tastatur | Controller |
|--------|----------|------------|
| Bewegen | WASD oder Pfeiltasten | Linker Stick / D-Pad |
| Angriff | Automatisch | Automatisch |
| Dash | Shift oder rechte Maustaste | B |
| Ultimate | E | X |
| Pause | ESC | B |

Der Dash hat unten links eine Cooldown-Anzeige (blau bedeutet bereit, orange bedeutet lädt).

### Spieler 2 (Local Co-op)

| Aktion | Controller |
|--------|------------|
| Bewegen | Linker Stick / D-Pad |
| Angriff | Automatisch |
| Ultimate | X |

Spieler 2 braucht zwingend einen zweiten Controller, eine Tastatur-Steuerung für P2 gibt es nicht. Belegung anpassbar im Hauptmenü unter Optionen, Gameplay, Controller.

---

## Charaktere

Die sechs Bandmitglieder. Angriff läuft bei allen automatisch, der Charakter bestimmt Waffe, Ultimate und eine Kill-Passive.

| Charakter | Instrument | Waffe / Stil | Kill-Passive |
|-----------|-----------|--------------|--------------|
| **Manny** | Schlagzeug | Schockwellen | Kills erhöhen die Angriffsgeschwindigkeit |
| **Chicken** | Growl-Vocals | Präzisions-Todesstrahl | Precision Focus: Kill setzt den Angriffstimer zurück (sofort nächster Schuss) |
| **Nik** | Inhale-Scream | Dreadlock-Peitsche, greift und wirft Feinde (max 4 Ziele) | Adrenalin-Schub: Kill gibt 35 Prozent Tempo für 2,2s |
| **Andz** | Lead-Gitarre | Klingen, durchdringen mehrere Feinde | Blade Momentum: Kill feuert 2 extra Klingen |
| **Grindhouse** | Rhythmus-Gitarre | Verzerrungsfelder, verlangsamen Feinde | Distortion Field: Kill verlangsamt Feinde im Umkreis um 55 Prozent für 2,5s |
| **Armin** | Bass | Sub-Bass-Wellen, Erdbebenstöße | Low End Theory: jeder 4. Treffer löst eine Mini-Schockwelle aus |

Dazu kommen zwei versteckte Charaktere, siehe [Easter Eggs](#easter-eggs-und-geheimnisse).

---

## Spielmodi

**Story-Mode (15 Wellen).** Beginnt mit dem Intro (Akt I). Nach jeder Welle ein Upgrade-Shop mit 3 zufälligen Upgrades. Story-Sequenzen bei Welle 5, 10 und 15, Bosse an festen Wellen. Local Co-op für 2 Spieler nur hier verfügbar (im Charakterwählen den 2-Spieler-Modus aktivieren, Game Over erst wenn beide tot sind).

**Endless-Mode.** Unendliche Wellen auf einer wählbaren Map. Alle 5 Wellen ein Shop, jede 5. Welle ein Boss aus der Rotation (10 verschiedene). Eigene Highscore-Bestenliste. Die Geheim-Maps sind nur hier wählbar.

**Netzwerk-Co-op.** Co-op-UI für das Spielen über Netzwerk ist im Spiel vorhanden.

---

## Schwierigkeitsgrade

| Stufe | Name | HP | Schaden | Gegneranzahl |
|-------|------|----|---------|--------------|
| 0 | Access Denied | x0.35 | x0.35 | x0.45 |
| 1 | Vomit Blood | x0.65 | x0.65 | x0.70 |
| 2 | Brootal Destroy | x1.0 | x1.0 | x1.0 |
| 3 | Drink Fight Die! | x1.6 | x1.4 | x1.45 |
| 4 | Bolognese Bloodbath | x2.8 | x2.0 | x2.1 |

---

## Bosse

Zur Boss-Riege gehören unter anderem Willi, der Großbauer, der Dirigent (beschwört frühere Bosse), der Trucker, der TV-Star und mehr. Der Endboss von Akt IV ist **Dr. Victor Stille, CEO von SoundCorp**. Im Endless-Mode rotieren zehn Bosse durch.

---

## Easter Eggs und Geheimnisse

Das Spiel hat zwei versteckte Charaktere, zwei Geheim-Maps und zufällige Spott-Sprüche beim Tod. Geheimcharaktere und Geheim-Maps tauchen vor der Freischaltung nicht auf, auch nicht als "???". Wer sich überraschen lassen will, klappt den Spoiler unten nicht auf.

<details>
<summary><b>Spoiler: So schaltest du alles frei</b></summary>

### Geheimcharakter Pimmel (der Merch-Mann)
Sombrero, Sonnenbrille, Schnauzer, gelbes Hawaiihemd, Becher in der Hand. Waffe: Merch-Shirts als Bumerang, prallen einmal von der Bildschirmkante ab. Ultimate "Bauchladen-Rausch": Becher-Salve im Kreis plus Slow-Welle. Passive "Verkaufsschlager": jeder 6. Kill lässt ein Merch-Paket fallen und heilt 5 LP.
**Freischaltung:** in einem einzigen Run 12 Upgrades nehmen.

### Geheimcharakter Theo (der Stagehand)
Geheimratsecken, Kinnbart, rotes Flanellhemd, Gaffa-Rolle am Gürtel. Waffe: Gaffa-Tape-Rollen, durchdringen 2 Feinde. Ultimate "PA-Drop": eine Lautsprecherbox fällt auf die dichteste Gegnergruppe. Passive "Schnelle Bühne": jeder Kill verkürzt den Ultimate-Cooldown um 0,5s.
**Freischaltung:** eine Boss-Welle ohne einen einzigen Treffer überstehen.

### Geheim-Map Nikolausdorf
Schneeboden, zugefrorener Dorfteich, schneebedeckte Häuser mit Lichterketten, großer Weihnachtsbaum, Schneemann, fallende Flocken.
**Freischaltung:** insgesamt 1.000 Kills über alle Runs, oder automatisch, wenn im Dezember gespielt wird.

### Geheim-Map Der Strand
Die Strand-Szene aus dem Pausenmenü als spielbare Map: Meer, Palmen, Handtücher, Sonnenschirm, Krebse und mitten im Sand der Fahrstuhl aus dem Pausenmenü.
**Freischaltung:** das Spiel insgesamt 30-mal pausieren.

### Spott-Sprüche beim Tod
Stirbt man (nicht beim Sieg), erscheint einer von 10 zufälligen Sprüchen, die auf die Easter Eggs und die Spielwelt anspielen (Pimmels Merch, Theos Gaffa, Willi und Gerlinde, Dr. Stille, das umgekippte Bier).

</details>

---

## Was zuletzt gemacht wurde

Eine Kurzfassung der letzten Entwicklungsschritte (Details in `IMPROVEMENT_LOG.md`):

- **Story-Paket:** Akt I wird jetzt korrekt angezeigt, durchgehender roter Faden um SoundCorp und Dr. Stille, Band-Funk-Dialoge vor jeder Welle, Gegner-Lore bei Erstkontakt, einheitlicher Endboss-Name.
- **Komplette Lokalisierung:** Deutsch, Englisch, Französisch, Spanisch und Ukrainisch durchgängig, inklusive aller 37 Upgrade-Beschreibungen, Boss- und Map-Namen, Tutorial und Story.
- **Zwei Geheimcharaktere** (Pimmel und Theo) und **zwei Geheim-Maps** (Nikolausdorf und Der Strand) als Easter Eggs.
- **PC-Dash sichtbar gemacht:** Cooldown-Anzeige und zweite Belegung auf der rechten Maustaste.
- **Großes Audit mit Balancing:** rund 70 Befunde aus 12 Prüf-Durchläufen, davon viele direkt gefixt (Save-System, Boss-Erkennung, Rhythm- und Crowd-Upgrades, Co-op-Targeting und mehr).

---

## Spiel exportieren

Einmalig die Export-Templates installieren: in Godot unter Editor, Manage Export Templates, Download neben der passenden Version (rund 200 MB).

Dann unter Project, Export das gewünschte Preset wählen (Windows, macOS, Linux sind angelegt) und auf Export Project klicken.

> **Compatibility-Renderer für ältere GPUs oder für Mobile:** Unter Project Settings, Rendering, Renderer die Rendering-Methode auf "Compatibility" stellen (für Mobile als Mobile-Override). Das läuft auf praktisch jeder Hardware. Für die Android-Version ist das zwingend nötig, siehe das [Mobile-Repo](https://github.com/nimraseflor84/home-reared-meat-mobile).

Hinweise zu macOS Code-Signing und Notarisierung für eine Veröffentlichung stehen in `RELEASE-CHECKLISTE.md`.

---

## Systemvoraussetzungen

| | Windows | macOS | Linux |
|---|---|---|---|
| OS | Windows 10 64-bit | macOS 10.15 | Ubuntu 20.04 |
| RAM | 2 GB | 2 GB | 2 GB |
| GPU | Vulkan-fähig | Metal-fähig | Vulkan oder OpenGL 3.3 |
| Speicher | rund 200 MB | rund 200 MB | rund 200 MB |

Mit dem Compatibility-Renderer (OpenGL 3.3) läuft das Spiel auch auf deutlich älterer Hardware.

---

## Bekannte Probleme

- **Musik fehlt beim Klonen:** MP3-Dateien eventuell nicht im Repository, das Spiel läuft dann ohne Musik.
- **Controller wird nicht erkannt:** Joypad vor dem Spielstart anschließen, USB läuft zuverlässiger als Bluetooth.
- **Schwarzer Screen unter Linux:** `sudo apt install libvulkan1`.

---

## Entwickelt mit

Godot 4.6, GDScript. Grafik vollständig prozedural gezeichnet (keine externen Sprites). Audio aus prozeduraler WAV-Erzeugung plus MP3-Musik. Lokalisierung in 5 Sprachen.

*Home Reared Meat, Loud Enough to Kill, Copyright 2026 Armin Rolfes / Home Reared Meat*
