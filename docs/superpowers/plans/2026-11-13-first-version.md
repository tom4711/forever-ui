# Forever UI v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein eigenständiges, im gewünschten Fantasy-Stil gestaltetes WoW-Forever-Addon mit nutzbarem Hunter- und XP-Modul erstellen.

**Architecture:** Ein installierbares `ForeverUI`-Addon mit gemeinsamer Oberfläche, gemeinsamen Charaktereinstellungen und zwei unabhängig aktivierbaren Modulen. Berechnung, WoW-Datenzugriff und Darstellung bleiben getrennt. Der Fütterbutton bleibt ein eigener geschützter Frame.

**Tech Stack:** Lua in einem mit dem WoW-Client kompatiblen Sprachumfang, WoW-Frame- und Ereignis-API, eigene Medien bzw. Referenzen auf Client-Ressourcen, Lua für Offline-Logiktests, Python 3 für Paketbau.

**Spec:** [Zielbild und Umfang](../specs/2026-11-13-first-version-design.md)

**Status:** Nutzer hat Umfang und direkte Umsetzung bestätigt. Die Designvorschau ist ebenfalls bestätigt; die Implementierung läuft.

## Global Constraints

- Zielclient: WoW Forever; TOC-Interface zunächst `16001`, vor dem Paketbau im laufenden Client prüfen. Retail-/Classic-Unterstützung wird nicht zugesagt.
- Ein Addon-Paket mit zwei Modulen; keine Abhängigkeit von den drei Referenz-Addons und keine gemeinsame Konfiguration mit ihnen.
- Keine zusätzlichen Laufzeitbibliotheken für v0.1.
- Eigenes Addon `ForeverUI`, Chatbefehl `/fui`, Charakterdaten `ForeverUICharDB`.
- Eigener Code unter MIT; Herkunft möglicher ForeverHunter-Übernahmen mit dessen vollständigem Copyright-/Lizenzhinweis erhalten. Keine Übernahme von ForeverXPBar-/ForeverFishing-Code oder deren eigenen Medien.
- Darstellung und Berechnung trennen. WoW-Daten zuerst auf Lesbarkeit prüfen; erst danach vergleichen, rechnen oder formatieren.
- Keine Änderungen an bestehenden Addons, Einstellungen oder SavedVariables. Installation von ForeverUI erst beim ausdrücklich gestarteten Spieltest.
- Das Nutzerbild ist Stilreferenz; es wird nicht im Addon-Paket ausgeliefert.

## Review Focus

1. Unbekannte oder geschützte Reichweitenwerte dürfen keine scheinbar sichere Distanz erzeugen – Task 3.
2. Kampf kann während einer laufenden Einstellungsänderung beginnen; sichere Buttonattribute und dessen Geometrie bleiben dann unverändert – Task 4 plus Spieltest in Task 5.
3. XP-Ereignisse beim Levelaufstieg, mehrstufige Sprünge und Maximallevel dürfen keine negativen Gewinne oder ungültigen Zeiten erzeugen – Task 2.
4. UI-Neuladen und neue Anmeldung müssen Sitzungen unterschiedlich behandeln; Charakterdaten bleiben getrennt – Tasks 1/2.
5. Leere Munition, fehlender/toter Begleiter und noch nicht geladene Futterdaten müssen verständliche, bedienbare Zustände ergeben – Tasks 3/4.

## Arbeitsfolge

Direkte Umsetzung in diesem Chat ist der Vorschlag: erst gemeinsame Gestaltung, danach Hunter samt Füttern, anschließend XP und abschließend der gemeinsame Spieltest. Task 2 (XP) und Task 3 (Hunter) sind technisch nach Task 1 möglich; die vorgeschlagene Ausführungsreihenfolge lautet **1 → 3 → 4 → 2 → 5**, damit früh ein vollständiges Hunter-Modul sichtbar wird.

