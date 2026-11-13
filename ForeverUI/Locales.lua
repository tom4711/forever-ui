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
    MOVE_HINT="Hold Alt and drag to move unlocked panels.", MOVE_HINT_MAC="Hold Option (⌥) and drag to move unlocked panels.", SOON="Example values; this preview does not trigger game actions.",
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
    MOVE_HINT="Zum Verschieben entsperren und mit Alt ziehen.", MOVE_HINT_MAC="Zum Verschieben entsperren und mit Option (⌥) ziehen.",
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
en.FEED_STATE_unlearned="Learn Feed Pet first.";en.FEED_STATE_missing="Call your pet first.";en.FEED_STATE_dead="Revive your pet before feeding it."
en.FEED_STATE_unselected="Right-click to select food.";en.FEED_STATE_loading="Food data is loading; try again shortly."
en.FEED_STATE_empty="The selected food is used up. Right-click to choose another.";en.FEED_STATE_unsuitable="Your current pet cannot eat this food. Right-click to choose another."
en.FEED_STATE_unknown="Feeding readiness cannot be evaluated right now. Try again after combat."
de.FEED_STATE_unlearned="Erlerne zuerst Begleiter füttern.";de.FEED_STATE_missing="Rufe zuerst deinen Begleiter.";de.FEED_STATE_dead="Belebe deinen Begleiter vor dem Füttern wieder."
de.FEED_STATE_unselected="Wähle per Rechtsklick geeignetes Futter.";de.FEED_STATE_loading="Die Futterdaten werden geladen. Versuche es gleich noch einmal."
de.FEED_STATE_empty="Das gewählte Futter ist aufgebraucht. Wähle per Rechtsklick anderes Futter.";de.FEED_STATE_unsuitable="Dein aktueller Begleiter frisst dieses Futter nicht. Wähle per Rechtsklick anderes Futter."
de.FEED_STATE_unknown="Ob Füttern möglich ist, kann gerade nicht geprüft werden. Versuche es nach dem Kampf erneut."
en.XP_WIDTH="XP bar · width";de.XP_WIDTH="XP-Leiste · Breite"
en.PET_HINT_missing="Call your pet to see its mood.";en.PET_HINT_dead="Revive your pet.";en.PET_HINT_unknown="Pet mood cannot be evaluated right now."
en.PET_HINT_unhappy="Your pet is unhappy. Suitable food improves its mood.";en.PET_HINT_content="Your pet is content. Suitable food can improve its mood.";en.PET_HINT_happy="Your pet is happy."
de.PET_HINT_missing="Rufe deinen Begleiter, um seine Stimmung zu sehen.";de.PET_HINT_dead="Belebe deinen Begleiter wieder.";de.PET_HINT_unknown="Die Stimmung kann gerade nicht ausgelesen werden."
de.PET_HINT_unhappy="Dein Begleiter ist unglücklich. Geeignetes Futter verbessert seine Stimmung.";de.PET_HINT_content="Dein Begleiter ist zufrieden. Geeignetes Futter kann seine Stimmung verbessern.";de.PET_HINT_happy="Dein Begleiter ist glücklich."
en.CLOSE="Close";de.CLOSE="Schließen"
en.QUEST_XP="Completed quests";de.QUEST_XP="Fertige Quests"
en.CURRENT_XP="Current XP";de.CURRENT_XP="Aktuelle XP"
en.GAIN_SHORT="Earned";de.GAIN_SHORT="Gewinn"
en.GAIN_RESET="Since reset";de.GAIN_RESET="Seit Neustart"
en.QUEST_PREVIEW_HINT="Gold shows unclaimed XP from completed quests; blue shows rested bonus. Segments stop at the next level boundary."
de.QUEST_PREVIEW_HINT="Gold zeigt offene XP aus erledigten Quests, Blau den Erholungsbonus. Die Segmente enden an der nächsten Levelgrenze."
ns.L=setmetatable(GetLocale() == "deDE" and de or {}, {__index=en})

en.QUEST_DISPLAY="Quest XP display";de.QUEST_DISPLAY="Quest-XP anzeigen als"
en.RESTED_DISPLAY="Rested XP display";de.RESTED_DISPLAY="Erholungsbonus anzeigen als"
en.DISPLAY_XP="XP";de.DISPLAY_XP="XP"
en.DISPLAY_PERCENT="Percent";de.DISPLAY_PERCENT="Prozent"
en.XP_PERCENT_HINT="Percent of the XP required for this level.";de.XP_PERCENT_HINT="Prozent der benötigten XP für diese Stufe."
