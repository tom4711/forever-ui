# Forever UI

Ein eigenständiges WoW-Forever-Addon für Spieler-, Ziel- und Gruppenrahmen, Klassenaktionen und Erfahrung. Die gemeinsame Fantasy-Gestaltung verwendet dunkles Petrol, Goldrahmen und gut lesbare Serifenschrift. Die vom Nutzer gezeigte ForeverFishing-Ansicht dient als Stilreferenz.

## Stand

**0.1.35-alpha** bündelt die Korrekturen aus dem Wartungsreview. Die [aktuelle Prüfrunde](docs/testing.md#prüfrunde-0135-alpha) beschreibt die Abläufe für den Test im Forever-Client.

**0.1.24-alpha** zeigt die eigene Spieler-Zauberleiste als schmales Panel mit kleinem Icon, Zaubername, Restzeit und einer dünnen Fortschrittslinie. Unter **Allgemein → Zauberleiste** kannst du auf die Blizzard-Anzeige zurückschalten oder die Größe einstellen. Zum Platzieren kannst du die Vorschau öffnen und bei entsperrten Positionen mit Alt beziehungsweise Option ziehen.

**0.1.18-alpha** bringt kompakte Klassenanzeigen für Jäger, Paladin und Hexer. Beim Jäger ergänzt die Begleitergruppe Rufen und Freigeben. Der Paladin kann Freiheit und Schutz auf sich selbst wirken. Der Hexer erhält Lebenslinie und die Herstellung eines Gesundheitssteins als Schnellzauber. Die Gruppen lassen sich in den Klassenoptionen einzeln einblenden und bei entsperrten Positionen verschieben.

**0.1.17-alpha** zeigt Buffs und Debuffs im Spielerrahmen in zwei festen Zeilen. Für zeitlich begrenzte Auren erscheint die Restzeit, soweit der Client sie bereitstellt. Weitere Icons einer Zeile sind per Mausrad erreichbar. Im Forever-Client zeichnet der native Aura-Container des Spiels die Icons und Restzeiten auch im Kampf. Das Priester-Control zeigt seine Zauber und Schnellzauber in kompakten Gruppen. Den aktuellen Stand der Prüfung im Spiel führt [docs/testing.md](docs/testing.md).

## Funktionen

- Hunter: Reichweitenzustände einschließlich unbekannter Werte, Munition mit einstellbarer Warnung und Begleiterstimmung.
- Füttern: geeignete Futterauswahl aus den Taschen und ein sicherer Klickbutton. Geschützte Änderungen werden während des Kampfes vorgemerkt.
- XP: getrennte Vorschausegmente für aktuelle XP (Türkis), fertige Questbelohnungen (Gold) und Erholungsbonus (Blau), dazu Sitzungsgewinn/-dauer, XP pro Stunde und geschätzte Restzeit. Die Vorschau wird auf die nächste Levelgrenze begrenzt; vollständige Bonuswerte stehen als Zahlen daneben.
- Flugzeit: während des Fluges verstrichene Zeit und eine eigene Routenschätzung aus Taxikarten-Geometrie; abgeschlossene Flüge verbessern die persönlichen Schätzwerte. Bei verfügbarer ForeverXPBar-SavedVariables-Datei können Routendaten einmalig migriert werden.
- Gemeinsamer Spielerrahmen für alle Klassen mit Porträt, Level, Gesundheit, Mana und getrennten Buff-/Debuff-Reihen; Auren sind reine Anzeige. Der Blizzard-Spielerrahmen kann in den allgemeinen Einstellungen wieder aktiviert werden.
- Getrennte Sichtbarkeit, Position und Skalierung pro Modul; zusätzliche XP-Breite von 620 bis 1600 Pixeln ohne Änderung von Höhe oder Schriftgröße; Einstellungen pro Charakter. Hunter wird nur auf Jägern, Paladin nur auf Paladinen und Hexer nur auf Hexern aktiviert; die passende Klassenanzeige ist standardmäßig sichtbar und pro Charakter abschaltbar.
- Deutsch mit englischem Fallback; keine anderen Addons als Voraussetzung.

## Installation und Bedienung

Den Ordner `ForeverUI` nach `Interface/AddOns/` im WoW-Forever-Client kopieren. Das Ergebnis muss `Interface/AddOns/ForeverUI/ForeverUI.toc` sein. Danach den Client neu starten und das Addon aktivieren.

- `/fui` öffnet die Einstellungen. Unter **Klassen → Tastenkürzel** lassen sich die Schnellaktionen des aktuellen Charakters belegen. Über **×** entfernst du eine Belegung. Sie wird pro Charakter gespeichert und ist aktiv, solange die Aktion in der Klassenanzeige sichtbar ist.
- `/fui preview` schaltet eine ausdrücklich als Beispieldaten gekennzeichnete Vorschau um.
- Rechtsklick auf dein Porträt öffnet das WoW-Spielermenü. Dort kannst du beispielsweise deine Gruppe verlassen.
- Positionen zum Verschieben entsperren und die jeweilige Anzeige mit Alt (Windows) beziehungsweise Option (macOS) ziehen.
- Quest- und Ruhebonus unabhängig in XP oder Prozent der für diese Stufe benötigten XP anzeigen.
- Als Paladin gelernte Auren und Segen anklicken; die aktive Aura erhält eine türkise Markierung. Über die Settings lassen sich zwei Equipment-Sets auswählen und per Klick anhand des Schildstatus wechseln. Als Hexer werden Dämonenstatus und Seelensplitter angezeigt; gelernte Dämonen lassen sich manuell beschwören.
- Beim Priester lassen sich Stärkungen, Gestalt, Unterstützung und Schnellzauber über die jeweiligen Zaubergruppen bedienen. Beim Schnellzauber „Nah“ hat mit Tastenkürzel die freundliche Einheit unter dem Mauszeiger Vorrang. Sonst wählt jeder Druck über die eingebaute WoW-Zielwahl den nächsten nahen freundlichen Spieler. Dieses Ziel bleibt ausgewählt, damit der nächste Druck weiterschalten kann. Unter den Schnellzaubern erscheinen für die Einheit unter der Maus die Zauberreichweite und der Seelenstärke-Status, soweit der Client diese Daten bereitstellt. Die Schnellzauber bieten Seelenstärke für einen nahen freundlichen Spieler und Seelenstärke, Schild und Erneuerung für dich selbst, sobald du diese Zauber gelernt hast.
- In der Begleitergruppe markiert „Mal + Begleiterangriff“ dein aktuelles Gegnerziel und schickt deinen Begleiter darauf. Die Aktion lässt sich unter **Klassen → Tastenkürzel** belegen.
- Als Jäger erlernte Aspekte direkt anklicken; Mend Pet und Revive Pet erscheinen als eigene manuelle Pet-Aktionen.
- Aspekte und Pet-Aktionen einschließlich Füttern unabhängig ein-/ausblenden und verschieben; eine türkise Markierung zeigt den aktiven Aspekt.
- Linksklick auf den Fütterbutton verwendet das gewählte Futter; Rechtsklick wählt anderes geeignetes Futter.

Die Blizzard-XP-Leiste bleibt erhalten. Der Blizzard-Spielerrahmen wird standardmäßig durch den Forever-Spielerrahmen ersetzt; über `/fui` kann die Ersetzung deaktiviert und der ursprüngliche Rahmen wieder angezeigt werden. Ein Maximallevel-Schalter steuert die zusätzliche XP-Anzeige. Auto-Quest und Level-Rennen gehören nicht zu dieser ersten Version. Quest-Vorschau-XP werden erst bei tatsächlicher Belohnung zu verdienten Sitzungs-XP.

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