Vor Produktcode: Entwurf und v0.1-Umfang prüfen lassen, dann den gewählten Ausführungsworkflow verwenden. Vor Beginn aktive Arbeitskopie und lokale Änderungen prüfen; falls Isolation benötigt wird, den Worktree-Workflow verwenden. In dieser Planungsphase bleibt die bestehende Arbeitskopie erhalten.

## Task 1: Installierbare Designvorschau und gemeinsame Basis

**Files – Create:**
- `ForeverUI/ForeverUI.toc`, `ForeverUI/Locales.lua`
- `ForeverUI/Core/Bootstrap.lua`, `ForeverUI/Core/Settings.lua`, `ForeverUI/Core/Read.lua`
- `ForeverUI/UI/Theme.lua`, `ForeverUI/UI/Widgets.lua`, `ForeverUI/UI/Preview.lua`, `ForeverUI/UI/Settings.lua`
- `tests/run.lua`, `tests/settings_test.lua`, `tests/read_test.lua`
- `docs/testing.md`, `docs/media-sources.md`

**Interfaces:**
- `ns.Settings.Load(saved) -> config` stellt gültige Charaktereinstellungen her, erhält bekannte Werte und ersetzt ungültige Werte durch dokumentierte Defaults.
- `config.hunter` und `config.xp`: `enabled`, `scale`, `position`; `config.locked` ist die gemeinsame Verschiebesperre. `config.hunter.ammoWarning` und `config.xp.showAtCap` ergänzen die Module.
- `ns.Read.Number(value) -> number|nil` und `ns.Read.Boolean(value) -> boolean|nil` geben nur lesbare Werte des passenden Typs zurück. `issecretvalue` vor jeder Typ-/Wertauswertung nutzen, sofern verfügbar.
- `ns.UI.CreatePanel(parent, id) -> frame` liefert einen gestalteten Frame mit `content`-Anker; `ns.UI.CreateIconButton(parent, id) -> button` liefert einen normalen, ungeschützten Symbolknopf. Task 4 übernimmt für den sicheren Button nur die Gestaltung.
- `ns.Preview.SetEnabled(enabled)` arbeitet mit eigenen Beispieldaten, ohne Live-Statistiken oder geschützte Frames zu verändern; im Kampf ist ein Wechsel nicht zulässig.
- `/fui` öffnet die gemeinsamen Einstellungen; `/fui preview` schaltet die beschriftete Vorschau um. Bei jeder Anmeldung startet der Live-Modus.

- [x] **1. Voraussetzungen prüfen:** `lua -v` und `python3 --version` ausführen. Falls erforderlich, vor dem ersten Logiktest einen geeigneten Interpreter aus vertrauenswürdiger Quelle bereitstellen und den verwendeten Aufruf in `docs/testing.md` festhalten. Das Addon darf keine nur in neueren Desktop-Lua-Versionen verfügbaren Sprachmittel benötigen.
- [x] **2. Verhalten der Einstellungen und Datenleser als Tests festlegen:** leere Daten liefern skalierte Standardwerte, `ammoWarning=200`, `showAtCap=true`; gültige gespeicherte Positionen bleiben erhalten; getrennte Eingabetabellen teilen keine veränderlichen Defaults. Geschützte Testwerte, falsche Typen und nicht endliche Zahlen liefern `nil`, ohne vorher verglichen/formatiert zu werden.
- [x] **3. Tests mit `lua tests/run.lua` ausführen:** Vor der Implementierung müssen die benannten Tests wegen der fehlenden Funktionen fehlschlagen. Der Runner lädt WoW-Dateien mit einer Test-Namensraumtabelle; keine umfangreiche Nachbildung des Clients erstellen.
- [x] **4. Basis implementieren:** eindeutiger Namensraum, pro Charakter gespeicherte Einstellungen, DE-Texte mit EN-Fallback und geordnete TOC-Ladereihenfolge. Keine Original-Addon-Daten migrieren oder überschreiben. Skalierung und Position gemeinsam validieren, Frames auf dem Bildschirm halten.
- [x] **5. Gemeinsame Gestaltung und Vorschau erstellen:** beide Modulansichten mit realistisch beschrifteten Beispieldaten und einem Einstellungsfenster zeigen. Petrol, Gold, Serifenschrift und plastische Symbolknöpfe anhand des Nutzerbilds umsetzen. Alle ausgelieferten Medien in `docs/media-sources.md` nachweisen; Client-Ressourcen nur referenzieren.
- [x] **6. Vorschau vorlegen:** Nutzer bewertet Stil, Größe, Informationsdichte und Lesbarkeit. Konkrete Geometrie und wesentliche Änderungen im Zielbild festhalten, bevor die endgültigen Modulansichten entstehen. Ein externes Mockup ist als Vorschau zu kennzeichnen und bestätigt keine Funktion im Spiel.
- [x] **7. Prüfen und committen:** `lua tests/run.lua` muss alle bisherigen Tests bestehen; TOC und Dateien statisch prüfen. Einen Commit mit dem eigenständig prüfbaren Ergebnis „gemeinsame Basis und Designvorschau“ erstellen.

