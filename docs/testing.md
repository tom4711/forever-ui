# Prüfung

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
