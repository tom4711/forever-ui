# Forever UI Folgefunktionen: XP-Anzeige und Jäger-Klickflächen

## Ziel

Die XP-Anzeige soll das störende Fragezeichen-Icon verlieren und Quest- sowie Ruhebonus wahlweise verständlicher als Erfahrungspunkte oder Prozent anzeigen. Jäger sollen Aspekte und die beiden Pet-Zauber direkt in Forever UI klicken können, ohne dafür Aktionsleistenplätze bereitzustellen.

## Bestätigte Wünsche

- Getrennte Auswahl in den Settings: Quest-XP und Erholungsbonus können unabhängig als absolute XP oder Prozent angezeigt werden.
- macOS-Hinweise nennen Option; andere Plattformen nennen Alt.
- Jägeraspekte und Pet-Aktionen erhalten eigene Schaltflächen.
- Manuelle Klicks lösen die jeweilige Aktion aus. Keine automatische Aspektwahl, Heilung oder Wiederbelebung.

## Anzeige

XP-/Prozent-Auswahl gilt nur für die beiden Textwerte. Die drei Balkensegmente und XP-Berechnungen bleiben unverändert. Prozent zeigt jeweils den Anteil der gesamten Questbelohnung beziehungsweise des Ruhebonus an den für die aktuelle Stufe benötigten XP; die Anzeige kann dadurch über 100 % liegen. Absolute XP bleibt Standard für bestehende Einstellungen. Ein Wechsel der Anzeige wirkt sich nicht auf Sitzung, Queststatus oder gespeicherte XP aus.

Das Fragezeichen wird durch eine klare, zur Gold-Petrol-Oberfläche passende XP-Kennzeichnung ersetzt. Das Draggen verwendet weiterhin dieselbe plattformübergreifende WoW-Alt-Taste; nur der sichtbare Hilfetext wechselt zwischen Alt und Option.

## Jäger-Steuerung

Jede erlernte Aspekt erhält eine eigene SecureActionButton mit direkter Spell-ID und WoW-Highlight. Zusätzlich gibt es feste Schaltflächen für Mend Pet und Revive Pet. Sichere Makroaktionen beschränken Mend Pet auf einen lebenden Begleiter und Revive Pet auf einen toten Begleiter. Die Aktionen beginnen ausschließlich durch einen echten Klick. Die Schaltflächen werden vor dem Kampf konfiguriert und bleiben während des Kampfes stabil; Aktualisierungen warten bis zum Kampfende. Sie werden nicht dynamisch im Kampf versteckt oder umkonfiguriert.

Die Funktion gilt nur für Jäger und erlernte Zauber. Nicht verfügbare Zauber werden nach Spellbook-/Spell-Änderungsereignissen außerhalb des Kampfes ergänzt. Futterwahl und Fütterung behalten ihre bestehende Bedienung.

## Umsetzungsansätze

1. Einzelne vorbereitete SecureActionButtons für jeden Aspekt und die beiden Begleiterzauber (bestätigt): sofortige direkte Klicks und unverändertes Kampfverhalten; benötigt Platz auf der Hunter-Leiste.
2. Ausklappmenü mit Aktionen: spart Platz, macht Aktionen aber weniger direkt und erschwert sichere Klickbedienung im Kampf.
3. Aspekt-Rad oder automatischer Wechsel: passt nicht zur ausdrücklich manuellen Bedienung und wird verworfen.

## Grenzen und offene Client-Prüfungen

Die Forever-Client-Spell-IDs, erlernten Zauber, Zielverhalten von Mend/Revive Pet, Reihenfolge und Platzbedarf der Aspect-Schaltflächen sowie UI-Interaktion im Kampf müssen im Spiel geprüft werden. Kein Addon darf Zauber ohne Klick autonom wirken oder geschützte Aktionsattribute im Kampf umschalten.