## Task 2: XP-Modul mit belastbarer Sitzungsstatistik

**Files – Create:** `ForeverUI/Modules/XP/Model.lua`, `ForeverUI/Modules/XP/Controller.lua`, `ForeverUI/Modules/XP/View.lua`, `tests/xp_test.lua`. **Modify:** TOC, gemeinsame Einstellungen und `docs/testing.md`.

**Interfaces:**
- `ns.XPModel.New(snapshot, startedAt) -> state`, `ns.XPModel.Observe(state, snapshot) -> state` und `ns.XPModel.Summarize(state, now) -> summary` sind unabhängig von WoW-Frames.
- `snapshot = {level, current, maximum, rested, at, atCap}` enthält ausschließlich lesbare Werte oder `nil`; `at` und `startedAt` benutzen dieselbe reloadfeste Zeitbasis.
- `summary = {level, current, maximum, percent, remaining, restedEnd, earned, elapsed, perHour, eta, atCap, reliable}`; fehlende Auswertbarkeit ergibt `nil`-Werte und `reliable=false`, niemals erfundene Zahlen. `restedEnd` ist auf das XP-Maximum begrenzt.
- Controller bindet geprüfte Client-APIs und relevante XP-, Level-, Erholungs- und Anmeldeereignisse an. View verwendet Task-1-Komponenten; `nil` erscheint als „–“.

- [ ] **1. Failing Tests schreiben:** normale Gewinne, keine Gewinne, Levelübergang, doppelte Ereignisse, mehrstufiger Sprung, Maximallevel, unlesbare Daten und Sitzungsneustart prüfen. Konkreter Levelübergang: vorher Level 10 / 90 von 100 XP, danach Level 11 / 10 von 150 XP → 20 XP Gewinn; eine identische Folgemeldung zählt 0 hinzu.

```lua
local s = ns.XPModel.New({level=10,current=90,maximum=100,rested=0,at=0,atCap=false}, 0)
s = ns.XPModel.Observe(s, {level=11,current=10,maximum=150,rested=0,at=60,atCap=false})
local r = ns.XPModel.Summarize(s, 60)
assert(r.earned == 20)
assert(r.perHour == 1200)
assert(r.remaining == 140)
assert(r.eta == 420)
```

