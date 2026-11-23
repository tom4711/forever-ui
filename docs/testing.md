# Prüfung

## Prüfrunde 0.1.35-alpha

- XP verdienen, die Sitzungswerte ablesen und `/reload` ausführen. XP-Gewinn und Sitzungszeit sollen erhalten bleiben. Bei einer neuen Anmeldung beginnt eine neue Sitzung.
- Mit Jäger oder Hexer einen Begleiter rufen und den Forever-Spielerrahmen wechselweise aktivieren und deaktivieren. Den sichtbaren Blizzard-Begleiterrahmen anklicken und sein Rechtsklickmenü öffnen.
- Die Blizzard-Zauberleiste im Bearbeitungsmodus am Spielerrahmen andocken. Einen Zauber mit aktivierter Forever-Leiste abschließen und die Forever-Leiste abschalten. Der beendete Zauber soll verschwunden bleiben und der nächste Zauber wieder über Blizzard angezeigt werden.
- Eine Flugroute mit Zwischenhalt einmal vollständig fliegen und später vorzeitig landen. Das verkürzte Teilstück soll die gelernte Gesamtdauer nicht verändern.
- Einen unterbrechbaren Gegnerspruch in und außerhalb der Reichweite testen. Der goldene Rand soll nur bei verfügbarer Unterbrechung und bestätigter Reichweite erscheinen.
- Bei gleichzeitig aktiver Wick-Gestaltung die Taschen neu gestalten lassen und den Forever-Taschenstil ausschalten. Das zuletzt gesetzte native Aussehen soll erhalten bleiben.

Die Lua-Suite prüft die nachgestellten Abläufe inklusive fehlgeschlagener Warteschlangeneinträge mit `lua tests/run.lua`. Die obigen Schritte prüfen zusätzlich den echten Client.

## Entwicklungsprüfungen

- Lua-5.1-kompatible Syntax und keine Laufzeitabhängigkeiten von anderen Addons.
- `lua tests/run.lua` prüft gespeicherte Einstellungen und die Normalisierung lesbarer API-Werte.
- `luac -p DATEI.lua` prüft die Syntax einzelner ausgelieferter Dateien.
- Die Browseransicht unter `preview/index.html` dient zur Designabstimmung. Ihre Daten sind Beispiele; sie simuliert nicht die WoW-Engine.

## Stand der Designbasis

- 10 Logiktests bestanden, jeweils zuerst gegen die fehlende Implementierung fehlgeschlagen.
- Lua-Dateien mit Lua 5.1 syntaktisch geprüft.
- Browservorschau visuell geprüft; Einstellungen öffnen/schließen und XP-Anzeige aus-/einblenden geprüft.
- Nutzer hat die Stilrichtung der Vorschau bestätigt.
- Noch kein Test in WoW; Live-Module folgen in den nächsten Schritten.

## Spätere Spielprüfung

Anmeldung, UI-Neuladen, Zonenwechsel, Charakterklassen, vier Reichweiten und unbekannte Werte, Munitionswarnung, Begleiterzustände, Futterwahl, echtes Füttern und Kampfwechsel prüfen. Beim XP-Modul Gewinne, Levelaufstieg, Neuanmeldung, UI-Neuladen und Maximallevel prüfen. Layout bei unterschiedlichen UI-Skalierungen und langen Texten kontrollieren.

## Hunter-Anbindung

18 Offline-Tests bestehen, einschließlich unbekannter Reichweite, leerem versus unzugänglichem Munitionsplatz, wiederholter Warnungen und Begleiterzuständen. Die API-Anbindung und tatsächlichen Entfernungsgrenzen sind vor einer Freigabe im Client zu prüfen. Keine fremden Module wurden übernommen.

## Fütterfunktion

28 Offline-Tests bestehen. Hinzugekommen sind Kampfsperre/erneuter Kampfbeginn, Ersetzen vorgemerkter Einstellungen, Futterstapel, nicht geladene Gegenstandsnamen und gesicherte Futterwahl. Der geschützte Button wird ohne Verankerung an den verschiebbaren Normalframe positioniert. Die WoW-Sicherheitsmechanik und echtes Füttern sind damit nicht offline bestätigt; diese Spieltests bleiben offen.

## XP-Modul

40 Offline-Tests bestehen, darunter ein Levelübergang mit exakt 20 XP Gewinn, unveränderte Folgemeldungen, Erholungsdeckelung, mehrstufige Sprünge, Maximallevel sowie getrennte Behandlung von Reload und neuer Anmeldung. Ein vorübergehender Verlust lesbarer Daten führt zu einer gekennzeichneten neuen Messung. Das Zusammenspiel echter XP-/Level-Ereignisse ist noch im Client zu prüfen.

## Paketprüfung

