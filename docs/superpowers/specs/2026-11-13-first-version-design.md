# Forever UI – erste Umsetzung

Stand: 13. November 2026. Umfang und direkte Umsetzung vom Nutzer bestätigt. Die Stilrichtung der Browservorschau wurde anschließend ebenfalls bestätigt.

## Ziel und getroffene Entscheidungen

Forever UI wird ein eigenständiges, unter MIT veröffentlichtes WoW-Forever-Addon mit Hunter- und XP-Modul. Der Nutzer hat diesen Weg am 13. November gewählt. Beide Module erhalten eine gemeinsame Fantasy-Gestaltung nach der von ihm gezeigten ForeverFishing-Ansicht.

Die erste Version soll im persönlichen Spielbetrieb nutzbar werden. Eine Veröffentlichung auf CurseForge und vollständige Funktionsgleichheit mit allen aktuellen ForeverXPBar-Erweiterungen gehören nicht zur ersten Umsetzung.

## Ausgangslage und Quellen

- Repository: `tom4711/forever-ui`; bisher nur Projekt- und Lizenzdokumentation.
- ForeverHunter ist auf der öffentlichen Projektseite als MIT-Projekt ausgewiesen. Eine Codeübernahme ist bisher nicht erfolgt.
- ForeverXPBar und ForeverFishing sind auf ihren CurseForge-Seiten als All Rights Reserved ausgewiesen. Sie dienen als Funktions- bzw. Designreferenz; ihr Code und ihre eigenen Medien werden nicht übernommen.
- Aktuelle technische Referenz: [Forever-UI-Quellen, Build 1.60.1 (70938)](https://github.com/Gethe/wow-ui-source/tree/bebcb6bf309cf41b41bd74f8ca651e6a105b2676). Vor der Implementierung mit dem tatsächlich laufenden Client abgleichen.
- Das Nutzerbild zeigt eine dunkle Petrolfläche, verzierte Goldrahmen, warme Serifenschrift, plastische Symbolknöpfe und türkisfarbene Bedienelemente. Es bleibt eine Referenz; es wird nicht als Addon-Grafik ausgeliefert.

Projektseiten: [ForeverHunter](https://www.curseforge.com/wow/addons/foreverhunter), [ForeverXPBar](https://www.curseforge.com/wow/addons/foreverxpbar), [ForeverFishing](https://www.curseforge.com/wow/addons/forever-fishing).

## Ansätze und Auswahl

1. Zusätzliches Design-Addon: erhält die Originalfunktionen, hängt aber von fremden Fensterstrukturen und Updates ab.
2. Eigenständiges Forever UI mit gemeinsamer Gestaltung und zwei Modulen: mehr eigene Funktionsarbeit, dafür kontrollierbarer Umfang und klare Lizenzierung. Diesen Ansatz hat der Nutzer gewählt.

Eigene Implementierung ist der Standard. Geeignete Teile von ForeverHunter dürfen nach Prüfung mit vollständigem MIT-Hinweis übernommen werden; dessen enthaltene Bibliotheken werden dadurch nicht automatisch übernommen. Eine solche Entscheidung wird mit Dateinamen und Version in `THIRD_PARTY.md` festgehalten.

## Geplanter Umfang von v0.1

### Gemeinsame Oberfläche

- Dunkler Petrolhintergrund, goldene Zierrahmen, goldene Überschriften, helle gut lesbare Werte und dezente türkisfarbene Interaktion.
- Gemeinsame Komponenten für Rahmen, Symbolknöpfe, Tooltips und Einstellungen. Kein dauerhaftes Leuchten und keine Animation als Voraussetzung für Erkennbarkeit.
- Ein eigener Addon-Ordner `ForeverUI`; Lua-Namensraum über die Addon-Tabelle; eigener Chatbefehl `/fui` und eigene Charaktereinstellungen `ForeverUICharDB`.
- Beide Module unabhängig ein-/ausschaltbar; Hunter nur für Jäger aktiv, XP grundsätzlich für jede Klasse.
- Position und Skalierung getrennt pro Modul speichern; XP-Breite nach Nutzerfeedback zusätzlich unabhängig zwischen 620 und 1600 Pixeln einstellen; verschieben per Alt-Ziehen außerhalb des Kampfes; eine Sperre und ein Zurücksetzen anbieten.
- Deutsch als erste vollständig ausgearbeitete Sprache, Englisch als Fallback. Interne Zustandsnamen bleiben sprachunabhängig.
- Eine Vorschau mit Beispieldaten wird zuerst erstellt und dem Nutzer gezeigt. Die genaue Anordnung, Größe und Ornamentik werden daran festgelegt; der Screenshot legt den Stil, nicht die Abmessungen fest.

### Hunter

- Reichweitenzustände: Nahkampf, tote Zone, Fernkampf, zu weit entfernt. Zustand durch Text und Farbe, nie allein durch Farbe kennzeichnen.
- Zusätzlich neutrale Zustände für kein geeignetes Ziel und nicht auswertbare Reichweite. Fehlende oder geschützte Werte dürfen nicht als sicher bekannte Entfernung erscheinen.
- Munitionssymbol und Schusszahl. Warnschwelle als Vorschlag 200, mit 0 abschaltbar; Warnung beim Unterschreiten bzw. einmal nach Anmeldung unterhalb der Schwelle. Nach Auffüllen darf sie erneut auslösen.
- Begleiterstimmung mit Symbol und verständlichem Tooltip; fehlender oder toter Begleiter wird ausdrücklich dargestellt.
- Fütterbutton: Linksklick verwendet das gewählte Futter, Rechtsklick wählt geeignetes Futter aus den Taschen. Anzahl und fehlendes Futter sichtbar machen. Erst verfügbar, sobald Füttern gelernt wurde.
- Geschützte Aktionen ausschließlich über einen sicheren WoW-Button und einen echten Spielerklick. Futterwechsel sowie Position, Sichtbarkeit und Skalierung des sicheren Buttons werden im Kampf nicht verändert; Einstellungsänderungen werden bis Kampfende vorgemerkt.

### XP

- Aktuelles Level, XP-Fortschritt als Wert und Prozent, fehlende XP sowie gedeckelte Erholungsbonus-Markierung.
- In der laufenden Sitzung verdiente XP, Sitzungsdauer, XP pro Stunde und geschätzte Zeit bis zum nächsten Level.
- Sitzungsstatistik über `/reload` erhalten; bei neuer Anmeldung oder Charakterwechsel eine neue Sitzung beginnen. Zeitbasis muss einen UI-Neuladevorgang überstehen.
- Levelaufstieg ohne negativen XP-Zuwachs behandeln. Bei mehrstufigen Sprüngen oder fehlenden verlässlichen Daten keine erfundenen Gewinne oder Zeiten anzeigen; Messung mit klar erkennbarem neuen Ausgangspunkt fortsetzen.
- Vor dem ersten Gewinn keine irreführende Restzeit. Am Maximallevel klarer Maximallevel-Zustand ohne Division durch null; standardmäßig sichtbar, einzeln ausblendbar.
- Die Blizzard-XP-Leiste bleibt zunächst unangetastet; der Nutzer kann die neue Leiste frei platzieren.

### Bewusst spätere Erweiterungen

Auto-Quest-Funktionen, Level-Rennen, Ranglisten, Erfolge, Minimap-Menüs, Datenbroker, Mehrcharakterprofile, Sounds und Gamepad-Bedienung werden separat priorisiert. Sie sind kein Bestandteil von v0.1. Für die spätere Funktionsgleichheit werden sie nicht als bereits erledigt betrachtet.

## Technische Leitplanken

- Zielclient: WoW Forever; TOC-Interface zunächst `16001`, vor dem Paketbau im laufenden Client prüfen. Retail-/Classic-Unterstützung wird nicht zugesagt.
- Ein Addon-Paket mit zwei Modulen; keine Abhängigkeit von den drei Referenz-Addons und keine gemeinsame Konfiguration mit ihnen.
- Darstellung und Berechnung trennen. WoW-Daten zuerst auf Lesbarkeit prüfen; erst danach vergleichen, rechnen oder formatieren. API-Verfügbarkeit gezielt prüfen.
- Reichweitenprüfungen höchstens alle 0,2 Sekunden bei sichtbarem Hunter-Modul und geeignetem Ziel. Taschenbestände ereignisgesteuert aktualisieren; kein vollständiger Taschenscan pro Bild.
- Fütterbutton als separaten geschützten Frame halten; normale Anzeigen dürfen dessen Kampfsperren nicht erben. Alle Konfigurationswege benutzen dieselbe Warteschlange für geschützte Änderungen.
- Eigene Grafiken bzw. ausdrücklich passende Ressourcen verwenden. Spielinterne Symbole und Schriftarten können über den Client referenziert werden; keine Blizzard-Dateien kopieren oder mitliefern. Die MIT-Lizenz beansprucht keine Rechte an Client-Ressourcen.
- Keine zusätzlichen Laufzeitbibliotheken für v0.1. Ein Lua-Interpreter für Logiktests und Python 3 für Paketbau genügen als Entwicklungswerkzeuge.
- Keine Änderungen an bestehenden Addons, Einstellungen oder SavedVariables. Installation von ForeverUI erst beim ausdrücklich gestarteten Spieltest.

## Aufbau

`ForeverUI/` enthält das installierbare Addon. `Core/` verwaltet Lebenszyklus, sichere Datenzugriffe und Charaktereinstellungen; `UI/` enthält die gemeinsame Gestaltung und Einstellungen; `Modules/Hunter/` und `Modules/XP/` enthalten jeweils Modell, WoW-Anbindung und Ansicht. `tests/` prüft die Berechnungen ohne Spielclient. `tools/` baut ein ZIP mit genau einem Addon-Ordner.

Diese Dateiaufteilung und die Vorgaben für Warnschwelle, Sprachen, Maximallevel-Anzeige und Testwerkzeuge sind Vorschläge des Planerstellers, keine zusätzlichen Nutzervorgaben.

## Abnahme

1. Nutzer beurteilt eine Vorschau beider Module im gewünschten Fantasy-Stil; konkrete Anordnung wird vor der endgültigen Oberfläche bestätigt.
2. Logiktests decken unbekannte Reichweite, Warnschwellen, Futterzustände, XP-Levelübergänge, UI-Neuladen und fehlende Daten ab.
3. Im Client prüfen: Anmeldung, `/reload`, Zonenwechsel, Jäger/nicht Jäger, kein/toter/lebender Begleiter, keine/knappe Munition, mehrere Reichweiten, Füttern und Kampfwechsel, ein XP-Gewinn und Levelaufstieg sowie verschiedene UI-Skalierungen.
4. Keine Lua-Fehler oder blockierten Addon-Aktionen im geprüften Ablauf. Keine funktionierende Reichweiten- oder Fütterlogik nur aus Offline-Tests behaupten; Instanzverhalten gesondert prüfen und dokumentieren.
5. Ein ZIP lässt sich als `Interface/AddOns/ForeverUI/ForeverUI.toc` entpacken und enthält alle notwendigen eigenen Medien und Lizenzhinweise. Ohne bestandenen Spieltest heißt der Stand ausdrücklich Alpha.

## Offene Abstimmung

Der Nutzer hat den vorgeschlagenen v0.1-Umfang bestätigt. Die gezeigte Browservorschau legt Gold-/Petrol-Stil, horizontale Hunter-Anzeige, darunterliegende Symbolknöpfe und die XP-Anzeige fest. Die Darstellung im echten Client muss noch geprüft werden.

## Erweiterung nach dem ersten Spieltest

Der Nutzer hat die Vorschau fertiger, noch nicht abgegebener Quest-XP ausdrücklich ergänzt. Dafür werden aktuelle XP türkis, Quest-XP gold und der Erholungsbonus blau als getrennte, bis zur nächsten Levelgrenze begrenzte Segmente dargestellt. Ungekürzte Mengen stehen numerisch daneben. Die Anzeige wird kompakter und nutzt die zusätzliche Breite; ihre Breite bleibt unabhängig von Höhe und Schriftgröße einstellbar.


## Folgefunktionen nach Alpha 0.1.3

Auf Nutzerwunsch werden Quest- und Erholungswerte unabhängig in XP oder Prozent der nötigen XP für die aktuelle Stufe gezeigt. Auf macOS nennt der Verschiebehinweis Option. Jäger erhalten separate SecureActionButtons für erlernte Aspekte und manuelle Pet-Zauber. Alpha 0.1.4 muss im Spiel auf Zauberwahl, Pet-Ziel, Kampfwechsel und Leistenposition geprüft werden.


Die Folgefunktionen sind als Alpha 0.1.7 umgesetzt; siehe die separate Folgefunktionsspezifikation und den Umsetzungsplan.