- [ ] **2. `lua tests/run.lua` ausführen:** neue XP-Tests müssen zunächst fehlschlagen, vorhandene Tests weiter bestehen.
- [ ] **3. Modell implementieren:** Rate aus verlässlich erfassten Gewinnen und Sitzungszeit berechnen; ETA nur bei positiver Rate und sinnvoller Restmenge. Bei Datenlücken/mehrem Levelsprung die Messung an einer neuen gültigen Basis beginnen und den Bruch kennzeichnen. Keine stillschweigende Schätzung übersprungener Levelkosten.
- [ ] **4. Controller und Persistenz anschließen:** API-Signaturen im aktuellen Forever-Client prüfen; Anmelde-/Reload-Unterscheidung verwenden. Über `/reload` erhaltene Sitzung mit derselben Zeitbasis fortsetzen; echte Neuanmeldung setzt sie zurück. Level-/XP-Ereignisreihenfolge im Client prüfen und zusammengehörige Aktualisierungen konsistent einlesen.
- [ ] **5. Ansicht integrieren:** Level, XP-Balken, begrenzte Erholungsmarkierung, Prozent, fehlende XP, Sitzungsgewinn/-dauer, XP/h und ETA im bestätigten Stil darstellen. Maximallevel und fehlende Daten ausdrücklich zeigen; Blizzard-Leiste bleibt unverändert.
- [ ] **6. Prüfen und committen:** `lua tests/run.lua`; in `docs/testing.md` konkrete Spielchecks für XP-Gewinn, `/reload`, Neuanmeldung und Levelaufstieg ergänzen. Ergebnis: eigenständig nutzbares XP-Modul, Clientprüfung ggf. noch offen.

## Task 3: Hunter-Anzeigen ohne geschützte Aktionen

**Files – Create:** `ForeverUI/Modules/Hunter/Model.lua`, `ForeverUI/Modules/Hunter/Controller.lua`, `ForeverUI/Modules/Hunter/View.lua`, `tests/hunter_test.lua`. **Modify:** TOC, Einstellungen, `THIRD_PARTY.md` bei tatsächlicher MIT-Codeübernahme, `docs/testing.md`.

**Interfaces:**
- `ns.HunterModel.ResolveZone(validTarget, shot, melee, near) -> zone`: `zone` ist `none`, `unknown`, `ranged`, `melee`, `deadzone` oder `far`; drei Prüfwerte sind `true`, `false` oder `nil`.
- `ns.HunterModel.AmmoTransition(previousLow, count, threshold) -> low, warn`: `count=nil` bedeutet unbekannt, `threshold=0` schaltet Warnungen aus. Beim Start wird `previousLow=false` übergeben.
- Controller erzeugt `{zone, ammoCount, ammoIcon, petState}`; View rendert diese normalisierten Daten. `petState` unterscheidet mindestens fehlend, tot, unbekannt sowie die drei Stimmungen.

- [x] **1. Failing Tests schreiben:** gültiger Treffer der Fernkampf-/Nahkampfprüfung; tote Zone nur bei `shot=false`, `melee=false`, `near=true`; `far` nur bei drei bekannten negativen Prüfungen; fehlende Ergebnisse bleiben unbekannt. Außerdem kein/ungeeignetes Ziel, leere Munition, Warngrenze und Wiederbewaffnung der Warnung prüfen.

```lua
assert(ns.HunterModel.ResolveZone(true, false, false, true) == "deadzone")
assert(ns.HunterModel.ResolveZone(true, nil, false, false) == "unknown")
assert(ns.HunterModel.ResolveZone(false, nil, nil, nil) == "none")
local low, warn = ns.HunterModel.AmmoTransition(false, 199, 200)
assert(low == true and warn == true)
```

- [x] **2. `lua tests/run.lua` ausführen:** neue Hunter-Tests müssen zunächst fehlschlagen.
- [x] **3. Datenadapter implementieren:** Prüfungen auf Auto Shot, einen Nahkampf-Itemcheck und Interaktionsreichweite im aktuellen Client validieren; bei Bedarf die öffentlich unter MIT veröffentlichte ForeverHunter-Version als Referenz heranziehen. Fehlende Itemdaten asynchron anfordern; geschützte oder nicht auswertbare Ergebnisse auf `nil` abbilden. Keine exakte Meter-/Yardzahl anzeigen.
- [x] **4. Munitions- und Begleiterdaten anschließen:** leeren Munitionsplatz als 0 behandeln; unbekannte Daten bleiben unbekannt. Munitionswarnungen nur beim Zustandswechsel bzw. einmal unterhalb der Schwelle beim Start. Begleiter fehlt/tot und unbekannte Stimmung getrennt behandeln.
- [x] **5. Ansicht und Aktivierung integrieren:** Hunter nur auf Jägern aktiv; Text plus Farbe für Reichweite, Icon und Menge für Munition, Symbol/Tooltip für Stimmung. Reichweite maximal alle 0,2 Sekunden prüfen; Pause bei ausgeblendetem Modul, kein Taschenscan pro Bild.
- [x] **6. Prüfen und committen:** `lua tests/run.lua` sowie dokumentierte Clientchecks für Zielwechsel, vier Reichweiten und Datenlücken. Quellübernahmen falls erfolgt exakt in `THIRD_PARTY.md` mit Original-Lizenz aufnehmen. Ergebnis: Hunter-Anzeige funktioniert ohne Fütterbutton.

