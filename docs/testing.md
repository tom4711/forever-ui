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