Das Alpha-ZIP enthält 22 deklarierte Dateien unter genau einem `ForeverUI/`-Wurzelordner. TOC und Laufzeitdateien wurden auf Vollständigkeit geprüft. Referenzbilder, Browservorschau, Tests, Arbeitsdateien und Blizzard-Mediendateien werden nicht ausgeliefert. Der vollständige Spieltest ist noch offen; es wird ausdrücklich kein stabiler Release zugesagt.

## Erste Prüfung im Spiel und Folgekorrekturen

Vom Nutzer im Spiel bestätigt: Addon startet, beide Anzeigen und Einstellungen sind sichtbar, Füttern funktioniert, geeignetes Futter lässt sich auswählen, und der Reichweitenzustand „zu weit“ passt im geprüften Fall. Die grundsätzliche Gestaltung ist bestätigt.

Das anschließende Feedback führte zu schlichten kleinen Settings-Controls und einer unabhängig von der Skalierung gespeicherten XP-Breite (620–1600 Pixel). Die unabhängige Codeprüfung führte zu ausdrücklichen Fütterzuständen und Bildschirmbegrenzung des vollständigen Hunter-Bereichs.

48 Logiktests bestehen. Die neue Anordnung, die Breitenbedienung und das Verhalten direkt am Bildschirmrand müssen nach dem Aktualisieren noch im Client bestätigt werden. Kampfwechsel, Instanzreichweiten, XP-Ereignisse beim echten Levelaufstieg, neue Anmeldung versus Reload und nicht verfügbare Charakterklassen/Maximallevel sind weiterhin offene Abnahmefälle. Eine vollständige Client-Build-ID ist noch nicht protokolliert.

Die Alpha 0.1.1 wurde nach der Korrektur aktualisiert. Die beiden wichtigen Reviewbefunde sind behoben und durch Regressionstests abgesichert. Der im Umfang vorgesehene Begleiter-Tooltip wurde ergänzt. Für die kleinen Controls wird die vorhandene Client-Checkbox-Textur statt eines möglicherweise fehlenden Häkchen-Schriftzeichens verwendet.

## Schließen-Schaltfläche

In Alpha 0.1.2 wurde die rote Fläche mit kleinem Schriftzeichen durch ein gleichmäßig gezeichnetes goldenes Kreuz auf demselben Petrol-/Gold-Control wie die übrigen Settings-Buttons ersetzt. Es gibt einen lokalisierten Schließen-Tooltip. Die verwendeten Line-Anker wurden mit der Forever-API-Dokumentation abgeglichen; die endgültige optische Beurteilung erfolgt nach dem UI-Neuladen im Spiel.

## XP-Segmente und kompaktere Anzeige (Alpha 0.1.3)

Auf ausdrücklichen Nutzerwunsch ergänzt: fertige Quest-XP zusätzlich zur aktuellen Erfahrung und dem Erholungsbonus. Die Farbbereiche überlappen nicht mehr; Questbelohnungen nutzen vor dem Erholungsbonus den noch freien Vorschauplatz bis zur nächsten Stufe. Vollständige Werte bleiben numerisch sichtbar. Eine unbekannte Questbelohnung wird nicht als null ausgegeben; die Quest-Auswahl wird nicht verändert.

Das Layout nutzt den Balken über fast die volle Breite, die XP-Zahlen im Kopfbereich und eine gemeinsame Statistikzeile. Höhe 132 statt 145 UI-Einheiten, Balkenhöhe 23 statt 16. Breite und Skalierung bleiben getrennt. Die reale Farbzuordnung und Questbelohnungen müssen nach dem Neuladen im Client geprüft werden.

59 Logiktests bestehen, einschließlich disjunkter Segmente, Begrenzung, Quest-ID statt Logindex, doppelter/fehlender Daten und bereits abgegebener Quests. Es wird keine zusätzliche Laufzeitdatei benötigt; die Erweiterung liegt in den vorhandenen XP-Modell-/Controller-Dateien und kann per `/reload` geladen werden.


## XP-Einheiten und Hunter-Klickaktionen (Alpha 0.1.8)

72 Offline-Tests bestehen. Hinzugekommen sind unabhängige SavedVariables-Auswahl für Quest- und Ruhebonus in XP/Prozent sowie Hunter-Modelltests für höchste erlernte Aspektränge und Pet-Zustände. Sichere Klickbuttons für Aspekte, Mend Pet und Revive Pet werden außerhalb des Kampfes konfiguriert. Der neue Aspektbereich hat eine eigene Zeile oberhalb der Futter- und Werkzeugbuttons. Das tatsächliche Zauberwirken, Zielverhalten und Layout im Forever-Client müssen im Spiel bestätigt werden.

Die Abschlussprüfung hat die Pet-Button-Slots über wiederholte Aktualisierungen, die Hunter-Skalierung und den Abstand zum Futterbutton durch zusätzliche Offline-Tests abgesichert.