## Task 4: Sicherer Fütterbutton und Einstellungen im Kampf

**Files – Create:** `ForeverUI/Core/CombatQueue.lua`, `ForeverUI/Modules/Hunter/Feed.lua`, `tests/combat_queue_test.lua`, `tests/food_test.lua`. **Modify:** Hunter-Ansicht/-Controller, gemeinsame Einstellungen, TOC und `docs/testing.md`.

**Interfaces:**
- `ns.CombatQueue.Request(key, apply)`, `ns.CombatQueue.Flush()` speichern pro Schlüssel die letzte vorgemerkte Konfiguration. Eine zentral injizierte Kampfprüfung verhindert `apply`, solange die Sperre aktiv ist; vor jedem Aufruf erneut prüfen.
- `ns.HunterFeed.Refresh(config)` ist der einzige Weg zu geschützten Attribut-, Positions-, Skalierungs- und Sichtbarkeitsänderungen; alle Einstellungswege benutzen ihn.
- `ns.HunterFeed.Foods() -> entries` liefert geeignete Taschenfutter-IDs ohne Duplikate, mit lesbarer Menge und ggf. noch fehlendem Namen. Nicht geladene Namen werden nachgefordert; kein unvollständiger sicherer Futterbezug wird aktiviert.

- [ ] **1. Failing Tests schreiben:** vorgemerkte Änderung im Kampf wird nicht ausgeführt; mehrere Änderungen desselben Schlüssels wenden nach Kampfende nur die letzte an; beginnt die Sperre während `Flush`, werden übrige Änderungen aufbewahrt. Food-Test: doppelte Item-ID nur einmal, ungeeignetes/leeres Futter ausgeschlossen, unbekannter Name noch nicht als verwendbares Futter aktiviert.
- [ ] **2. `lua tests/run.lua` ausführen:** neue Tests müssen zunächst fehlschlagen. Diese Tests prüfen nur Warteschlangen- und Filterlogik, keine Sicherheitseigenschaften der WoW-Engine.
- [ ] **3. Warteschlange und Futterabfrage implementieren:** Taschenupdates und erfolgreiche Itemdaten-Ladung verwenden; keine Bankenbestände als verfügbares Taschenfutter zählen.
- [ ] **4. Separaten `SecureActionButtonTemplate`-Button erstellen:** Linksklick löst das vorbereitete Füttern über die Clientmechanik aus; Rechtsklick wählt außerhalb des Kampfes geeignetes Futter. Keine automatischen Zauberaufrufe und keine geschützten Attributänderungen im Klickskript während des Kampfes.
- [ ] **5. Zustände und Einstellungen verbinden:** fehlender/toter Begleiter, nicht gelernte Fähigkeit, kein gewähltes Futter, kein passendes Futter und aufgebrauchter Vorrat ergeben verständliche Hinweise. Verschieben, Ausblenden, Skalieren und Zurücksetzen des sicheren Buttons laufen über denselben geschützten Pfad. Vorschau darf ihn nicht manipulieren.
- [ ] **6. Prüfen und committen:** `lua tests/run.lua`; Spielchecks für echtes Füttern, Futterwechsel, laufenden Drag bei Kampfbeginn, Einstellungswechsel im Kampf und Ausführung nach Kampfende ergänzen. Ergebnis: vollständiger geplanter Hunter-Umfang, echte Clientabnahme weiterhin Voraussetzung.

