# Home Reared Meat – Loud Enough to Kill

Deutsch · [English](README.en.md)

> Brotato-artiges Roguelite-Rhythm-Game. Entwickelt mit Godot 4.6. Metal und Chaos.

Ein Wave-Survival-Roguelite, in dem du als Mitglied der Metal-Band Home Reared Meat im Takt der Musik gegen Wellen von Feinden kämpfst. 15 Story-Wellen mit durchgehender Handlung rund um den Konzern SoundCorp und seinen Chef Dr. Victor Stille, dazu Endless-Mode, 6 Bandmitglieder plus geheime und Bonus-Charaktere, viele Maps, lokaler Co-op und 5 Sprachen (Deutsch, Englisch, Französisch, Spanisch, Ukrainisch).

---

## Download

Neueste Version: [Release v1.3.0](https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill/releases/tag/v1.3.0)

- **Windows:** `HomeRearedMeat-Windows-v1.3.0.zip` entpacken und `HomeRearedMeat.exe` starten. Bei der Defender-Warnung: "Weitere Informationen", dann "Trotzdem ausführen".
- **macOS:** `HomeRearedMeat-macOS-v1.3.0.zip` entpacken, beim ersten Start Rechtsklick, "Öffnen" (die App ist unsigniert).
- **Android:** im eigenen Repo [home-reared-meat-mobile](https://github.com/nimraseflor84/home-reared-meat-mobile).

Frischer Start: die Builds enthalten keinen Spielstand. Es ist nur Manny freigeschaltet, alles andere muss neu freigespielt werden.

---

## Steuerung

| Aktion | Tastatur | Controller |
|--------|----------|------------|
| Bewegen | WASD oder Pfeiltasten | Linker Stick / D-Pad |
| Angriff | Automatisch | Automatisch |
| Dash | Shift oder rechte Maustaste | B |
| Ultimate | E | X |
| Pause | ESC | B |

Spieler 2 (lokaler Co-op) braucht zwingend einen zweiten Controller.

---

## Charaktere

| Charakter | Instrument | Stil |
|-----------|-----------|------|
| Manny | Schlagzeug | Schockwellen, Kills erhöhen das Angriffstempo |
| Chicken | Growl-Vocals | Präzisions-Todesstrahl |
| Nik | Inhale-Scream | Dreadlock-Peitsche, greift und wirft Feinde |
| Andz | Lead-Gitarre | Klingen, durchdringen mehrere Feinde |
| Grindhouse (Maik) | Rhythmus-Gitarre | Verzerrungsfelder verlangsamen Feinde |
| Armin | Bass | Sub-Bass-Wellen, Erdbebenstöße bei Kills |

Dazu kommen versteckte Charaktere und ein Bonus-Charakter, siehe [Freischaltungen](#easter-eggs-und-freischaltungen).

---

## Spielmodi

- **Story-Mode (15 Wellen):** durchgehende Handlung, Upgrade-Shop nach jeder Welle, Story-Sequenzen und Bosse. Local Co-op für 2 Spieler nur hier.
- **Endless-Mode:** unendliche Wellen auf wählbarer Map, alle 5 Wellen ein Boss, eigene Bestenliste.
- **Netzwerk-Co-op:** über lokales Netzwerk.

---

## Schwierigkeitsgrade

| Stufe | Name |
|-------|------|
| 0 | Access Denied |
| 1 | Vomit Blood |
| 2 | Brootal Destroy |
| 3 | Drink Fight Die! |
| 4 | Bolognese Bloodbath |

---

## Bosse

Zur Boss-Riege gehören unter anderem Willi, der Großbauer, der Dirigent (beschwört frühere Bosse), der Trucker und der TV-Star. Der Endboss von Akt IV ist Dr. Victor Stille, CEO von SoundCorp. Im Endless-Mode rotieren zehn Bosse.

---

## Easter Eggs und Freischaltungen

Versteckte Charaktere, Bonus-Inhalte und Geheim-Maps tauchen vor der Freischaltung nicht auf. Wer sich überraschen lassen will, klappt den Spoiler nicht auf.

<details>
<summary><b>Spoiler: alle Freischaltungen anzeigen</b></summary>

### Charaktere
- **Chicken / Nik / Andz / Grindhouse / Armin:** durch Erreichen von Welle 3 / 5 / 7 / 10 / 12.
- **Pimmel (Merch-Mann, geheim):** in einem einzigen Run 12 Upgrades nehmen.
- **Theo (Stagehand, geheim):** eine Boss-Welle ohne einen einzigen Treffer überstehen.
- **Toxo (Bonus, mutierter Toxic-Held):** den schwersten Grad (Bolognese Bloodbath) im Story-Mode durchspielen. Schaltet zusammen mit der Map Giftstadt frei.

### Maps
- **Nikolausdorf:** 1.000 Kills insgesamt, oder im Dezember spielen.
- **Der Strand:** das Spiel insgesamt 30-mal pausieren.
- **Giftstadt (Bonus):** den schwersten Grad durchspielen.

### Signature-Waffen
Jeder Charakter schaltet eine besondere zweite Waffe frei, wenn man den Story-Mode mit ihm auf Drink Fight Die! (zweitschwerster Grad) oder höher durchspielt. Umschalten im Charakter-Auswahlbildschirm.
Manny – Blast Beat Barrage · Chicken – Brown Note · Nik – Headbang Cyclone · Andz – Sweep Picking · Grindhouse/Maik – Feedback Drone · Armin – Standing Wave · Pimmel – Bauchladen Blitz · Theo – Backline Rig

### Sonstiges
Beim Tod erscheint einer von 10 zufälligen Spott-Sprüchen.

</details>

---

## Aus dem Quellcode starten

Du brauchst nur die Godot Engine 4.6: [godotengine.org/download](https://godotengine.org/download).

```bash
git clone https://github.com/nimraseflor84/home-reared-meat-loud-enough-to-kill.git
```

In Godot importieren, `project.godot` öffnen, F5 drücken. Keine weiteren Abhängigkeiten.

### Exportieren
Project, Export. Presets für Windows, macOS, Linux und Android sind angelegt. Für mobile Geräte muss der Renderer auf Compatibility stehen (`renderer/rendering_method.mobile="gl_compatibility"`, bereits gesetzt). Für Android werden die Android-Build-Templates, das Android SDK und JDK 17 benötigt.

---

## Systemvoraussetzungen

Windows 10 64-bit, macOS 10.15+ oder Linux. 2 GB RAM. Rund 200 MB Speicher. Vulkan- oder OpenGL-3.3-fähige GPU (mit Compatibility-Renderer läuft es auch auf älterer Hardware).

---

## Bekannte Probleme

- Musik (MP3) ist aus urheberrechtlichen Gründen eventuell nicht im Repository, das Spiel läuft dann ohne Hintergrundmusik. Soundeffekte werden prozedural erzeugt.
- Controller vor dem Spielstart anschließen.
- macOS: beim ersten Start Rechtsklick, Öffnen.

---

## Entwickelt mit

Godot 4.6, GDScript. Grafik vollständig prozedural gezeichnet. Audio aus prozeduraler WAV-Erzeugung plus MP3-Musik. Lokalisierung in 5 Sprachen.

*Home Reared Meat, Loud Enough to Kill, Copyright 2026 Armin Rolfes / Home Reared Meat*