Der XP-Controller initialisiert die normale XP-Leiste sofort aus einem lesbaren Snapshot; ein Test deckt den Fall ab, dass das Welt-Ereignis später eintrifft.

Ein Startfehler durch das Forever-unbekannte `LEARNED_SPELL_IN_TAB` wurde durch die gültige Forever-Eventvariante `LEARNED_SPELL_IN_SKILL_LINE` ersetzt. Der Regressionstest prüft die registrierten Spell-Events.

## Hunter-Buttonreihe (Alpha 0.1.9)

Die gelernten Aspekte und verfügbaren Pet-Aktionen sowie Füttern, Futterwahl und Einstellungen stehen jetzt in einer gemeinsamen Reihe unter dem Hunter-Statusfeld. Die Aktionen behalten ihre Reihenfolge; die nachfolgenden Werkzeuge rücken abhängig von der Zahl erlernter Aktionen mit. Die Offline-Tests decken fünf und acht Aktionen ab. 74 Tests bestehen; Lua-5.1-Syntax und Paketinhalt wurden geprüft. Die tatsächliche Anordnung und Abstände sind nach `/reload` noch im Forever-Client zu bestätigen.

## Getrennte Hunter-Aktionsgruppen (Alpha 0.1.10)

Aspekte haben eine eigene Box; die Pet-Box enthält Mend Pet, Revive Pet, Füttern und Futterwahl. Die Einstellungen-Schaltfläche bleibt separat. Beide Boxen lassen sich unabhängig über Settings ein-/ausblenden und bei entsperrten Positionen per Alt/Option ziehen; ihre Offsets bleiben relativ zum Hunter-Control gespeichert. Ein aktiver Aspekt erhält eine türkise Kontur, ein nicht lesbarer Aura-Status einen gedämpften Hinweisrahmen.

88 Offline-Tests bestehen, darunter unabhängige Gruppenpositionen, Sichtbarkeitseinstellungen, nicht verfügbare Aura-Daten, die Abfrage aller erlernten Aspektränge und root-relative Drag-Koordinaten. Revive Pet nutzt nun den direkten sicheren Spell-Klick per ID 982 statt eines Makros mit Pet-Zielbedingung. Drag-Ende wird bei Kampfbeginn bis nach Kampfende aufgeschoben. Lua-5.1-Syntax und Paketinhalt sind geprüft; der installierte Ordner stimmt mit dem Paket überein. Im Forever-Client müssen Wiederbeleben, 100-%-Abstände, Draggen der Gruppen, Settings-Schalter, aktive Aspektmarkierung sowie Füttern und Zauberklicks bestätigt werden.

## Flugzeit in der XP-Leiste (Alpha 0.1.11)

Die XP-Leiste ergänzt während des Flugs eine türkise Fortschrittslinie und die vergangene Zeit. Ist eine gelernte oder aus ForeverXPBar einmalig importierte Route verfügbar, erscheint zusätzlich deren Gesamtdauer; sonst schätzt ForeverUI die Route aus den Taxikarten-Knoten und kennzeichnet die Schätzung. Ohne lesbare Routengeometrie bleibt nur die verstrichene Zeit. Die XP-Leiste wächst während dieser Anzeige um 26 UI-Einheiten und kehrt nach der Landung auf ihre vorherige Höhe zurück. Der zusätzliche Abstand hält den Flugzeittext sichtbar von der unteren Rahmenkante fern.

Die erste Schätzung ist grob; abgeschlossene, von ForeverUI beobachtete Flüge kalibrieren die Routendauer. Offline-Tests decken Modellgrenzen, Import, Taxiübergänge, partielle Flüge, Zeittext und Fortschrittsbreite ab. Im Forever-Client sind eine neue und eine bekannte Route, Anzeige ohne ForeverXPBar, Verbergen nach der Landung sowie unveränderte XP-/Sitzungswerte zu prüfen.

## Paladin- und Hexer-Controls (Alpha 0.1.12)

Klassenanzeigen erscheinen nur auf der passenden Klasse und lassen sich pro Charakter in den Settings ausblenden. Paladine erhalten manuelle Buttons für gelernte Auren und Segen sowie eine aktive-Aura-Markierung. Der Ausrüstungsbutton erscheint nur mit zwei aktuellen Equipment-Sets und wechselt sie per Klick anhand des Schildstatus. Hexer sehen Dämonenstatus, Seelensplitter und gelernte Beschwörungen. Die Vorschau nutzt Beispieldaten und reine Anzeige-Buttons.

112 Offline-Tests decken Klassenfilter, Set-Normalisierung und Makros, Aura- und Dämonenzustände, CombatQueue, `C_Item`-Fallbacks, Live-/Vorschau-Buttonmodi und das Layout ab. Im Client bleiben Zauberklicks, der Equipment-Wechsel inklusive Kampfverhalten und die Darstellung bei vielen gelernten Zaubern zu prüfen.