## Task 5: Installation, Spieltest und erstes Alpha-Paket

**Files – Create:** `tools/package.py`. **Modify:** `README.md`, `THIRD_PARTY.md`, `docs/testing.md`, `docs/media-sources.md`. **Package:** `dist/ForeverUI-0.1.0-alpha.zip`; Versionsangabe in TOC auf denselben Stand setzen.

**Interfaces:** `python3 tools/package.py --output dist` baut genau einen Wurzelordner `ForeverUI/`, nimmt nur deklarierte Addon-Dateien sowie notwendige MIT-/Medienhinweise auf und lässt Repository, Tests, Referenzbilder und lokale Arbeit aus.

- [ ] **1. Lokale Checks ausführen:** `lua tests/run.lua` muss fehlerfrei enden; Lua-Syntax aller ausgelieferten Dateien und TOC-Dateiliste prüfen; `git diff --check` ausführen. Keine eigenen Tests erstellen, die nur die triviale ZIP-Implementierung nachbauen.
- [ ] **2. Spieltest vorbereiten:** geprüften Installationspfad und Client-Interface dokumentieren; ausschließlich den neuen `ForeverUI`-Ordner installieren. Bestehende Addons und ihre Daten bleiben erhalten. Für den isolierten Test kann der Nutzer deren Anzeige im Spiel vorübergehend deaktivieren.
- [ ] **3. Matrix im echten Client prüfen:** Jäger/nicht Jäger; Anmeldung/Reload/Zonenwechsel; lebendes/totes/kein Ziel; vier Reichweiten; fehlende/knappe/ausreichende Munition; Begleiterzustände; Füttern/Futterwechsel; Kampf während Verschieben/Einstellungen; XP-Gewinn/Levelaufstieg/Maximallevel soweit mit verfügbaren Charakteren prüfbar. Zusätzlich wenigstens eine Instanzsituation für Hunter prüfen. Nicht verfügbare Fälle als offen kennzeichnen.
- [ ] **4. Optik gemeinsam abnehmen:** tatsächliche Spielansichten bei verschiedenen UI-Skalierungen und langen deutschen Texten beurteilen. Gold/Petrol-Stil, klare Hierarchie, saubere Rahmen und gute Lesbarkeit müssen im Spiel erkennbar sein; keine Überlappungen oder abgeschnittenen Bedienelemente.
- [ ] **5. Paket bauen und inspizieren:** `python3 tools/package.py --output dist`, anschließend `python3 -m zipfile -l dist/ForeverUI-0.1.0-alpha.zip`. Prüfen: `ForeverUI/ForeverUI.toc`, jede deklarierte Datei, verwendete eigene Medien und Lizenzhinweise sind vorhanden; keine Original-Addon-Dateien oder privaten Daten enthalten.
- [ ] **6. Ergebnis dokumentieren und committen:** Clientversion, tatsächlich geprüfte Fälle und verbleibende Grenzen in `docs/testing.md` festhalten. Ohne bestandenen Spieltest den Stand ausdrücklich Alpha nennen. README mit Installation, `/fui`, Funktionsumfang und offenen Punkten aktualisieren; Prüfung und Paketergebnis committen. Kein automatisches CurseForge-Release einrichten.

## Selbstprüfung dieses Plans

- Umfang: gemeinsame Gestaltung, Hunter, XP, Einstellungen, Lizenzen und Paketabnahme sind Aufgaben zugeordnet.
- Schnittstellen: Task 1 stellt Datenleser, Einstellungen und Widgets bereit; Tasks 2/3 erzeugen ihre eigenen normalisierten Modelle; Task 4 kapselt alle geschützten Änderungen.
- Kritische Fälle aus Review Focus sind entweder Logiktests oder ausdrücklich Clientchecks zugeordnet.
- Nutzerfreigaben für Umfang und Stil liegen vor. Offene Spieltests werden separat dokumentiert.
