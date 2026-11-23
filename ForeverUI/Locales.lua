local _, ns = ...
local en = {
    TITLE="Forever UI", HUNTER="Hunter", PRIEST="Priest", EXPERIENCE="Experience", TAB_GENERAL="General", TAB_CLASSES="Classes", HUNTER_SECTION="Hunter", PALADIN_SECTION="Paladin", WARLOCK_SECTION="Warlock", PRIEST_SECTION="Priest", PALADIN_SCALE="Paladin scale", WARLOCK_SCALE="Warlock scale", ENABLE_PRIEST="Show Priest module", PRIEST_GROUPS="Priest action groups", SHOW_PRIEST_BUFFS="Show buffs and form", SHOW_PRIEST_SUPPORT="Show support actions", BUFFS_FORM="Buffs & Form", SUPPORT="Support", HEALTH="Health", MANA="Mana", SHADOWFORM_ACTIVE="Shadowform active", SHADOWFORM_INACTIVE="Shadowform inactive", SHADOWFORM_UNAVAILABLE="Shadowform not learned", STATUS_UNKNOWN="Status unavailable", PRIEST_CLICK_HINT="Click to cast on your current target.", POWER_WORD_FORTITUDE="Power Word: Fortitude", INNER_FIRE="Inner Fire", SHADOWFORM="Shadowform", POWER_WORD_SHIELD="Power Word: Shield", RENEW="Renew", DISPEL_MAGIC="Dispel Magic", CURE_DISEASE="Cure Disease", RESURRECTION="Resurrection", CLASS_CONTROLS="Class controls", ENABLE_PALADIN="Show Paladin module", ENABLE_WARLOCK="Show Warlock module", SHIELD_SET="Shield equipment set", TWO_HAND_SET="Two-handed equipment set", SET_NONE="Not selected", SET_UNAVAILABLE="Unavailable", SET_EMPTY="No equipment sets found", SET_MENU_UNAVAILABLE="Equipment set selection is unavailable on this client", PREVIEW="Example values", ASPECTS="Aspects", HUNTER_GROUPS="Hunter bars",
    RANGED="Ranged", RANGE_HINT="Your target is within shooting range", AMMO="Ammunition",
    PET="Companion", HAPPY="Happy", FEED="Feed pet", FOOD="Choose food", OPTIONS="Settings",
    LEVEL="Level 32", NEXT_LEVEL="Next level", RESTED="Rested", SESSION="Session",
    XP_HOUR="XP per hour", TIME_LEFT="Time to level", REMAINING="XP remaining",
    ENABLE_HUNTER="Show hunter module", ENABLE_XP="Show experience module",
    SHOW_ASPECTS="Show aspect bar", SHOW_PET_ACTIONS="Show pet actions",
    MOVE_GROUP="Move this group", MOVE_GROUP_HINT="Unlock positions, then hold Alt and drag.",
    LOCK="Lock positions", SCALE="Scale", AMMO_WARNING="Warn below this ammunition count",
    PREVIEW_SHOW="Show preview", PREVIEW_HIDE="Close preview", RESET="Reset positions",
    MOVE_HINT="Hold Alt and drag to move unlocked panels.", MOVE_HINT_MAC="Hold Option (⌥) and drag to move unlocked panels.", SOON="Example values; this preview does not trigger game actions.",
    COMBAT="Wait until combat ends before changing the preview or its layout.",
    READY="Loaded. Use /fui for settings or /fui preview for the design preview.",
    INVALID_AMMO="Enter an ammunition threshold from 0 to 100000; 0 disables the warning.",
    PREVIEW_HINT="Example values; not live game data", NOT_LIVE="Not connected to game data yet",
}
local de = {
    HUNTER="Jäger", PRIEST="Priester", EXPERIENCE="Erfahrung", TAB_GENERAL="Allgemein", TAB_CLASSES="Klassen", HUNTER_SECTION="Jäger", PALADIN_SECTION="Paladin", WARLOCK_SECTION="Hexer", PRIEST_SECTION="Priester", PALADIN_SCALE="Paladin-Skalierung", WARLOCK_SCALE="Hexer-Skalierung", ENABLE_PRIEST="Priester-Anzeige einblenden", PRIEST_GROUPS="Priester-Aktionsgruppen", SHOW_PRIEST_BUFFS="Stärkungen und Gestalt einblenden", SHOW_PRIEST_SUPPORT="Unterstützungsaktionen einblenden", BUFFS_FORM="Stärkungen & Gestalt", SUPPORT="Unterstützung", HEALTH="Gesundheit", MANA="Mana", SHADOWFORM_ACTIVE="Schattenform aktiv", SHADOWFORM_INACTIVE="Schattenform nicht aktiv", SHADOWFORM_UNAVAILABLE="Schattenform nicht erlernt", STATUS_UNKNOWN="Status unbekannt", PRIEST_CLICK_HINT="Klicken, um auf dein aktuelles Ziel zu wirken.", POWER_WORD_FORTITUDE="Machtwort: Seelenstärke", INNER_FIRE="Inneres Feuer", SHADOWFORM="Schattenform", POWER_WORD_SHIELD="Machtwort: Schild", RENEW="Erneuerung", DISPEL_MAGIC="Magie bannen", CURE_DISEASE="Krankheit heilen", RESURRECTION="Wiederbelebung", CLASS_CONTROLS="Klassenanzeigen", ENABLE_PALADIN="Paladin-Anzeige einblenden", ENABLE_WARLOCK="Hexer-Anzeige einblenden", SHIELD_SET="Schild-Set", TWO_HAND_SET="Zweihand-Set", SET_NONE="Nicht ausgewählt", SET_UNAVAILABLE="Nicht verfügbar", SET_EMPTY="Keine Ausrüstungssets gefunden", SET_MENU_UNAVAILABLE="Set-Auswahl ist in diesem Client nicht verfügbar", PREVIEW="Beispieldaten", ASPECTS="Aspekte", HUNTER_GROUPS="Jäger-Leisten",
    RANGED="Fernkampf", RANGE_HINT="Dein Ziel ist in Schussreichweite", AMMO="Munition",
    PET="Begleiter", HAPPY="Glücklich", FEED="Begleiter füttern", FOOD="Futter wählen", OPTIONS="Einstellungen",
    LEVEL="Stufe 32", NEXT_LEVEL="Nächste Stufe", RESTED="Erholt", SESSION="Sitzung",
    XP_HOUR="XP pro Stunde", TIME_LEFT="Zeit bis zum Aufstieg", REMAINING="Fehlende XP",
    ENABLE_HUNTER="Jäger-Anzeige einblenden", ENABLE_XP="XP-Leiste einblenden", LOCK="Positionen sperren",
    SHOW_ASPECTS="Aspekt-Leiste einblenden", SHOW_PET_ACTIONS="Begleiter-Aktionen einblenden",
    MOVE_GROUP="Gruppe verschieben", MOVE_GROUP_HINT="Positionen entsperren, dann mit Alt/Option ziehen.",
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
en.FLIGHT_TIME="Flight";de.FLIGHT_TIME="Flugzeit"

en.PET_ACTION_READY="Click to cast on your pet.";de.PET_ACTION_READY="Klicken, um den Zauber auf deinen Begleiter zu wirken."
en.PET_ACTION_UNAVAILABLE="Your pet's current state may prevent this spell.";de.PET_ACTION_UNAVAILABLE="Der Zustand deines Begleiters kann diesen Zauber verhindern."
en.PET_ACTION_MANUAL="This action is only cast when clicked.";de.PET_ACTION_MANUAL="Der Zauber wird nur durch einen Klick gewirkt."
en.ASPECT_monkey="Aspect of the Monkey";de.ASPECT_monkey="Aspekt des Affen"
en.ASPECT_hawk="Aspect of the Hawk";de.ASPECT_hawk="Aspekt des Falken"
en.ASPECT_cheetah="Aspect of the Cheetah";de.ASPECT_cheetah="Aspekt des Geparden"
en.ASPECT_pack="Aspect of the Pack";de.ASPECT_pack="Aspekt des Rudels"
en.ASPECT_wild="Aspect of the Wild";de.ASPECT_wild="Aspekt der Wildnis"
en.ASPECT_viper="Aspect of the Viper";de.ASPECT_viper="Aspekt der Viper"
en.MEND_PET="Mend Pet";de.MEND_PET="Begleiter heilen"
en.REVIVE_PET="Revive Pet";de.REVIVE_PET="Begleiter wiederbeleben"

en.PALADIN="Paladin";de.PALADIN="Paladin"
en.AURAS="Auras";de.AURAS="Auren"
en.BLESSINGS="Blessings";de.BLESSINGS="Segen"
en.ACTIVE_AURA="Active aura";de.ACTIVE_AURA="Aktive Aura"
en.NO_ACTIVE_AURA="No active aura detected";de.NO_ACTIVE_AURA="Keine aktive Aura erkannt"
en.AURA_UNKNOWN="Aura state unavailable";de.AURA_UNKNOWN="Aurenstatus nicht verfügbar"
en.WEAPON_SET="Weapon set";de.WEAPON_SET="Ausrüstungsset"
en.WEAPON_SET_HINT="Click to switch between the selected shield and two-handed sets.";de.WEAPON_SET_HINT="Klicken, um zwischen ausgewähltem Schild- und Zweihand-Set zu wechseln."
en.PALADIN_CLICK_HINT="Click to cast this spell.";de.PALADIN_CLICK_HINT="Klicken, um diesen Zauber zu wirken."
en.SHIELD_EQUIPPED="Shield equipped";de.SHIELD_EQUIPPED="Schild ausgerüstet"
en.TWO_HAND_EQUIPPED="Two-handed weapon equipped";de.TWO_HAND_EQUIPPED="Zweihandwaffe ausgerüstet"
en.SHIELD_UNKNOWN="Weapon state unavailable";de.SHIELD_UNKNOWN="Waffenstatus nicht verfügbar"
for _,key in ipairs({"devotion","retribution","concentration","fireResistance","frostResistance","shadowResistance"})do en["AURA_"..key]=key:gsub("^%l",string.upper);de["AURA_"..key]=en["AURA_"..key]end
for _,key in ipairs({"might","wisdom","kings","salvation","sanctuary","protection","freedom","sacrifice","greaterMight","greaterWisdom","greaterKings"})do en["BLESSING_"..key]=key:gsub("^%l",string.upper);de["BLESSING_"..key]=en["BLESSING_"..key]end
de.AURA_fireResistance="Aura des Feuerwiderstands";de.AURA_frostResistance="Aura des Frostwiderstands";de.AURA_shadowResistance="Aura des Schattenwiderstands"
de.BLESSING_greaterMight="Großer Segen der Macht";de.BLESSING_greaterWisdom="Großer Segen der Weisheit";de.BLESSING_greaterKings="Großer Segen der Könige"
de.AURA_devotion="Aura der Hingabe";de.AURA_retribution="Aura der Vergeltung";de.AURA_concentration="Aura der Konzentration"
de.BLESSING_might="Segen der Macht";de.BLESSING_wisdom="Segen der Weisheit";de.BLESSING_kings="Segen der Könige";de.BLESSING_salvation="Segen der Rettung"

en.WARLOCK="Warlock";de.WARLOCK="Hexer"
en.DEMON_missing="No demon summoned";de.DEMON_missing="Kein Dämon beschworen"
en.DEMON_dead="Demon is dead";de.DEMON_dead="Dämon ist tot"
en.DEMON_living="Demon";de.DEMON_living="Dämon"
en.DEMON_unknown="Demon status unavailable";de.DEMON_unknown="Dämonenstatus nicht verfügbar"
en.SHARDS="Soul shards";de.SHARDS="Seelensplitter"
en.SHARDS_UNKNOWN="Soul shard count unavailable";de.SHARDS_UNKNOWN="Seelensplitterzahl nicht verfügbar"
en.WARLOCK_CLICK_HINT="Click to summon this demon.";de.WARLOCK_CLICK_HINT="Klicken, um diesen Dämon zu beschwören."
en.SUMMON_imp="Summon Imp";de.SUMMON_imp="Wichtel beschwören"
en.SUMMON_voidwalker="Summon Voidwalker";de.SUMMON_voidwalker="Leerwandler beschwören"
en.SUMMON_succubus="Summon Succubus";de.SUMMON_succubus="Sukkubus beschwören"
en.SUMMON_felhunter="Summon Felhunter";de.SUMMON_felhunter="Teufelsjäger beschwören"
en.SUMMON_felguard="Summon Felguard";de.SUMMON_felguard="Teufelswache beschwören"
en.SUMMON_infernal="Summon Infernal";de.SUMMON_infernal="Infernal beschwören"
en.SUMMON_doomguard="Summon Doomguard";de.SUMMON_doomguard="Verdammniswache beschwören"

de.BLESSING_light="Segen des Lichts";de.BLESSING_sanctuary="Segen des Refugiums";de.BLESSING_protection="Segen des Schutzes";de.BLESSING_freedom="Segen der Freiheit";de.BLESSING_sacrifice="Segen der Opferung"
en.DEMON_SAMPLE="Summoned companion";de.DEMON_SAMPLE="Beschworener Begleiter"


en.PLAYER="Player";de.PLAYER="Spieler"
en.LEVEL_UNKNOWN="Level unavailable";de.LEVEL_UNKNOWN="Stufe nicht verfügbar"
en.BUFFS="Buffs";de.BUFFS="Stärkungen"
en.DEBUFFS="Debuffs";de.DEBUFFS="Schwächungen"
en.ENABLE_PLAYER_FRAME="Replace Blizzard player frame";de.ENABLE_PLAYER_FRAME="Blizzard-Spielerrahmen ersetzen"
en.PLAYER_FRAME_SCALE="Player frame scale";de.PLAYER_FRAME_SCALE="Spielerrahmen · Skalierung"

en.PRIEST_MACROS="Quick casts";de.PRIEST_MACROS="Schnellzauber"
en.SHOW_PRIEST_MACROS="Show Priest quick casts";de.SHOW_PRIEST_MACROS="Priester-Schnellzauber einblenden"
en.PRIEST_MACRO_NEAR="Near";de.PRIEST_MACRO_NEAR="Nah"
en.PRIEST_MACRO_SELF="Self";de.PRIEST_MACRO_SELF="Ich"
en.PRIEST_MACRO_NEAR_HINT="With the key binding, hover a friendly unit to cast without changing targets. Otherwise, each press selects the next nearby friendly player and keeps that target.";de.PRIEST_MACRO_NEAR_HINT="Per Tastenkürzel auf eine freundliche Einheit unter dem Mauszeiger wirken, ohne das Ziel zu wechseln. Sonst wählt jeder Druck den nächsten nahen freundlichen Spieler und behält ihn als Ziel."
en.PRIEST_MACRO_SELF_HINT="Casts on yourself.";de.PRIEST_MACRO_SELF_HINT="Wirkt auf dich selbst."
en.SHADOW_WORD_PAIN="Shadow Word: Pain";de.SHADOW_WORD_PAIN="Schattenwort: Schmerz"

en.QUICK_CASTS="Quick casts";de.QUICK_CASTS="Schnellzauber"
en.SHOW_QUICK_CASTS="Show quick casts";de.SHOW_QUICK_CASTS="Schnellzauber einblenden"
en.SHOW_PALADIN_AURAS="Show aura buttons";de.SHOW_PALADIN_AURAS="Aura-Aktionen einblenden"
en.SHOW_PALADIN_BLESSINGS="Show blessing buttons";de.SHOW_PALADIN_BLESSINGS="Segen einblenden"
en.SHOW_PALADIN_WEAPONS="Show equipment swap";de.SHOW_PALADIN_WEAPONS="Ausrüstungswechsel einblenden"
en.WARLOCK_SUMMONS="Summons";de.WARLOCK_SUMMONS="Beschwörungen"
en.SHOW_WARLOCK_SUMMONS="Show summons";de.SHOW_WARLOCK_SUMMONS="Beschwörungen einblenden"
en.WARLOCK_HEALTH_FUNNEL="Health Funnel";de.WARLOCK_HEALTH_FUNNEL="Lebenslinie"
en.WARLOCK_HEALTHSTONE="Create Healthstone";de.WARLOCK_HEALTHSTONE="Gesundheitsstein herstellen"
en.WARLOCK_FUNNEL_HINT="Channels healing to your demon.";de.WARLOCK_FUNNEL_HINT="Kanalisiert Heilung auf deinen Dämon."
en.WARLOCK_HEALTHSTONE_HINT="Creates a healthstone.";de.WARLOCK_HEALTHSTONE_HINT="Stellt einen Gesundheitsstein her."
en.CALL_PET="Call Pet";de.CALL_PET="Begleiter rufen"
en.DISMISS_PET="Dismiss Pet";de.DISMISS_PET="Begleiter freigeben"

en.BIND_HEADING="Key bindings";de.BIND_HEADING="Tastenkürzel"
en.BIND_CAPTURE="Press a key or key combination. Escape cancels.";de.BIND_CAPTURE="Drücke eine Taste oder Kombination. Esc bricht ab."
en.BIND_ASSIGN="Assign";de.BIND_ASSIGN="Belegen"
en.BIND_CLEAR="Clear key binding";de.BIND_CLEAR="Tastenkürzel entfernen"
en.BIND_CONFLICT="This key combination is already in use.";de.BIND_CONFLICT="Diese Tastenkombination ist bereits belegt."
en.BIND_UNAVAILABLE="Could not set this key binding.";de.BIND_UNAVAILABLE="Dieses Tastenkürzel konnte nicht gesetzt werden."
en.BIND_INACTIVE="Saved. Active when the action is visible in your class control.";de.BIND_INACTIVE="Gespeichert. Aktiv, wenn die Aktion in deiner Klassenanzeige sichtbar ist."
en.BIND_COMBAT="Change key bindings after combat.";de.BIND_COMBAT="Tastenkürzel lassen sich nach dem Kampf ändern."
en.BIND_PROTECTION_SELF="Protection on yourself";de.BIND_PROTECTION_SELF="Schutz auf dich selbst"
en.BIND_FREEDOM_SELF="Freedom on yourself";de.BIND_FREEDOM_SELF="Freiheit auf dich selbst"
en.BIND_FORTITUDE_NEARBY="Fortitude on a nearby ally";de.BIND_FORTITUDE_NEARBY="Seelenstärke auf nahen Spieler"
en.BIND_FORTITUDE_SELF="Fortitude on yourself";de.BIND_FORTITUDE_SELF="Seelenstärke auf dich selbst"
en.BIND_SHIELD_SELF="Shield on yourself";de.BIND_SHIELD_SELF="Schild auf dich selbst"
en.BIND_RENEW_SELF="Renew on yourself";de.BIND_RENEW_SELF="Erneuerung auf dich selbst"

en.PRIEST_FORTITUDE_HOVER="Hover a friendly unit";de.PRIEST_FORTITUDE_HOVER="Mauszeiger auf freundliche Einheit"
en.PRIEST_FORTITUDE_TARGET="Unit under cursor";de.PRIEST_FORTITUDE_TARGET="Einheit unter der Maus"
en.PRIEST_FORTITUDE_IN="In range";de.PRIEST_FORTITUDE_IN="In Reichweite"
en.PRIEST_FORTITUDE_OUT="Out of range";de.PRIEST_FORTITUDE_OUT="Außer Reichweite"
en.PRIEST_FORTITUDE_RANGE_UNKNOWN="Range unknown";de.PRIEST_FORTITUDE_RANGE_UNKNOWN="Reichweite unbekannt"
en.PRIEST_FORTITUDE_ACTIVE="Fortitude active";de.PRIEST_FORTITUDE_ACTIVE="Schon gestärkt"
en.PRIEST_FORTITUDE_MISSING="Fortitude missing";de.PRIEST_FORTITUDE_MISSING="Seelenstärke fehlt"
en.PRIEST_FORTITUDE_AURA_UNKNOWN="Buff unknown";de.PRIEST_FORTITUDE_AURA_UNKNOWN="Buff unbekannt"

en.CAST_BAR="Cast bar";de.CAST_BAR="Zauberleiste"
en.ENABLE_CAST_BAR="Replace Blizzard cast bar";de.ENABLE_CAST_BAR="Blizzard-Zauberleiste ersetzen"
en.CAST_BAR_SCALE="Cast bar scale";de.CAST_BAR_SCALE="Zauberleiste · Skalierung"
en.CAST_BAR_DEMO="Hearthstone · Preview";de.CAST_BAR_DEMO="Ruhestein · Vorschau"
en.CAST_BAR_DEMO_TIME="4.5 s";de.CAST_BAR_DEMO_TIME="4,5 s"

en.PLAYER_MENU="Player menu";de.PLAYER_MENU="Spielermenü"
en.PLAYER_MENU_HINT="Right-click to open the player menu.";de.PLAYER_MENU_HINT="Rechtsklick öffnet das Spielermenü."

en.REST_AREA="Rest area";de.REST_AREA="Ruhezone"

en.HUNTER_MARK="Hunter's Mark";de.HUNTER_MARK="Mal des Jägers"
en.HUNTER_MARK_ATTACK="Mark + pet attack";de.HUNTER_MARK_ATTACK="Mal + Begleiterangriff"
en.HUNTER_MARK_ATTACK_HINT="Marks your current enemy and sends your pet to attack it.";de.HUNTER_MARK_ATTACK_HINT="Markiert dein aktuelles Gegnerziel und schickt deinen Begleiter darauf."

en.MAGE = "Mage"; de.MAGE = "Magier"
en.SHAMAN = "Shaman"; de.SHAMAN = "Schamane"
en.DRUID = "Druid"; de.DRUID = "Druide"
en.ENABLE_MAGE = "Show Mage module"; de.ENABLE_MAGE = "Magier-Anzeige einblenden"
en.ENABLE_SHAMAN = "Show Shaman module"; de.ENABLE_SHAMAN = "Schamanen-Anzeige einblenden"
en.ENABLE_DRUID = "Show Druid buff bar"; de.ENABLE_DRUID = "Druiden-Buffleiste einblenden"
en.FRIENDLY_BUFFS = "Buff allies"; de.FRIENDLY_BUFFS = "Verbündete stärken"
en.SHOW_FRIENDLY_BUFFS = "Show ally buff shortcuts"; de.SHOW_FRIENDLY_BUFFS = "Schnellbuffs für Verbündete einblenden"
en.CLASS_UTILITY = "Utility"; de.CLASS_UTILITY = "Klassenaktionen"
en.SHOW_CLASS_UTILITY = "Show utility actions"; de.SHOW_CLASS_UTILITY = "Klassenaktionen einblenden"
en.SHAMAN_TOTEMS = "Totems"; de.SHAMAN_TOTEMS = "Totems"
en.SHOW_SHAMAN_TOTEMS = "Show totem actions"; de.SHOW_SHAMAN_TOTEMS = "Totem-Aktionen einblenden"
en.CLASS_ACTION_HINT = "Click to cast."; de.CLASS_ACTION_HINT = "Zum Wirken klicken."
en.BIND_MIGHT = "Blessing of Might on an ally"; de.BIND_MIGHT = "Segen der Macht auf Verbündete"
en.BIND_WISDOM = "Blessing of Wisdom on an ally"; de.BIND_WISDOM = "Segen der Weisheit auf Verbündete"
en.BIND_KINGS = "Blessing of Kings on an ally"; de.BIND_KINGS = "Segen der Könige auf Verbündete"
en.BIND_ARCANE_INTELLECT = "Arcane Intellect on an ally"; de.BIND_ARCANE_INTELLECT = "Arkane Intelligenz auf Verbündete"
en.BIND_WATER_WALKING = "Water Walking on an ally"; de.BIND_WATER_WALKING = "Wasserwandeln auf Verbündete"
en.BIND_WATER_BREATHING = "Water Breathing on an ally"; de.BIND_WATER_BREATHING = "Wasseratmung auf Verbündete"
en.BIND_UNENDING_BREATH = "Unending Breath on an ally"; de.BIND_UNENDING_BREATH = "Unendlicher Atem auf Verbündete"
en.BIND_MARK_OF_THE_WILD = "Mark of the Wild on an ally"; de.BIND_MARK_OF_THE_WILD = "Mal der Wildnis auf Verbündete"
en.BIND_THORNS = "Thorns on an ally"; de.BIND_THORNS = "Dornen auf Verbündete"
en.BIND_SHADOW_PROTECTION = "Shadow Protection on an ally"; de.BIND_SHADOW_PROTECTION = "Schattenschutz auf Verbündete"
en.BIND_DIVINE_SPIRIT = "Divine Spirit on an ally"; de.BIND_DIVINE_SPIRIT = "Göttlicher Wille auf Verbündete"
en.SHADOW_PROTECTION = "Shadow Protection"; de.SHADOW_PROTECTION = "Schattenschutz"
en.DIVINE_SPIRIT = "Divine Spirit"; de.DIVINE_SPIRIT = "Göttlicher Wille"

en.CLASS_SETTINGS_EMPTY = "This class has no settings yet."
de.CLASS_SETTINGS_EMPTY = "Für diese Klasse gibt es noch keine Einstellungen."

en.NOT_ENOUGH_POWER = "Not enough resources."
de.NOT_ENOUGH_POWER = "Nicht genug Ressourcen."
en.NOT_ENOUGH_MANA = "Not enough mana."
de.NOT_ENOUGH_MANA = "Nicht genug Mana."

en.RAGE = "Rage"; de.RAGE = "Wut"
en.ENERGY = "Energy"; de.ENERGY = "Energie"
en.RESOURCE = "Resource"; de.RESOURCE = "Ressource"
en.ROGUE = "Rogue"; de.ROGUE = "Schurke"
en.WARRIOR = "Warrior"; de.WARRIOR = "Krieger"
en.ENABLE_ROGUE = "Show Rogue module"; de.ENABLE_ROGUE = "Schurken-Anzeige einblenden"
en.ENABLE_WARRIOR = "Show Warrior module"; de.ENABLE_WARRIOR = "Krieger-Anzeige einblenden"
en.INTERRUPTS = "Interrupts"; de.INTERRUPTS = "Unterbrechen"
en.SHOW_INTERRUPTS = "Show interrupts"; de.SHOW_INTERRUPTS = "Unterbrechungsaktionen einblenden"
en.SHOW_WARRIOR_STANCES = "Show stance actions"; de.SHOW_WARRIOR_STANCES = "Haltungswechsel einblenden"
en.ROGUE_KICK = "Kick"; de.ROGUE_KICK = "Tritt"
en.COMBO_POINTS = "Combo points"; de.COMBO_POINTS = "Combopunkte"
en.STANCES = "Stances"; de.STANCES = "Haltungen"
en.BATTLE_STANCE = "Battle Stance"; de.BATTLE_STANCE = "Kampfhaltung"
en.DEFENSIVE_STANCE = "Defensive Stance"; de.DEFENSIVE_STANCE = "Verteidigungshaltung"
en.BERSERKER_STANCE = "Berserker Stance"; de.BERSERKER_STANCE = "Berserkerhaltung"
en.NO_ACTIVE_STANCE = "Stance unknown"; de.NO_ACTIVE_STANCE = "Haltung unbekannt"

en.ENABLE_TARGET_FRAME = "Replace Blizzard target frame"; de.ENABLE_TARGET_FRAME = "Blizzard-Zielrahmen ersetzen"
en.TARGET_FRAME = "Target frame"; de.TARGET_FRAME = "Zielrahmen"
en.TARGET_DEMO = "Training Dummy"; de.TARGET_DEMO = "Trainingsattrappe"
en.TARGET_CAST = "Target cast"; de.TARGET_CAST = "Zielzauber"
en.TARGET_CAST_DEMO = "Fireball"; de.TARGET_CAST_DEMO = "Feuerball"
en.TARGET_CAST_INTERRUPTIBLE = "Interruptible"; de.TARGET_CAST_INTERRUPTIBLE = "Unterbrechbar"
en.TARGET_CAST_UNINTERRUPTIBLE = "Uninterruptible"; de.TARGET_CAST_UNINTERRUPTIBLE = "Nicht unterbrechbar"
en.TARGET_LEVEL_BOSS = "Level ??"; de.TARGET_LEVEL_BOSS = "Stufe ??"

en.COMPANION = "Companion"; de.COMPANION = "Begleiter"
en.COMPANION_TARGET = "Target"; de.COMPANION_TARGET = "Ziel"
en.COMPANION_SAMPLE_PET = "Companion"; de.COMPANION_SAMPLE_PET = "Begleiter"
en.COMPANION_SAMPLE_TARGET = "Training Dummy"; de.COMPANION_SAMPLE_TARGET = "Trainingsattrappe"
en.SHOW_COMPANION_FRAME = "Show companion frame"; de.SHOW_COMPANION_FRAME = "Begleiterrahmen einblenden"
en.SHOW_TOTEM_STATUS = "Show active totems"; de.SHOW_TOTEM_STATUS = "Aktive Totems einblenden"
en.ACTIVE_TOTEMS = "Active totems"; de.ACTIVE_TOTEMS = "Aktive Totems"
en.TOTEM_FIRE = "Fire"; de.TOTEM_FIRE = "Feuer"
en.TOTEM_EARTH = "Earth"; de.TOTEM_EARTH = "Erde"
en.TOTEM_WATER = "Water"; de.TOTEM_WATER = "Wasser"
en.TOTEM_AIR = "Air"; de.TOTEM_AIR = "Luft"

en.TARGET_OF_TARGET = "Target of target"; de.TARGET_OF_TARGET = "Ziel des Ziels"
en.TARGET_IS_YOU = "You"; de.TARGET_IS_YOU = "Du"
en.MAGE_COUNTERSPELL = "Counterspell"; de.MAGE_COUNTERSPELL = "Gegenzauber"
en.SHAMAN_EARTH_SHOCK = "Earth Shock"; de.SHAMAN_EARTH_SHOCK = "Erdschock"
en.PRIEST_SILENCE = "Silence"; de.PRIEST_SILENCE = "Stille"
en.WARRIOR_PUMMEL = "Pummel"; de.WARRIOR_PUMMEL = "Zuschlagen"
en.WARRIOR_SHIELD_BASH = "Shield Bash"; de.WARRIOR_SHIELD_BASH = "Schildhieb"

en.PARTY_FRAMES = "Party frames"; de.PARTY_FRAMES = "Gruppenrahmen"
en.SHOW_PARTY_FRAMES = "Show Forever party frames"; de.SHOW_PARTY_FRAMES = "Forever-Gruppenrahmen einblenden"
en.REPLACE_BLIZZARD_PARTY = "Replace Blizzard party frames"; de.REPLACE_BLIZZARD_PARTY = "Blizzard-Gruppenrahmen ersetzen"
en.PARTY_MEMBERS = "Party"; de.PARTY_MEMBERS = "Gruppe"
en.PARTY_MEMBER = "Party member"; de.PARTY_MEMBER = "Gruppenmitglied"
en.PARTY_TANK = "Tank"; de.PARTY_TANK = "Tank"
en.PARTY_HEALER = "Healer"; de.PARTY_HEALER = "Heiler"
en.PARTY_DAMAGE = "Damage"; de.PARTY_DAMAGE = "Schaden"
en.PARTY_OFFLINE = "Offline"; de.PARTY_OFFLINE = "Offline"
en.PARTY_DEAD = "Dead"; de.PARTY_DEAD = "Tot"

en.PRIEST_MACRO_MOUSEOVER = "Hover"; de.PRIEST_MACRO_MOUSEOVER = "Maus"
en.PRIEST_MACRO_MOUSEOVER_HINT = "Hover a friendly unit or party frame and use the key binding to cast."
de.PRIEST_MACRO_MOUSEOVER_HINT = "Mit der Maus auf einen Gruppenrahmen oder eine freundliche Einheit zeigen und das Tastenkürzel drücken."
en.BIND_SHIELD_MOUSEOVER = "Shield on mouseover"; de.BIND_SHIELD_MOUSEOVER = "Schild auf Mouseover"
en.BIND_RENEW_MOUSEOVER = "Renew on mouseover"; de.BIND_RENEW_MOUSEOVER = "Erneuerung auf Mouseover"

en.TAB_APPEARANCE = "Appearance"; de.TAB_APPEARANCE = "Aussehen"
en.CLASS_ACCENT = "Use class color for accents"; de.CLASS_ACCENT = "Klassenfarbe als Akzent"
en.MOVE_CLASS_GROUPS_HINT = "Unlock positions. Use Alt/Option to drag this group or Shift + Alt/Option to move all class groups."
de.MOVE_CLASS_GROUPS_HINT = "Positionen entsperren. Mit Alt/Option diese Gruppe ziehen. Mit Umschalt + Alt/Option alle Klassengruppen verschieben."
en.ACTION_BARS = "Action bars"; de.ACTION_BARS = "Aktionsleisten"
en.INVENTORY = "Bags and bank"; de.INVENTORY = "Taschen und Bank"
en.STYLE_ACTION_BARS = "Style Blizzard action bars"; de.STYLE_ACTION_BARS = "Blizzard-Aktionsleisten gestalten"
en.STYLE_INVENTORY = "Style Blizzard bags and bank"; de.STYLE_INVENTORY = "Blizzard-Taschen und Bank gestalten"
en.BACKGROUND_OPACITY = "Background opacity"; de.BACKGROUND_OPACITY = "Hintergrunddeckkraft"
en.INVENTORY_FREE_SLOTS = "%d free"; de.INVENTORY_FREE_SLOTS = "%d frei"
