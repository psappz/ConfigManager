local ADDON, ns = ...
-- Bundled presets.
--  * Role presets: key bindings only (US key positions, remapped to the player's layout).
--  * Class/spec presets: the role key bindings plus action bar contents. The spell choice
--    follows the TBC Anniversary spell summaries on Icy Veins (rotation, cooldowns, utility)
--    cross-checked with Wowhead. Every spell is stored as English name + spell ID; at import
--    the ID is only used to look up the localized name, and the spell is then placed by name,
--    so the game uses the highest rank the character knows. Unknown spells are skipped and
--    counted ("/cfgm checkpresets" lists them for the current character).
local P = {}
ns.Presets = P

local function base()
  return {
    { "W", "MOVEFORWARD" }, { "S", "MOVEBACKWARD" }, { "A", "STRAFELEFT" }, { "D", "STRAFERIGHT" },
    { "SPACE", "JUMP" }, { "NUMLOCK", "TOGGLEAUTORUN" }, { "TAB", "TARGETNEARESTENEMY" }, { "SHIFT-TAB", "TARGETPREVIOUSENEMY" },
    { "ENTER", "OPENCHAT" }, { "ESCAPE", "TOGGLEGAMEMENU" }, { "B", "OPENALLBAGS" }, { "C", "TOGGLECHARACTER0" },
    { "M", "TOGGLEWORLDMAP" }, { "L", "TOGGLEQUESTLOG" }, { "O", "TOGGLESOCIAL" }, { "PRINTSCREEN", "SCREENSHOT" },
    { "MOUSEWHEELUP", "CAMERAZOOMIN" }, { "MOUSEWHEELDOWN", "CAMERAZOOMOUT" },
  }
end

local function add(list, keys, prefix, first)
  for i, k in ipairs(keys) do list[#list + 1] = { k, prefix .. (first + i - 1) } end
end

local function roleBinds(role)
  local b = base()
  add(b, { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "G", "T", "V" }, "ACTIONBUTTON", 1)
  add(b, { "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-G" }, "MULTIACTIONBAR1BUTTON", 1)
  add(b, { "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-Q", "CTRL-E" }, "MULTIACTIONBAR2BUTTON", 1)
  add(b, { "ALT-1", "ALT-2", "ALT-3", "ALT-4" }, "MULTIACTIONBAR3BUTTON", 1)
  if role == "HEALER" then
    b[#b + 1] = { "F1", "TARGETSELF" }
    add(b, { "F2", "F3", "F4", "F5" }, "TARGETPARTYMEMBER", 1)
    add(b, { "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5" }, "MULTIACTIONBAR4BUTTON", 1)
  elseif role == "TANK" then
    add(b, { "BUTTON4", "BUTTON5" }, "MULTIACTIONBAR4BUTTON", 1)
    b[#b + 1] = { "CTRL-TAB", "FOCUSTARGET" }
    b[#b + 1] = { "SHIFT-BUTTON4", "MULTIACTIONBAR4BUTTON3" }
  else
    add(b, { "BUTTON4", "BUTTON5" }, "MULTIACTIONBAR1BUTTON", 11)
    b[#b + 1] = { "CTRL-TAB", "FOCUSTARGET" }
  end
  return b
end
P.RoleBinds = roleBinds

local function rolePreset(role)
  return { v = 1, layout = "us", meta = { role = role }, binds = roleBinds(role) }
end

---------------------------------------------------------------------------
-- Class/spec presets
---------------------------------------------------------------------------
-- Bars: main = action bar 1 (keys 1-5 Q E R F G T V), shift = bottom left bar
-- (Shift+1-5 Q E R F G, mouse 4/5 for damage dealers), ctrl = bottom right bar
-- (Ctrl+1-5 Q E), alt = right bar (Alt+1-4). Form/stance bars use the same keys as bar 1.
P.SLOTS = { main = 1, shift = 61, ctrl = 49, alt = 25,
  stance1 = 73, stance2 = 85, stance3 = 97, stance4 = 109 }
local LIMIT = { main = 12, shift = 12, ctrl = 7, alt = 4, stance1 = 12, stance2 = 12, stance3 = 12, stance4 = 12 }
P.LIMIT = LIMIT

-- Spell lists: "English Name:spellID" separated by ";".
-- tab = talent tree index (Classic clients), spec = specialization IDs (modern clients).
local SPECS = {
  -- Warrior: stance bars (73 Battle, 85 Defensive, 97 Berserker) get the same main bar.
  { class = "WARRIOR", tab = 1, spec = { 71 }, role = "DAMAGER", key = "arms", stances = { "stance1", "stance2", "stance3" },
    main = "Mortal Strike:12294;Slam:1464;Whirlwind:1680;Execute:5308;Heroic Strike:78;Cleave:845;Sweeping Strikes:12328;Overpower:7384;Hamstring:1715;Bloodrage:2687;Battle Shout:6673;Charge:100",
    shift = "Recklessness:1719;Retaliation:20230;Shield Wall:871;Berserker Rage:18499;Intimidating Shout:5246;Thunder Clap:6343;Demoralizing Shout:1160;Intercept:20252;Pummel:6552;Disarm:676",
    ctrl = "Battle Stance:2457;Defensive Stance:71;Berserker Stance:2458;Intervene:3411;Taunt:355;Commanding Shout:469;Shield Bash:72" },
  { class = "WARRIOR", tab = 2, spec = { 72 }, role = "DAMAGER", key = "fury", stances = { "stance1", "stance2", "stance3" },
    main = "Bloodthirst:23881;Whirlwind:1680;Rampage:29801;Execute:5308;Heroic Strike:78;Cleave:845;Slam:1464;Sweeping Strikes:12328;Hamstring:1715;Bloodrage:2687;Battle Shout:6673;Intercept:20252",
    shift = "Death Wish:12292;Recklessness:1719;Retaliation:20230;Shield Wall:871;Berserker Rage:18499;Intimidating Shout:5246;Piercing Howl:12323;Thunder Clap:6343;Demoralizing Shout:1160;Pummel:6552",
    ctrl = "Battle Stance:2457;Defensive Stance:71;Berserker Stance:2458;Intervene:3411;Disarm:676;Commanding Shout:469;Charge:100" },
  { class = "WARRIOR", tab = 3, spec = { 73 }, role = "TANK", key = "prot", stances = { "stance1", "stance2", "stance3" },
    main = "Shield Slam:23922;Revenge:6572;Devastate:20243;Sunder Armor:7386;Heroic Strike:78;Cleave:845;Thunder Clap:6343;Demoralizing Shout:1160;Shield Block:2565;Taunt:355;Bloodrage:2687;Commanding Shout:469",
    shift = "Last Stand:12975;Shield Wall:871;Spell Reflection:23920;Mocking Blow:694;Challenging Shout:1161;Concussion Blow:12809;Retaliation:20230;Recklessness:1719;Berserker Rage:18499;Disarm:676",
    ctrl = "Battle Stance:2457;Defensive Stance:71;Berserker Stance:2458;Charge:100;Intercept:20252;Intervene:3411;Shield Bash:72",
    alt = "Battle Shout:6673;Intimidating Shout:5246;Hamstring:1715" },

  { class = "PALADIN", tab = 1, spec = { 65 }, role = "HEALER", key = "holy",
    main = "Holy Light:635;Flash of Light:19750;Holy Shock:20473;Cleanse:4987;Judgement:20271;Seal of Wisdom:20166;Seal of Light:20165;Divine Favor:20216;Hammer of Justice:853;Blessing of Freedom:1044;Blessing of Protection:1022;Divine Shield:642",
    shift = "Divine Illumination:31842;Lay on Hands:633;Avenging Wrath:31884;Aura Mastery:31821;Blessing of Sacrifice:6940;Purify:1152;Redemption:7328",
    ctrl = "Devotion Aura:465;Concentration Aura:19746;Retribution Aura:7294;Crusader Aura:32223;Greater Blessing of Kings:25898;Greater Blessing of Wisdom:25894;Greater Blessing of Might:25782",
    alt = "Greater Blessing of Light:25890;Greater Blessing of Salvation:25895;Blessing of Kings:20217;Blessing of Wisdom:19742" },
  { class = "PALADIN", tab = 2, spec = { 66 }, role = "TANK", key = "prot",
    main = "Holy Shield:20925;Avenger's Shield:31935;Consecration:26573;Judgement:20271;Seal of Righteousness:21084;Seal of Vengeance:31801;Exorcism:879;Holy Wrath:2812;Hammer of Wrath:24275;Righteous Defense:31789;Hammer of Justice:853;Cleanse:4987",
    shift = "Avenging Wrath:31884;Divine Shield:642;Lay on Hands:633;Blessing of Protection:1022;Blessing of Freedom:1044;Divine Protection:498;Flash of Light:19750;Holy Light:635",
    ctrl = "Righteous Fury:25780;Devotion Aura:465;Retribution Aura:7294;Crusader Aura:32223;Greater Blessing of Sanctuary:25899;Greater Blessing of Kings:25898;Redemption:7328" },
  { class = "PALADIN", tab = 3, spec = { 70 }, role = "DAMAGER", key = "ret",
    main = "Crusader Strike:35395;Judgement:20271;Seal of Command:20375;Seal of Blood:31892;Seal of the Crusader:21082;Hammer of Wrath:24275;Consecration:26573;Exorcism:879;Hammer of Justice:853;Repentance:20066;Cleanse:4987;Flash of Light:19750",
    shift = "Avenging Wrath:31884;Divine Shield:642;Lay on Hands:633;Blessing of Freedom:1044;Blessing of Protection:1022;Divine Protection:498;Holy Light:635;Redemption:7328",
    ctrl = "Sanctity Aura:20218;Retribution Aura:7294;Devotion Aura:465;Crusader Aura:32223;Greater Blessing of Might:25782;Greater Blessing of Kings:25898;Greater Blessing of Wisdom:25894" },

  { class = "HUNTER", tab = 1, spec = { 253 }, role = "DAMAGER", key = "bm",
    main = "Steady Shot:34120;Kill Command:34026;Multi-Shot:2643;Arcane Shot:3044;Serpent Sting:1978;Hunter's Mark:1130;Auto Shot:75;Aimed Shot:19434;Raptor Strike:2973;Mongoose Bite:1495;Wing Clip:2974;Concussive Shot:5116",
    shift = "Bestial Wrath:19574;Rapid Fire:3045;Intimidation:19577;Misdirection:34477;Feign Death:5384;Freezing Trap:1499;Frost Trap:13809;Explosive Trap:13813;Disengage:781;Volley:1510",
    ctrl = "Aspect of the Hawk:13165;Aspect of the Viper:34074;Aspect of the Cheetah:5118;Mend Pet:136;Call Pet:883;Revive Pet:982;Tranquilizing Shot:19801",
    alt = "Flare:1543;Aspect of the Pack:13159;Scare Beast:1513;Dismiss Pet:2641" },
  { class = "HUNTER", tab = 2, spec = { 254 }, role = "DAMAGER", key = "mm",
    main = "Steady Shot:34120;Arcane Shot:3044;Multi-Shot:2643;Aimed Shot:19434;Serpent Sting:1978;Hunter's Mark:1130;Kill Command:34026;Auto Shot:75;Silencing Shot:34490;Raptor Strike:2973;Wing Clip:2974;Concussive Shot:5116",
    shift = "Rapid Fire:3045;Trueshot Aura:19506;Scatter Shot:19503;Misdirection:34477;Feign Death:5384;Freezing Trap:1499;Frost Trap:13809;Explosive Trap:13813;Deterrence:19263;Volley:1510",
    ctrl = "Aspect of the Hawk:13165;Aspect of the Viper:34074;Aspect of the Cheetah:5118;Mend Pet:136;Call Pet:883;Revive Pet:982;Tranquilizing Shot:19801",
    alt = "Flare:1543;Disengage:781;Aspect of the Pack:13159;Dismiss Pet:2641" },
  { class = "HUNTER", tab = 3, spec = { 255 }, role = "DAMAGER", key = "sv",
    main = "Steady Shot:34120;Arcane Shot:3044;Multi-Shot:2643;Serpent Sting:1978;Hunter's Mark:1130;Kill Command:34026;Auto Shot:75;Aimed Shot:19434;Raptor Strike:2973;Mongoose Bite:1495;Counterattack:19306;Wing Clip:2974",
    shift = "Rapid Fire:3045;Readiness:23989;Wyvern Sting:19386;Deterrence:19263;Misdirection:34477;Feign Death:5384;Freezing Trap:1499;Frost Trap:13809;Explosive Trap:13813;Volley:1510",
    ctrl = "Aspect of the Hawk:13165;Aspect of the Viper:34074;Aspect of the Cheetah:5118;Mend Pet:136;Call Pet:883;Revive Pet:982;Tranquilizing Shot:19801",
    alt = "Flare:1543;Disengage:781;Concussive Shot:5116;Dismiss Pet:2641" },

  -- Rogue: bar 73 is the stealth bar (openers).
  { class = "ROGUE", tab = 1, spec = { 259 }, role = "DAMAGER", key = "assa",
    main = "Mutilate:1329;Sinister Strike:1752;Slice and Dice:5171;Envenom:32645;Rupture:1943;Eviscerate:2098;Expose Armor:8647;Shiv:5938;Kick:1766;Gouge:1776;Kidney Shot:408;Stealth:1784",
    stance1 = "Cheap Shot:1833;Garrote:703;Ambush:8676;Sap:6770;Pick Pocket:921;Mutilate:1329;Distract:1725;Stealth:1784",
    shift = "Cold Blood:14177;Vanish:1856;Evasion:5277;Sprint:2983;Cloak of Shadows:31224;Blind:2094;Feint:1966;Distract:1725",
    ctrl = "Kick:1766;Kidney Shot:408;Gouge:1776;Blind:2094;Sap:6770;Pick Lock:1804;Detect Traps:2836" },
  { class = "ROGUE", tab = 2, spec = { 260 }, role = "DAMAGER", key = "combat",
    main = "Sinister Strike:1752;Slice and Dice:5171;Rupture:1943;Eviscerate:2098;Expose Armor:8647;Shiv:5938;Kick:1766;Gouge:1776;Kidney Shot:408;Riposte:14251;Feint:1966;Stealth:1784",
    stance1 = "Cheap Shot:1833;Garrote:703;Ambush:8676;Sap:6770;Pick Pocket:921;Sinister Strike:1752;Distract:1725;Stealth:1784",
    shift = "Adrenaline Rush:13750;Blade Flurry:13877;Vanish:1856;Evasion:5277;Sprint:2983;Cloak of Shadows:31224;Blind:2094;Distract:1725",
    ctrl = "Kick:1766;Kidney Shot:408;Gouge:1776;Blind:2094;Sap:6770;Pick Lock:1804;Detect Traps:2836" },
  { class = "ROGUE", tab = 3, spec = { 261 }, role = "DAMAGER", key = "sub",
    main = "Hemorrhage:16511;Sinister Strike:1752;Slice and Dice:5171;Rupture:1943;Eviscerate:2098;Expose Armor:8647;Shiv:5938;Kick:1766;Gouge:1776;Kidney Shot:408;Feint:1966;Stealth:1784",
    stance1 = "Cheap Shot:1833;Garrote:703;Ambush:8676;Sap:6770;Pick Pocket:921;Premeditation:14183;Distract:1725;Stealth:1784",
    shift = "Shadowstep:36554;Preparation:14185;Vanish:1856;Evasion:5277;Sprint:2983;Cloak of Shadows:31224;Blind:2094;Distract:1725",
    ctrl = "Kick:1766;Kidney Shot:408;Gouge:1776;Blind:2094;Sap:6770;Pick Lock:1804;Detect Traps:2836" },

  { class = "PRIEST", tab = 1, spec = { 256 }, role = "HEALER", key = "disc",
    main = "Power Word: Shield:17;Flash Heal:2061;Greater Heal:2060;Renew:139;Prayer of Mending:33076;Binding Heal:32546;Prayer of Healing:596;Dispel Magic:527;Abolish Disease:552;Smite:585;Fade:586;Psychic Scream:8122",
    shift = "Pain Suppression:33206;Power Infusion:10060;Inner Focus:14751;Shadowfiend:34433;Fear Ward:6346;Mass Dispel:32375;Resurrection:2006",
    ctrl = "Power Word: Fortitude:1243;Prayer of Fortitude:21562;Divine Spirit:14752;Prayer of Spirit:27681;Shadow Protection:976;Prayer of Shadow Protection:27683;Inner Fire:588" },
  { class = "PRIEST", tab = 2, spec = { 257 }, role = "HEALER", key = "holy",
    main = "Greater Heal:2060;Flash Heal:2061;Renew:139;Circle of Healing:34861;Prayer of Mending:33076;Binding Heal:32546;Prayer of Healing:596;Power Word: Shield:17;Dispel Magic:527;Abolish Disease:552;Fade:586;Psychic Scream:8122",
    shift = "Inner Focus:14751;Shadowfiend:34433;Fear Ward:6346;Mass Dispel:32375;Holy Nova:15237;Lightwell:724;Resurrection:2006",
    ctrl = "Power Word: Fortitude:1243;Prayer of Fortitude:21562;Divine Spirit:14752;Prayer of Spirit:27681;Shadow Protection:976;Prayer of Shadow Protection:27683;Inner Fire:588" },
  { class = "PRIEST", tab = 3, spec = { 258 }, role = "DAMAGER", key = "shadow",
    main = "Vampiric Touch:34914;Shadow Word: Pain:589;Mind Blast:8092;Shadow Word: Death:32379;Mind Flay:15407;Vampiric Embrace:15286;Power Word: Shield:17;Devouring Plague:2944;Psychic Scream:8122;Fade:586;Dispel Magic:527;Shadowform:15473",
    shift = "Shadowfiend:34433;Inner Focus:14751;Fear Ward:6346;Silence:15487;Mass Dispel:32375;Shackle Undead:9484;Mind Soothe:453;Flash Heal:2061",
    ctrl = "Power Word: Fortitude:1243;Prayer of Fortitude:21562;Divine Spirit:14752;Shadow Protection:976;Prayer of Shadow Protection:27683;Inner Fire:588;Resurrection:2006" },

  { class = "SHAMAN", tab = 1, spec = { 262 }, role = "DAMAGER", key = "ele",
    main = "Lightning Bolt:403;Chain Lightning:421;Flame Shock:8050;Earth Shock:8042;Frost Shock:8056;Purge:370;Totem of Wrath:30706;Wrath of Air Totem:3738;Mana Spring Totem:5675;Searing Totem:3599;Magma Totem:8190;Water Shield:24398",
    shift = "Elemental Mastery:16166;Bloodlust:2825;Heroism:32182;Fire Elemental Totem:2894;Earth Elemental Totem:2062;Totemic Call:36936;Grounding Totem:8177;Tremor Totem:8143;Earthbind Totem:2484;Fire Nova Totem:1535",
    ctrl = "Healing Wave:331;Lesser Healing Wave:8004;Chain Heal:1064;Cure Poison:526;Cure Disease:2870;Ghost Wolf:2645;Ancestral Spirit:2008",
    alt = "Strength of Earth Totem:8075;Stoneskin Totem:8071;Windfury Totem:8512;Lightning Shield:324" },
  { class = "SHAMAN", tab = 2, spec = { 263 }, role = "DAMAGER", key = "enh",
    main = "Stormstrike:17364;Earth Shock:8042;Flame Shock:8050;Frost Shock:8056;Lightning Bolt:403;Chain Lightning:421;Purge:370;Windfury Totem:8512;Strength of Earth Totem:8075;Searing Totem:3599;Magma Totem:8190;Water Shield:24398",
    shift = "Shamanistic Rage:30823;Bloodlust:2825;Heroism:32182;Fire Elemental Totem:2894;Earth Elemental Totem:2062;Totemic Call:36936;Grounding Totem:8177;Tremor Totem:8143;Earthbind Totem:2484;Fire Nova Totem:1535",
    ctrl = "Windfury Weapon:8232;Flametongue Weapon:8024;Rockbiter Weapon:8017;Healing Wave:331;Lesser Healing Wave:8004;Ghost Wolf:2645;Ancestral Spirit:2008",
    alt = "Grace of Air Totem:8835;Mana Spring Totem:5675;Wrath of Air Totem:3738;Lightning Shield:324" },
  { class = "SHAMAN", tab = 3, spec = { 264 }, role = "HEALER", key = "resto",
    main = "Chain Heal:1064;Lesser Healing Wave:8004;Healing Wave:331;Earth Shield:974;Water Shield:24398;Cure Poison:526;Cure Disease:2870;Purge:370;Earth Shock:8042;Lightning Bolt:403;Mana Spring Totem:5675;Wrath of Air Totem:3738",
    shift = "Nature's Swiftness:16188;Mana Tide Totem:16190;Bloodlust:2825;Heroism:32182;Earth Elemental Totem:2062;Fire Elemental Totem:2894;Totemic Call:36936;Grounding Totem:8177;Tremor Totem:8143;Poison Cleansing Totem:8166",
    ctrl = "Strength of Earth Totem:8075;Windfury Totem:8512;Healing Stream Totem:5394;Stoneskin Totem:8071;Earthbind Totem:2484;Ghost Wolf:2645;Ancestral Spirit:2008",
    alt = "Searing Totem:3599;Disease Cleansing Totem:8170;Frost Shock:8056;Chain Lightning:421" },

  { class = "MAGE", tab = 1, spec = { 62 }, role = "DAMAGER", key = "arcane",
    main = "Arcane Blast:30451;Frostbolt:116;Arcane Missiles:5143;Fire Blast:2136;Arcane Explosion:1449;Cone of Cold:120;Blizzard:10;Frost Nova:122;Counterspell:2139;Polymorph:118;Blink:1953;Spellsteal:30449",
    shift = "Arcane Power:12042;Presence of Mind:12043;Icy Veins:12472;Cold Snap:11958;Evocation:12051;Ice Block:45438;Invisibility:66;Mana Shield:1463;Slow:31589;Remove Lesser Curse:475",
    ctrl = "Mage Armor:6117;Molten Armor:30482;Arcane Intellect:1459;Arcane Brilliance:23028;Fire Ward:543;Frost Ward:6143;Conjure Mana Emerald:27101",
    alt = "Conjure Water:5504;Conjure Food:587;Ritual of Refreshment:43987;Slow Fall:130" },
  { class = "MAGE", tab = 2, spec = { 63 }, role = "DAMAGER", key = "fire",
    main = "Fireball:133;Scorch:2948;Fire Blast:2136;Flamestrike:2120;Blast Wave:11113;Dragon's Breath:31661;Arcane Explosion:1449;Blizzard:10;Frost Nova:122;Counterspell:2139;Polymorph:118;Blink:1953",
    shift = "Combustion:11129;Icy Veins:12472;Cold Snap:11958;Evocation:12051;Ice Block:45438;Invisibility:66;Mana Shield:1463;Spellsteal:30449;Remove Lesser Curse:475;Cone of Cold:120",
    ctrl = "Molten Armor:30482;Mage Armor:6117;Arcane Intellect:1459;Arcane Brilliance:23028;Fire Ward:543;Frost Ward:6143;Conjure Mana Emerald:27101",
    alt = "Conjure Water:5504;Conjure Food:587;Ritual of Refreshment:43987;Slow Fall:130" },
  { class = "MAGE", tab = 3, spec = { 64 }, role = "DAMAGER", key = "frost",
    main = "Frostbolt:116;Ice Lance:30455;Fire Blast:2136;Frost Nova:122;Cone of Cold:120;Blizzard:10;Arcane Explosion:1449;Flamestrike:2120;Counterspell:2139;Polymorph:118;Blink:1953;Ice Barrier:11426",
    shift = "Icy Veins:12472;Summon Water Elemental:31687;Cold Snap:11958;Evocation:12051;Ice Block:45438;Invisibility:66;Mana Shield:1463;Spellsteal:30449;Remove Lesser Curse:475;Frost Ward:6143",
    ctrl = "Molten Armor:30482;Ice Armor:7302;Mage Armor:6117;Arcane Intellect:1459;Arcane Brilliance:23028;Fire Ward:543;Conjure Mana Emerald:27101",
    alt = "Conjure Water:5504;Conjure Food:587;Ritual of Refreshment:43987;Slow Fall:130" },

  { class = "WARLOCK", tab = 1, spec = { 265 }, role = "DAMAGER", key = "affli",
    main = "Shadow Bolt:686;Corruption:172;Unstable Affliction:30108;Siphon Life:18265;Curse of Agony:980;Curse of Doom:603;Curse of the Elements:1490;Immolate:348;Life Tap:1454;Drain Life:689;Seed of Corruption:27243;Fear:5782",
    shift = "Amplify Curse:18288;Fel Domination:18708;Death Coil:6789;Howl of Terror:5484;Soulshatter:29858;Shadow Ward:6229;Drain Soul:1120;Hellfire:1949;Banish:710;Curse of Recklessness:704",
    ctrl = "Fel Armor:28176;Demon Armor:706;Create Healthstone:6201;Create Soulstone:693;Health Funnel:755;Ritual of Souls:29893;Ritual of Summoning:698",
    alt = "Summon Imp:688;Summon Voidwalker:697;Summon Felhunter:691;Summon Succubus:712" },
  { class = "WARLOCK", tab = 2, spec = { 266 }, role = "DAMAGER", key = "demo",
    main = "Shadow Bolt:686;Corruption:172;Immolate:348;Curse of the Elements:1490;Curse of Recklessness:704;Curse of Doom:603;Curse of Agony:980;Life Tap:1454;Searing Pain:5676;Seed of Corruption:27243;Drain Life:689;Fear:5782",
    shift = "Fel Domination:18708;Soul Link:19028;Death Coil:6789;Howl of Terror:5484;Soulshatter:29858;Shadow Ward:6229;Drain Soul:1120;Hellfire:1949;Banish:710;Enslave Demon:1098",
    ctrl = "Fel Armor:28176;Demon Armor:706;Create Healthstone:6201;Create Soulstone:693;Health Funnel:755;Ritual of Souls:29893;Ritual of Summoning:698",
    alt = "Summon Felguard:30146;Summon Imp:688;Summon Felhunter:691;Summon Succubus:712" },
  { class = "WARLOCK", tab = 3, spec = { 267 }, role = "DAMAGER", key = "destro",
    main = "Shadow Bolt:686;Incinerate:29722;Immolate:348;Conflagrate:17962;Shadowburn:17877;Curse of the Elements:1490;Curse of Doom:603;Corruption:172;Life Tap:1454;Searing Pain:5676;Seed of Corruption:27243;Fear:5782",
    shift = "Shadowfury:30283;Fel Domination:18708;Death Coil:6789;Howl of Terror:5484;Soulshatter:29858;Shadow Ward:6229;Drain Soul:1120;Hellfire:1949;Rain of Fire:5740;Banish:710",
    ctrl = "Fel Armor:28176;Demon Armor:706;Create Healthstone:6201;Create Soulstone:693;Health Funnel:755;Ritual of Souls:29893;Ritual of Summoning:698",
    alt = "Summon Imp:688;Summon Voidwalker:697;Summon Felhunter:691;Summon Succubus:712" },

  -- Druid: bar 73 = Cat Form, bar 97 = Bear Form, bar 109 = Moonkin Form.
  { class = "DRUID", tab = 1, spec = { 102 }, role = "DAMAGER", key = "balance",
    main = "Starfire:2912;Wrath:5176;Moonfire:8921;Insect Swarm:5570;Faerie Fire:770;Hurricane:16914;Entangling Roots:339;Cyclone:33786;Hibernate:2637;Remove Curse:2782;Abolish Poison:2893;Moonkin Form:24858",
    stance4 = "Starfire:2912;Wrath:5176;Moonfire:8921;Insect Swarm:5570;Faerie Fire:770;Hurricane:16914;Entangling Roots:339;Cyclone:33786;Hibernate:2637;Remove Curse:2782;Abolish Poison:2893;Moonkin Form:24858",
    shift = "Force of Nature:33831;Innervate:29166;Barkskin:22812;Nature's Swiftness:17116;Tranquility:740;Rebirth:20484;Nature's Grasp:16689;Dash:1850",
    ctrl = "Mark of the Wild:1126;Gift of the Wild:21849;Thorns:467;Healing Touch:5185;Regrowth:8936;Rejuvenation:774;Lifebloom:33763",
    alt = "Bear Form:5487;Dire Bear Form:9634;Cat Form:768;Travel Form:783" },
  { class = "DRUID", tab = 2, spec = { 103 }, role = "DAMAGER", key = "cat",
    main = "Cat Form:768;Dire Bear Form:9634;Bear Form:5487;Travel Form:783;Faerie Fire:770;Entangling Roots:339;Cyclone:33786;Regrowth:8936;Rejuvenation:774;Healing Touch:5185;Remove Curse:2782;Abolish Poison:2893",
    stance1 = "Mangle (Cat):33876;Shred:5221;Rip:1079;Ferocious Bite:22568;Rake:1822;Claw:1082;Faerie Fire (Feral):16857;Tiger's Fury:5217;Cower:8998;Prowl:5215;Ravage:6785;Pounce:9005",
    stance3 = "Mangle (Bear):33878;Lacerate:33745;Maul:6807;Swipe:779;Faerie Fire (Feral):16857;Growl:6795;Demoralizing Roar:99;Bash:5211;Feral Charge:16979;Enrage:5229;Frenzied Regeneration:22842;Challenging Roar:5209",
    shift = "Innervate:29166;Barkskin:22812;Dash:1850;Rebirth:20484;Tranquility:740;Nature's Grasp:16689;Hibernate:2637;Soothe Animal:2908",
    ctrl = "Mark of the Wild:1126;Gift of the Wild:21849;Thorns:467;Omen of Clarity:16864;Lifebloom:33763;Moonfire:8921;Wrath:5176" },
  { class = "DRUID", tab = 2, spec = { 104 }, role = "TANK", key = "bear",
    main = "Dire Bear Form:9634;Bear Form:5487;Cat Form:768;Travel Form:783;Faerie Fire:770;Entangling Roots:339;Cyclone:33786;Regrowth:8936;Rejuvenation:774;Healing Touch:5185;Remove Curse:2782;Abolish Poison:2893",
    stance3 = "Mangle (Bear):33878;Lacerate:33745;Maul:6807;Swipe:779;Faerie Fire (Feral):16857;Growl:6795;Demoralizing Roar:99;Bash:5211;Feral Charge:16979;Enrage:5229;Frenzied Regeneration:22842;Challenging Roar:5209",
    stance1 = "Mangle (Cat):33876;Shred:5221;Rip:1079;Ferocious Bite:22568;Rake:1822;Claw:1082;Faerie Fire (Feral):16857;Tiger's Fury:5217;Cower:8998;Prowl:5215;Ravage:6785;Pounce:9005",
    shift = "Barkskin:22812;Innervate:29166;Dash:1850;Rebirth:20484;Tranquility:740;Nature's Grasp:16689;Hibernate:2637;Soothe Animal:2908",
    ctrl = "Mark of the Wild:1126;Gift of the Wild:21849;Thorns:467;Omen of Clarity:16864;Lifebloom:33763;Moonfire:8921;Wrath:5176" },
  { class = "DRUID", tab = 3, spec = { 105 }, role = "HEALER", key = "resto",
    main = "Lifebloom:33763;Rejuvenation:774;Regrowth:8936;Healing Touch:5185;Swiftmend:18562;Remove Curse:2782;Abolish Poison:2893;Moonfire:8921;Wrath:5176;Entangling Roots:339;Cyclone:33786;Tree of Life:33891",
    shift = "Nature's Swiftness:17116;Innervate:29166;Tranquility:740;Barkskin:22812;Rebirth:20484;Nature's Grasp:16689;Hibernate:2637;Dash:1850",
    ctrl = "Mark of the Wild:1126;Gift of the Wild:21849;Thorns:467;Omen of Clarity:16864;Faerie Fire:770;Travel Form:783;Cat Form:768",
    alt = "Bear Form:5487;Dire Bear Form:9634;Moonkin Form:24858;Soothe Animal:2908" },
}
P.SPECS = SPECS

local function parse(str)
  local out = {}
  for entry in (str or ""):gmatch("[^;]+") do
    local name, id = entry:match("^(.-):(%d+)$")
    if name then out[#out + 1] = { name = name, id = tonumber(id) } end
  end
  return out
end
P.Parse = parse

-- Localized spell name for an ID (any rank of a spell returns the same name).
local function spellName(id, fallback)
  local n
  if C_Spell and C_Spell.GetSpellName then
    local ok, v = pcall(C_Spell.GetSpellName, id); if ok then n = v end
  end
  if not n and GetSpellInfo then
    local ok, v = pcall(GetSpellInfo, id); if ok and type(v) == "string" then n = v end
  end
  return n or fallback
end
P.SpellName = spellName

local BARS = { "main", "shift", "ctrl", "alt", "stance1", "stance2", "stance3", "stance4" }

-- Builds the import data at runtime, so spell names match the client language.
function P.BuildSpec(s)
  local actions = {}
  local lists = {}
  for _, bar in ipairs(BARS) do lists[bar] = s[bar] and parse(s[bar]) end
  if s.stances then for _, st in ipairs(s.stances) do lists[st] = lists[st] or lists.main end end
  for _, bar in ipairs(BARS) do
    local list = lists[bar]
    if list then
      for i, sp in ipairs(list) do
        if i > LIMIT[bar] then break end
        -- No ID: placing by name lets the game pick the highest known rank.
        actions[P.SLOTS[bar] + i - 1] = { t = "s", n = spellName(sp.id, sp.name), en = sp.name }
      end
    end
  end
  return { v = 1, layout = "us", meta = { role = s.role, class = s.class, preset = s.key }, binds = roleBinds(s.role), actions = actions }
end

local function specPreset(s)
  local p = { id = "spec_" .. s.class .. "_" .. s.key, class = s.class, role = s.role, spec = s, sections = { binds = true, bars = true } }
  return setmetatable(p, { __index = function(t, k)
    if k == "data" then local d = P.BuildSpec(s); return d end
  end })
end

P.list = {
  { id = "role_TANK", role = "TANK", nameKey = "ROLE_TANK", data = rolePreset("TANK"), sections = { binds = true } },
  { id = "role_HEALER", role = "HEALER", nameKey = "ROLE_HEALER", data = rolePreset("HEALER"), sections = { binds = true } },
  { id = "role_DAMAGER", role = "DAMAGER", nameKey = "ROLE_DPS", data = rolePreset("DAMAGER"), sections = { binds = true } },
}
P.spec = {}
for _, s in ipairs(SPECS) do P.spec[#P.spec + 1] = specPreset(s) end

function P.ForRole(role)
  for _, p in ipairs(P.list) do if p.role == role then return p end end
end

function P.ForClass(class)
  local out = {}
  for _, p in ipairs(P.spec) do if p.class == class then out[#out + 1] = p end end
  return out
end

-- Index of the current spec: talent tree index on Classic clients ("WARRIOR-2"),
-- specialization ID on modern clients.
local function matches(s, info)
  if not info or s.class ~= info.class then return false end
  local id = info.specID
  if type(id) == "number" then
    for _, v in ipairs(s.spec) do if v == id then return true end end
    return false
  elseif type(id) == "string" then
    return tonumber(id:match("%-(%d+)$")) == s.tab
  end
  return false
end

-- Best class preset for a spec and role: same spec first, then any spec of that role.
function P.ForSpec(info, role)
  if not info then return nil end
  local fallback
  for _, p in ipairs(P.spec) do
    local s = p.spec
    if s.class == info.class and (not role or s.role == role) then
      if matches(s, info) then return p end
      fallback = fallback or p
    end
  end
  return fallback
end

local CLASS_NAMES = { WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
  SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid" }
local SPEC_NAMES = { arms = "Arms", fury = "Fury", prot = "Protection", holy = "Holy", ret = "Retribution",
  bm = "Beast Mastery", mm = "Marksmanship", sv = "Survival", assa = "Assassination", combat = "Combat", sub = "Subtlety",
  disc = "Discipline", shadow = "Shadow", ele = "Elemental", enh = "Enhancement", resto = "Restoration",
  arcane = "Arcane", fire = "Fire", frost = "Frost", affli = "Affliction", demo = "Demonology", destro = "Destruction",
  balance = "Balance", cat = "Feral", bear = "Feral" }

-- Spec name in the client language: specialization API on modern clients, the talent
-- tree name on Classic clients (only for the player's own class), English otherwise.
local function specName(s)
  if GetSpecializationInfoByID and s.spec[1] then
    local ok, _, name = pcall(GetSpecializationInfoByID, s.spec[1])
    if ok and type(name) == "string" and name ~= "" and s.key ~= "cat" and s.key ~= "bear" then return name end
  end
  if GetTalentTabInfo and UnitClass and select(2, UnitClass("player")) == s.class then
    local ok, a, b = pcall(GetTalentTabInfo, s.tab)
    local n = ok and (type(a) == "string" and a or (type(b) == "string" and b)) or nil
    if n and n ~= "" and s.key ~= "cat" and s.key ~= "bear" then return n end
    if n and n ~= "" then return n .. " (" .. (s.role == "TANK" and ns.L.ROLE_TANK or ns.L.ROLE_DPS) .. ")" end
  end
  local n = SPEC_NAMES[s.key] or s.key
  if s.key == "cat" or s.key == "bear" then n = n .. " (" .. (s.role == "TANK" and ns.L.ROLE_TANK or ns.L.ROLE_DPS) .. ")" end
  return n
end

function P.Name(p)
  if p.spec then
    local cls = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[p.class]) or CLASS_NAMES[p.class] or p.class
    return cls .. " · " .. specName(p.spec)
  end
  return p.name or (ns.L[p.nameKey] .. " – " .. ns.L.ROLE_SUB)
end

-- Spells of a preset the current character does not know (yet).
function P.Missing(p)
  local missing, total, seen = {}, 0, {}
  for _, bar in ipairs(BARS) do
    for _, sp in ipairs(parse(p.spec[bar])) do
      if not seen[sp.name] then
        seen[sp.name] = true
        total = total + 1
        local n = spellName(sp.id, sp.name)
        if not ns.Data.BookSpell(n) then missing[#missing + 1] = n end
      end
    end
  end
  return missing, total
end
