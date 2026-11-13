local _, ns = ...
local en = {
    TITLE="Forever UI", HUNTER="Hunter", EXPERIENCE="Experience", PREVIEW="Example values",
    RANGED="Ranged", RANGE_HINT="Your target is within shooting range", AMMO="Ammunition",
    PET="Companion", HAPPY="Happy", FEED="Feed pet", FOOD="Choose food", OPTIONS="Settings",
    LEVEL="Level 32", NEXT_LEVEL="Next level", RESTED="Rested", SESSION="Session",
    XP_HOUR="XP per hour", TIME_LEFT="Time to level", REMAINING="XP remaining",
    ENABLE_HUNTER="Show hunter module", ENABLE_XP="Show experience module",
    LOCK="Lock positions", SCALE="Scale", AMMO_WARNING="Warn below this ammunition count",
    PREVIEW_SHOW="Show preview", PREVIEW_HIDE="Close preview", RESET="Reset positions",
    MOVE_HINT="Hold Alt and drag to move unlocked panels.", SOON="Example values; this preview does not trigger game actions.",
    COMBAT="Wait until combat ends before changing the preview or its layout.",
    READY="Loaded. Use /fui for settings or /fui preview for the design preview.",
    INVALID_AMMO="Enter an ammunition threshold from 0 to 100000; 0 disables the warning.",
    PREVIEW_HINT="Example values; not live game data", NOT_LIVE="Not connected to game data yet",
}
local de = {
    HUNTER="Jäger", EXPERIENCE="Erfahrung", PREVIEW="Beispieldaten",
    RANGED="Fernkampf", RANGE_HINT="Dein Ziel ist in Schussreichweite", AMMO="Munition",
    PET="Begleiter", HAPPY="Glücklich", FEED="Begleiter füttern", FOOD="Futter wählen", OPTIONS="Einstellungen",
    LEVEL="Stufe 32", NEXT_LEVEL="Nächste Stufe", RESTED="Erholt", SESSION="Sitzung",
    XP_HOUR="XP pro Stunde", TIME_LEFT="Zeit bis zum Aufstieg", REMAINING="Fehlende XP",
    ENABLE_HUNTER="Jäger-Anzeige einblenden", ENABLE_XP="XP-Leiste einblenden", LOCK="Positionen sperren",
    SCALE="Skalierung", AMMO_WARNING="Warnung unter dieser Munitionsmenge", PREVIEW_SHOW="Vorschau anzeigen",
    PREVIEW_HIDE="Vorschau schließen", RESET="Positionen zurücksetzen",
    MOVE_HINT="Zum Verschieben entsperren und mit Alt ziehen.",
    SOON="Beispieldaten; diese Vorschau löst keine Spielaktionen aus.",
    COMBAT="Warte bis nach dem Kampf, um Vorschau oder Anordnung zu ändern.",
    READY="Geladen. /fui öffnet die Einstellungen; /fui preview zeigt die Designvorschau.",
    INVALID_AMMO="Gib eine Munitionsgrenze von 0 bis 100000 ein; 0 schaltet die Warnung aus.",
    PREVIEW_HINT="Beispieldaten; keine Live-Spielwerte", NOT_LIVE="Noch nicht mit Spielwerten verbunden",
}
en.RANGE_LABEL="Range"
en.ZONE_none="No target";en.ZONE_unknown="Unknown";en.ZONE_ranged="Ranged";en.ZONE_melee="Melee";en.ZONE_deadzone="Dead zone";en.ZONE_far="Too far"
en.HINT_none="Select a living hostile target";en.HINT_unknown="Range cannot be evaluated";en.HINT_ranged="Your target is within shooting range";en.HINT_melee="Your target is within melee range";en.HINT_deadzone="Too close to shoot, too far to strike";en.HINT_far="Move closer to your target"
en.PET_missing="No pet";en.PET_dead="Dead";en.PET_unknown="Unknown";en.PET_unhappy="Unhappy";en.PET_content="Content";en.PET_happy="Happy";en.AMMO_LOW="Low ammunition: %s shots left."
de.RANGE_LABEL="Reichweite"
de.ZONE_none="Kein Ziel";de.ZONE_unknown="Unbekannt";de.ZONE_ranged="Fernkampf";de.ZONE_melee="Nahkampf";de.ZONE_deadzone="Tote Zone";de.ZONE_far="Zu weit"
de.HINT_none="Wähle ein lebendes gegnerisches Ziel";de.HINT_unknown="Reichweite ist nicht auswertbar";de.HINT_ranged="Dein Ziel ist in Schussreichweite";de.HINT_melee="Dein Ziel ist in Nahkampfreichweite";de.HINT_deadzone="Zu nah zum Schießen, zu weit zum Zuschlagen";de.HINT_far="Nähere dich deinem Ziel"
de.PET_missing="Kein Tier";de.PET_dead="Tot";de.PET_unknown="Unbekannt";de.PET_unhappy="Unglücklich";de.PET_content="Zufrieden";de.PET_happy="Glücklich";de.AMMO_LOW="Wenig Munition: noch %s Schuss."
en.FOOD_EMPTY="The selected food is used up. Right-click to choose another."
en.SELECT_FOOD="Right-click to select pet food.";en.NO_FOOD="No suitable food in your bags";en.ITEM_LOADING="Loading item…";en.FEED_HINT="Left click: feed · Right click: choose food";en.MENU_UNAVAILABLE="Food selection is unavailable on this client."
de.FOOD_EMPTY="Das gewählte Futter ist aufgebraucht. Wähle per Rechtsklick anderes Futter."
de.SELECT_FOOD="Wähle per Rechtsklick Futter für deinen Begleiter.";de.NO_FOOD="Kein geeignetes Futter in den Taschen";de.ITEM_LOADING="Gegenstand wird geladen…";de.FEED_HINT="Linksklick: füttern · Rechtsklick: Futter wählen";de.MENU_UNAVAILABLE="Die Futterauswahl ist in diesem Client nicht verfügbar."
en.LEVEL_PREFIX="Level";en.MAX_LEVEL="Maximum level";en.MAX_LEVEL_HINT="Maximum level reached";en.SESSION_XP="Session XP"
en.RESET_MEASUREMENT="Measurement restarted after missing data; unobserved gains were not estimated.";en.RESET_SHORT="New measurement"
de.LEVEL_PREFIX="Stufe";de.MAX_LEVEL="Maximallevel";de.MAX_LEVEL_HINT="Maximallevel erreicht";de.SESSION_XP="XP dieser Sitzung"
de.RESET_MEASUREMENT="Messung nach einer Datenlücke neu begonnen; fehlende Gewinne wurden nicht geschätzt.";de.RESET_SHORT="Messung neu begonnen"
en.SHOW_AT_CAP="Show XP panel at maximum level"
de.SHOW_AT_CAP="XP-Anzeige am Maximallevel zeigen"
en.ALPHA_NOTE="Alpha version · Please verify behavior in game."
de.ALPHA_NOTE="Alpha-Version · Bitte Verhalten im Spiel prüfen."
ns.L=setmetatable(GetLocale() == "deDE" and de or {}, {__index=en})
