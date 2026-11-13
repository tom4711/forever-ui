# Forever UI

Ein eigenständiges WoW-Forever-Addon mit Hunter- und XP-Modul in einer gemeinsamen Fantasy-Gestaltung: dunkles Petrol, Goldrahmen und gut lesbare Serifenschrift. Die vom Nutzer gezeigte ForeverFishing-Ansicht dient als Stilreferenz.

## Stand

**0.1.3-alpha** enthält die erste Implementierung. Die Logik ist offline getestet; die vollständige Prüfung im Spiel steht aus. Die aktuelle Liste geprüfter und offener Fälle steht in [docs/testing.md](docs/testing.md).

## Funktionen

- Hunter: Reichweitenzustände einschließlich unbekannter Werte, Munition mit einstellbarer Warnung und Begleiterstimmung.
- Füttern: geeignete Futterauswahl aus den Taschen und ein sicherer Klickbutton. Geschützte Änderungen werden während des Kampfes vorgemerkt.
- XP: getrennte Vorschausegmente für aktuelle XP (Türkis), fertige Questbelohnungen (Gold) und Erholungsbonus (Blau), dazu Sitzungsgewinn/-dauer, XP pro Stunde und geschätzte Restzeit. Die Vorschau wird auf die nächste Levelgrenze begrenzt; vollständige Bonuswerte stehen als Zahlen daneben.
- Getrennte Sichtbarkeit, Position und Skalierung pro Modul; zusätzliche XP-Breite von 620 bis 1600 Pixeln ohne Änderung von Höhe oder Schriftgröße; Einstellungen pro Charakter. Hunter wird nur auf Jägern aktiviert.
- Deutsch mit englischem Fallback; keine anderen Addons als Voraussetzung.

## Installation und Bedienung

Den Ordner `ForeverUI` nach `Interface/AddOns/` im WoW-Forever-Client kopieren. Das Ergebnis muss `Interface/AddOns/ForeverUI/ForeverUI.toc` sein. Danach den Client neu starten und das Addon aktivieren.

- `/fui` öffnet die Einstellungen.
- `/fui preview` schaltet eine ausdrücklich als Beispieldaten gekennzeichnete Vorschau um.
- Positionen zum Verschieben entsperren und die jeweilige Anzeige mit Alt ziehen.
- Linksklick auf den Fütterbutton verwendet das gewählte Futter; Rechtsklick wählt anderes geeignetes Futter.

Die Blizzard-XP-Leiste bleibt erhalten. Ein Maximallevel-Schalter steuert die zusätzliche XP-Anzeige. Auto-Quest und Level-Rennen gehören nicht zu dieser ersten Version. Quest-Vorschau-XP werden erst bei tatsächlicher Belohnung zu verdienten Sitzungs-XP.

## Designvorschau

`preview/index.html` lässt sich direkt im Browser öffnen. Diese Ansicht zeigt die bestätigte Stilrichtung mit Beispieldaten. Sie führt keine Spielaktionen aus; ihre Vektor-Symbole und Schriften können von den Client-Ressourcen der Spielansicht abweichen.

## Entwicklung

Mit einem Lua-5.1-kompatiblen Interpreter: `lua tests/run.lua`.

Paket bauen: `python3 tools/package.py --output dist`. Python 3.9 oder neuer wird benötigt. Das ZIP enthält genau einen `ForeverUI`-Ordner mit den deklarierten Laufzeitdateien und Lizenzhinweisen.

- [Zielbild und Umfang von v0.1](docs/superpowers/specs/2026-11-13-first-version-design.md)
- [Umsetzungsplan](docs/superpowers/plans/2026-11-13-first-version.md)
- [Gestaltung und Medienherkunft](docs/media-sources.md)

## Lizenz

Eigener Code und die ursprüngliche Gestaltung stehen unter [MIT](LICENSE). Die Hinweise zur technischen ForeverHunter-Referenz bleiben im Addon erhalten. Referenzprojekte und ausschließlich aus dem Client geladene Ressourcen behalten ihre eigenen Rechte; Details stehen in [THIRD_PARTY.md](THIRD_PARTY.md).

Persönliches Projekt von [tom4711](https://github.com/tom4711). Das Repository ist öffentlich und Beiträge sind willkommen. Ein automatisches CurseForge-Release ist nicht eingerichtet.
