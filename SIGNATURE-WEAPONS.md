# Signature Weapons – Design-Konzept

Ziel: Spieler länger binden. Pro Charakter eine besondere Waffe, die freigeschaltet wird, wenn man den Story-Mode mit diesem Charakter auf dem zweitschwersten Grad (Drink Fight Die!) oder höher durchspielt.

Leitidee: Die Signature-Waffe ist ein **Sidegrade**, kein reiner Power-Boost. Sie ändert den Spielstil und spiegelt die Identität und die Ultimate des Charakters. So entsteht Wiederspielwert statt Power-Creep, und der Originalcharakter bleibt voll spielbar.

---

## Freischalt-Logik

- **Bedingung:** Story-Mode mit Charakter X abschließen auf **Drink Fight Die! (Stufe 3)** oder **Bolognese Bloodbath (Stufe 4)**.
- **Auswahl:** Im Charakter-Auswahlbildschirm ein zweiter Waffen-Slot pro Charakter (Standard vs Signature). Vor der Freischaltung als gesperrtes Symbol mit Bedingungstext sichtbar, damit der Anreiz klar ist.
- **Persistenz:** Neues Array `unlocked_weapons` im Save (rückwärtskompatibel über den Top-Level-Merge, wie bei `unlocked_maps`).
- **Reveal:** Beim Sieg der goldene Unlock-Toast (System existiert bereits von Pimmel/Theo und den Geheim-Maps).
- **Lokalisierung:** Waffennamen bleiben englisch (Flavor, wie Songtitel), Beschreibungen in allen 5 Sprachen.

---

## Die Waffen

### Manny (Schlagzeug)
- **Blast Beat Barrage:** Schnelle Doppelschläge gleichzeitig nach vorne und hinten, im Takt. Das Tempo skaliert noch stärker mit der Combo als sein Standard.
- **Trade-off:** Kurze Reichweite, man muss nah ran.
- **Spiegelt:** Drummer, Rhythmus und Geschwindigkeit.

### Chicken (Growl-Vocals)
- **Brown Note:** Ein durchgehender Growl-Strahl, der am Auftreffpunkt einen Schaden-über-Zeit-Kegel bildet und Gegner kurz "anwidert" (Mini-Stun).
- **Trade-off:** Dreht langsam, wenig Burst, dafür Flächendruck.
- **Spiegelt:** Den gehaltenen Schrei statt Einzeltreffer.

### Nik (Inhale-Scream, Dreads)
- **Headbang Cyclone:** Nik wirbelt die Dreads dauerhaft im Kreis, ein Nahbereichs-Wirbel, der Gegner zurückschleudert und kurz betäubt.
- **Trade-off:** Nur Nahbereich, kein gezieltes Greifen einzelner Gegner mehr.
- **Spiegelt:** Die Peitsche, jetzt als Flächen-Wirbel.

### Andz (Lead-Gitarre)
- **Sweep Picking:** Klingen springen zwischen bis zu 5 Gegnern (Ketten-Bounce) statt nur durchzustechen, jeder Sprung etwas schwächer.
- **Trade-off:** Einzelne starke Gegner kriegen weniger ab, der Schaden verteilt sich.
- **Spiegelt:** Schnelle Lead-Läufe, die von Saite zu Saite springen.

### Maik / Grindhouse (Rhythmus-Gitarre)
- **Feedback Drone:** Eine dauerhafte Verzerrungs-Aura um den Spieler, die Gegner verlangsamt und langsam Schaden tickt, statt einzelner Felder. (Name "Feedback Drone" statt "Wall of Sound", weil es bereits ein Upgrade mit diesem Namen gibt.)
- **Trade-off:** Kaum Schaden auf Distanz, reine Kontroll- und Tank-Waffe.
- **Spiegelt:** Die konstante Rhythmuswand.

### Armin (Bass)
- **Standing Wave:** Ein stehender Sub-Bass-Ring in fester Entfernung um Armin, der im Takt pulst (Knockback plus Schaden).
- **Trade-off:** Feste Reichweite, direkt am Körper sind Gegner sicher.
- **Spiegelt:** Die stehende Welle einer tiefen Frequenz.

### Pimmel (Geheim, Merch-Mann)
- **Bauchladen Blitz:** Wirft drei Merch-Shirts gleichzeitig im Fächer, alle mit Boomerang-Bounce.
- **Trade-off:** Langsamere Wurfrate. Die Heilung über Kills bleibt.

### Theo (Geheim, Stagehand)
- **Backline Rig:** Theo stellt eine ortsfeste PA-Box auf (begrenzte Lebensdauer), die automatisch Gaffa-Rollen auf Gegner feuert, also ein Mini-Turret.
- **Trade-off:** Die Box ist stationär, man muss sich gut positionieren.

---

## Umsetzung (technisch)

- **Player-Scripts:** Pro Charakter eine zweite Variante von `_auto_attack`, geschaltet über eine Variable `signature_active`, die der GameManager beim Run-Start je nach Auswahl setzt.
- **GameManager:** Pro Charakter die gewählte Waffe merken (Standard oder Signature).
- **SaveManager:** `is_weapon_unlocked()` / `unlock_weapon()`. Freischaltung in `update_run_results()` bei Sieg und `difficulty >= 3`.
- **character_select:** Toggle-UI für den Waffen-Slot plus gesperrte Anzeige mit Bedingungstext.
- **Balancing:** Strikt als Sidegrade halten, per Run-Simulation gegentesten (wie im IMPROVEMENT_LOG dokumentiert).

---

## Empfehlung fürs Vorgehen

Nicht alle auf einmal. Erst ein bis zwei Prototypen bauen, testen ob es Spaß macht, dann den Rest nachziehen.

Vorschlag für die ersten beiden: **Armin (Standing Wave)** und **Andz (Sweep Picking)**. Beide sind visuell klar erkennbar und mechanisch deutlich anders als ihr Standard, eignen sich also gut, um zu prüfen ob das Feature trägt.
