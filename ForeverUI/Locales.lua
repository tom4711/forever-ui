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
    MOVE_HINT="Hold Alt and drag to move unlocked panels.", SOON="This is a design preview. Live functionality follows after design review.",
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
    SOON="Dies ist die Designvorschau. Die Spielfunktionen folgen nach der Designabstimmung.",
    COMBAT="Warte bis nach dem Kampf, um Vorschau oder Anordnung zu ändern.",
    READY="Geladen. /fui öffnet die Einstellungen; /fui preview zeigt die Designvorschau.",
    INVALID_AMMO="Gib eine Munitionsgrenze von 0 bis 100000 ein; 0 schaltet die Warnung aus.",
    PREVIEW_HINT="Beispieldaten; keine Live-Spielwerte", NOT_LIVE="Noch nicht mit Spielwerten verbunden",
}
ns.L=setmetatable(GetLocale() == "deDE" and de or {}, {__index=en})
