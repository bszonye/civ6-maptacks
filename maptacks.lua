-- ===========================================================================
-- MapTacks
-- utility functions

ICON_MAP_PIN_UNKNOWN = "ICON_CIVILIZATION_UNKNOWN";

local g_debugLeader = nil;
-- g_debugLeader = GameInfo.Leaders.LEADER_BARBAROSSA
-- g_debugLeader = GameInfo.Leaders.LEADER_CATHERINE_DE_MEDICI
-- g_debugLeader = GameInfo.Leaders.LEADER_CLEOPATRA
-- g_debugLeader = GameInfo.Leaders.LEADER_GANDHI
-- g_debugLeader = GameInfo.Leaders.LEADER_GILGAMESH
-- g_debugLeader = GameInfo.Leaders.LEADER_GORGO
-- g_debugLeader = GameInfo.Leaders.LEADER_HARDRADA
-- g_debugLeader = GameInfo.Leaders.LEADER_HOJO
-- g_debugLeader = GameInfo.Leaders.LEADER_MVEMBA
-- g_debugLeader = GameInfo.Leaders.LEADER_PEDRO
-- g_debugLeader = GameInfo.Leaders.LEADER_PERICLES
-- g_debugLeader = GameInfo.Leaders.LEADER_PETER_GREAT
-- g_debugLeader = GameInfo.Leaders.LEADER_PHILIP_II
-- g_debugLeader = GameInfo.Leaders.LEADER_QIN
-- g_debugLeader = GameInfo.Leaders.LEADER_SALADIN
-- g_debugLeader = GameInfo.Leaders.LEADER_TOMYRIS
-- g_debugLeader = GameInfo.Leaders.LEADER_TRAJAN
-- g_debugLeader = GameInfo.Leaders.LEADER_T_ROOSEVELT
-- g_debugLeader = GameInfo.Leaders.LEADER_VICTORIA
-- g_debugLeader = GameInfo.Leaders.LEADER_JOHN_CURTIN
-- g_debugLeader = GameInfo.Leaders.LEADER_MONTEZUMA
-- g_debugLeader = GameInfo.Leaders.LEADER_ALEXANDER
-- g_debugLeader = GameInfo.Leaders.LEADER_CYRUS
-- g_debugLeader = GameInfo.Leaders.LEADER_AMANITORE
-- g_debugLeader = GameInfo.Leaders.LEADER_JADWIGA

-- ===========================================================================
local g_stockIcons = {
	{ name="ICON_MAP_PIN_STRENGTH" },
	{ name="ICON_MAP_PIN_RANGED"   },
	{ name="ICON_MAP_PIN_BOMBARD"  },
	{ name="ICON_MAP_PIN_DISTRICT" },
	{ name="ICON_MAP_PIN_CHARGES"  },
	{ name="ICON_MAP_PIN_DEFENSE"  },
	{ name="ICON_MAP_PIN_MOVEMENT" },
	{ name="ICON_MAP_PIN_NO"       },
	{ name="ICON_MAP_PIN_PLUS"     },
	{ name="ICON_MAP_PIN_CIRCLE"   },
	{ name="ICON_MAP_PIN_TRIANGLE" },
	{ name="ICON_MAP_PIN_SUN"      },
	{ name="ICON_MAP_PIN_SQUARE"   },
	{ name="ICON_MAP_PIN_DIAMOND"  },
};
local g_builderOps = {
	GameInfo.UnitOperations.UNITOPERATION_PLANT_FOREST,
	GameInfo.UnitOperations.UNITOPERATION_REMOVE_FEATURE,
	GameInfo.UnitOperations.UNITOPERATION_HARVEST_RESOURCE,
};
local g_engineerOps = {
	GameInfo.UnitOperations.UNITOPERATION_BUILD_ROUTE,
	GameInfo.UnitOperations.UNITOPERATION_CLEAR_CONTAMINATION,
	GameInfo.UnitOperations.UNITOPERATION_REPAIR,
};
local g_gsIcons = {
	-- TODO: fit this in somewhere
	GameInfo.UnitOperations.UNITOPERATION_TOURISM_BOMB,
};
local g_miscIcons = {
	{
		Icon="ICON_NOTIFICATION_BARBARIANS_SIGHTED",
		Description="LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME",
	},
	{
		Icon="ICON_NOTIFICATION_DISCOVER_GOODY_HUT",
		Description="LOC_IMPROVEMENT_GOODY_HUT_NAME",
	},
	{
		Icon="ICON_UNITOPERATION_SPY_COUNTERSPY_ACTION",
		-- Description="LOC_UNIT_SPY_NAME",
		Description="LOC_PROMOTION_CLASS_SPY_NAME",
	},
	-- Unit operations --------------------------------------------------------
	-- ATTACK:
	-- GameInfo.UnitOperations.UNITOPERATION_AIR_ATTACK,
	-- GameInfo.UnitOperations.UNITOPERATION_WMD_STRIKE,
	-- GameInfo.UnitOperations.UNITOPERATION_COASTAL_RAID,
	GameInfo.UnitOperations.UNITOPERATION_PILLAGE,
	-- GameInfo.UnitOperations.UNITOPERATION_PILLAGE_ROUTE,
	-- GameInfo.UnitOperations.UNITOPERATION_RANGE_ATTACK,
	-- BUILD:
	-- GameInfo.UnitOperations.UNITOPERATION_BUILD_IMPROVEMENT,
	-- GameInfo.UnitOperations.UNITOPERATION_BUILD_ROUTE,
	GameInfo.UnitOperations.UNITOPERATION_DESIGNATE_PARK,
	-- GameInfo.UnitOperations.UNITOPERATION_PLANT_FOREST,
	-- GameInfo.UnitOperations.UNITOPERATION_REMOVE_FEATURE,
	-- GameInfo.UnitOperations.UNITOPERATION_REMOVE_IMPROVEMENT,
	-- INPLACE:
	-- GameInfo.UnitOperations.UNITOPERATION_FORTIFY,
	-- GameInfo.UnitOperations.UNITOPERATION_HEAL,
	-- GameInfo.UnitOperations.UNITOPERATION_REST_REPAIR,
	-- GameInfo.UnitOperations.UNITOPERATION_SKIP_TURN,
	-- GameInfo.UnitOperations.UNITOPERATION_SLEEP,
	-- GameInfo.UnitOperations.UNITOPERATION_ALERT,
	-- MOVE:
	-- GameInfo.UnitOperations.UNITOPERATION_DEPLOY,
	-- GameInfo.UnitOperations.UNITOPERATION_DISEMBARK,  -- not VisibleInUI
	-- GameInfo.UnitOperations.UNITOPERATION_EMBARK,  -- not VisibleInUI
	-- GameInfo.UnitOperations.UNITOPERATION_MOVE_TO,
	-- GameInfo.UnitOperations.UNITOPERATION_MOVE_TO_UNIT,  -- not VisibleInUI
	-- GameInfo.UnitOperations.UNITOPERATION_REBASE,
	-- GameInfo.UnitOperations.UNITOPERATION_ROUTE_TO,  -- not VisibleInUI
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_COUNTERSPY,  -- special handling in unit panel
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_TRAVEL_NEW_CITY,
	-- GameInfo.UnitOperations.UNITOPERATION_TELEPORT_TO_CITY,
	-- OFFENSIVESPY:  -- these do not appear in unit panel
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_DISRUPT_ROCKETRY,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_GAIN_SOURCES,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_GREAT_WORK_HEIST,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_LISTENING_POST,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_RECRUIT_PARTISANS,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_SABOTAGE_PRODUCTION,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_SIPHON_FUNDS,
	-- GameInfo.UnitOperations.UNITOPERATION_SPY_STEAL_TECH_BOOST,
	-- SECONDARY:
	-- GameInfo.UnitOperations.UNITOPERATION_AUTOMATE_EXPLORE,
	-- SPECIFIC:
	-- GameInfo.UnitOperations.UNITOPERATION_CLEAR_CONTAMINATION,
	-- GameInfo.UnitOperations.UNITOPERATION_CONVERT_BARBARIANS,
	-- GameInfo.UnitOperations.UNITOPERATION_EVANGELIZE_BELIEF,
	GameInfo.UnitOperations.UNITOPERATION_EXCAVATE,
	-- GameInfo.UnitOperations.UNITOPERATION_FOUND_CITY,
	-- GameInfo.UnitOperations.UNITOPERATION_FOUND_RELIGION,
	-- GameInfo.UnitOperations.UNITOPERATION_HARVEST_RESOURCE,
	-- GameInfo.UnitOperations.UNITOPERATION_LAUNCH_INQUISITION,
	GameInfo.UnitOperations.UNITOPERATION_MAKE_TRADE_ROUTE,
	-- GameInfo.UnitOperations.UNITOPERATION_REMOVE_HERESY,
	-- GameInfo.UnitOperations.UNITOPERATION_REPAIR,
	-- GameInfo.UnitOperations.UNITOPERATION_REPAIR_ROUTE,
	-- GameInfo.UnitOperations.UNITOPERATION_RETRAIN,
	-- GameInfo.UnitOperations.UNITOPERATION_SPREAD_RELIGION,
	-- GameInfo.UnitOperations.UNITOPERATION_SWAP_UNITS,  -- not VisibleInUI
	-- GameInfo.UnitOperations.UNITOPERATION_UPGRADE,
	-- GameInfo.UnitOperations.UNITOPERATION_WAIT_FOR,  -- not VisibleInUI
	-- Unit commands ----------------------------------------------------------
	-- INPLACE:
	-- GameInfo.UnitCommands.UNITCOMMAND_WAKE,
	-- GameInfo.UnitCommands.UNITCOMMAND_CANCEL,
	-- GameInfo.UnitCommands.UNITCOMMAND_STOP_AUTOMATION,
	-- GameInfo.UnitCommands.UNITCOMMAND_GIFT,
	-- MOVE:
	-- GameInfo.UnitCommands.UNITCOMMAND_AIRLIFT,
	-- SECONDARY:
	-- GameInfo.UnitCommands.UNITCOMMAND_DELETE,
	-- SPECIFIC:
	-- GameInfo.UnitCommands.UNITCOMMAND_PROMOTE,
	-- GameInfo.UnitCommands.UNITCOMMAND_UPGRADE,
	-- GameInfo.UnitCommands.UNITCOMMAND_AUTOMATE,  -- not VisibleInUI
	-- GameInfo.UnitCommands.UNITCOMMAND_ENTER_FORMATION,
	-- GameInfo.UnitCommands.UNITCOMMAND_EXIT_FORMATION,
	-- GameInfo.UnitCommands.UNITCOMMAND_ACTIVATE_GREAT_PERSON,
	-- GameInfo.UnitCommands.UNITCOMMAND_DISTRICT_PRODUCTION,
	-- GameInfo.UnitCommands.UNITCOMMAND_FORM_CORPS,
	GameInfo.UnitCommands.UNITCOMMAND_FORM_ARMY,
	-- GameInfo.UnitCommands.UNITCOMMAND_PLUNDER_TRADE_ROUTE,
	-- GameInfo.UnitCommands.UNITCOMMAND_NAME_UNIT,
	-- GameInfo.UnitCommands.UNITCOMMAND_WONDER_PRODUCTION,
	-- GameInfo.UnitCommands.UNITCOMMAND_HARVEST_WONDER,
};

-- ===========================================================================
-- Timeline value based on tech/civic cost
function MapTacksTimeline(a)
	local techCost = 0;
	if a.PrereqTech ~= nil then
		tech = GameInfo.Technologies[a.PrereqTech];
		techCost = tech.Cost;
	end
	local civicCost = 0;
	if a.PrereqCivic ~= nil then
		civic = GameInfo.Civics[a.PrereqCivic];
		civicCost = civic.Cost;
	end
	local cost = math.max(techCost, civicCost);
	return cost;
end

function MapTacksTechCivicSort(a, b)
	local atime = MapTacksTimeline(a);
	local btime = MapTacksTimeline(b);
	-- primary sort: tech/civic timeline
	if atime ~= btime then
		return atime < btime;
	end
	-- secondary sort: build cost
	acost = a.Cost or 0;
	bcost = b.Cost or 0;
	if acost ~= bcost then
		return acost < bcost;
	end
	-- tertiary sort: localized icon name
	aname = Locale.Lookup(a.Name);
	bname = Locale.Lookup(b.Name);
	return Locale.Compare(aname, bname) == -1;
end

-- ===========================================================================
-- Build the grid of map pin icon options
function MapTacksIconOptions(stockIcons : table)
	local icons = {};
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];

	local leader = GameInfo.Leaders[pPlayerCfg:GetLeaderTypeID()];
	if g_debugLeader then leader = g_debugLeader; end
	local civ = leader.CivilizationCollection[1];
	-- print(civ.CivilizationType);

	-- Get unique traits for the player civilization
	local traits = {};
	for i, item in ipairs(leader.TraitCollection) do
		traits[item.TraitType] = true;
		-- print(item.TraitType);
	end
	for i, item in ipairs(civ.TraitCollection) do
		traits[item.TraitType] = true;
		-- print(item.TraitType);
	end

	-- Stock map pins
	local stockSection = {};
	for i, item in ipairs(stockIcons or g_stockIcons) do
		table.insert(stockSection, item);
	end

	-- Districts
	local skip_district = {};  -- we will skip all districts in this set
	for item in GameInfo.Districts() do
		local itype = item.DistrictType;
		local trait = item.TraitType;
		if itype == "DISTRICT_WONDER" then
			-- this goes in the wonders section instead
			skip_district[itype] = itype
		elseif traits[trait] then
			-- unique district for our civ
			-- mark any districts replaced by this one
			for i, swap in ipairs(item.ReplacesCollection) do
				local base = swap.ReplacesDistrictType;
				skip_district[base] = itype;
			end
		elseif trait then
			-- unique district for another civ
			skip_district[itype] = trait;
		end
	end
	local districtIcons = {};
	for item in GameInfo.Districts() do
		if not skip_district[item.DistrictType] then
			-- our civ does not have this district
			table.insert(districtIcons, item);
		end
	end

	-- Improvements
	local builderIcons = {};
	local uniqueIcons = {};
	local governorIcons = {};
	local minorCivIcons = {};
	local engineerIcons = {};
	for item in GameInfo.Improvements() do
		-- does this improvement have a valid build unit?
		local units = item.ValidBuildUnits;
		if #units ~= 0 then
			local entry = MapTacksIcon(item);
			local unit = GameInfo.Units[units[1].UnitType];
			local trait = item.TraitType or unit.TraitType;
			-- print(valid.UnitType, trait);
			if trait then
				-- print(trait);
				if traits[trait] then
					-- separate unique improvements
					table.insert(uniqueIcons, item);
				elseif trait == "TRAIT_CIVILIZATION_NO_PLAYER" then
					-- governor improvements
					table.insert(governorIcons, item);
				elseif trait:sub(1, 10) == "MINOR_CIV_" then
					table.insert(minorCivIcons, item);
				end
			elseif unit.UnitType == "UNIT_BUILDER" then
				table.insert(builderIcons, item);
			else
				table.insert(engineerIcons, item);
			end
			-- print(item.Name, MapTacksTimeline(item));
		end
	end

	-- sort icons according to tech cost
	table.sort(districtIcons, MapTacksTechCivicSort);
	table.sort(builderIcons, MapTacksTechCivicSort);
	table.sort(uniqueIcons, MapTacksTechCivicSort);
	table.sort(governorIcons, MapTacksTechCivicSort);
	table.sort(minorCivIcons, MapTacksTechCivicSort);
	table.sort(engineerIcons, MapTacksTechCivicSort);

	local districtSection = {};
	for i,v in ipairs(districtIcons) do table.insert(districtSection, MapTacksIcon(v)); end
	local builderSection = {};
	for i,v in ipairs(builderIcons) do table.insert(builderSection, MapTacksIcon(v)); end
	local uniqueSection = {
		-- TODO: find a better place for this
		MapTacksIcon(GameInfo.UnitOperations.UNITOPERATION_BUILD_IMPROVEMENT),
	};
	for i,v in ipairs(uniqueIcons) do table.insert(uniqueSection, MapTacksIcon(v)); end
	for i,v in ipairs(governorIcons) do table.insert(uniqueSection, MapTacksIcon(v)); end
	for i,v in ipairs(minorCivIcons) do table.insert(uniqueSection, MapTacksIcon(v)); end
	for i,v in ipairs(engineerIcons) do table.insert(uniqueSection, MapTacksIcon(v)); end

	local buildopSection = {};
	for i,v in ipairs(g_engineerOps) do table.insert(buildopSection, MapTacksIcon(v)); end
	for i,v in ipairs(g_builderOps) do table.insert(buildopSection, MapTacksIcon(v)); end

	local miscSection = {};
	for i,v in ipairs(g_gsIcons) do table.insert(miscSection, MapTacksIcon(v)); end
	for i,v in ipairs(g_miscIcons) do table.insert(miscSection, MapTacksIcon(v)); end

	-- Great people
	local peopleSection = {};
	table.insert(peopleSection, MapTacksIcon(GameInfo.UnitCommands.UNITCOMMAND_ACTIVATE_GREAT_PERSON));
	for item in GameInfo.GreatPersonClasses() do
		table.insert(peopleSection, MapTacksIcon(item));
	end

	-- Wonders
	local wonderSection = {};
	local wonderIcons = { GameInfo.Districts.DISTRICT_WONDER, };
	for item in GameInfo.Buildings() do
		if item.IsWonder then
			table.insert(wonderIcons, item);
		end
	end
	table.sort(wonderIcons, MapTacksTechCivicSort);
	for i,v in ipairs(wonderIcons) do table.insert(wonderSection, MapTacksIcon(v)); end

	table.insert(icons, districtSection);
	table.insert(icons, builderSection);
	table.insert(icons, uniqueSection);
	table.insert(icons, buildopSection);
	table.insert(icons, miscSection);
	table.insert(icons, peopleSection);
	table.insert(icons, stockSection);
	table.insert(icons, wonderSection);

	return icons;
end

-- ===========================================================================
-- Given a GameInfo object, determine its icon and tooltip
function MapTacksIcon(item)
	local name :string = nil;
	local tooltip :string = nil;
	if item.GreatPersonClassType then  -- this must come before districts
		name = item.ActionIcon;
		tooltip = item.Name;
	elseif item.DistrictType then  -- because great people have district types
		name = "ICON_"..item.DistrictType;
		if item.CityCenter or item.InternalOnly then
			tooltip = item.Name
		else
			tooltip = item.DistrictType;
		end
	elseif item.BuildingType then
		name = "ICON_"..item.BuildingType;
		tooltip = item.BuildingType;
	elseif item.ImprovementType then
		name = item.Icon;
		tooltip = item.ImprovementType;
	elseif item.NotificationType then
		name = "ICON_"..item.NotificationType;
		tooltip = item.Message;
	elseif item.UnitType then
		name = "ICON_"..item.UnitType;
		tooltip = item.Name;
	else
		name = item.Icon;
		tooltip = item.Description;
	end
	return { name=name, tooltip=tooltip };
end

-- ===========================================================================
-- Given an icon name, determine its color and size profile
MAPTACKS_STOCK = 0;  -- stock icons
MAPTACKS_WHITE = 1;  -- white icons (units, spy ops)
MAPTACKS_GRAY = 2;   -- gray shaded icons (improvements, commands)
MAPTACKS_COLOR = 3;  -- full color icons (districts, wonders)
function MapTacksType(pin : table)
	if not pin then return nil; end
	local iconName = pin:GetIconName();
	if iconName:sub(1,5) ~= "ICON_" then return nil; end
	local iconType = iconName:sub(6, 10);
	if iconType == "MAP_P" then
		return MAPTACKS_STOCK;
	elseif iconType == "UNIT_" then
		return MAPTACKS_WHITE;
	elseif iconType == "DISTR" then
		return MAPTACKS_COLOR;
	elseif iconType == "BUILD" then  -- wonders
		return MAPTACKS_COLOR;
	else
		return MAPTACKS_GRAY;
	end
end

-- ===========================================================================
-- Get player colors (with debug override)
function MapTacksColors(playerID : number)
	local primaryColor, secondaryColor = UI.GetPlayerColors(playerID);
	if g_debugLeader then
		local colors = GameInfo.PlayerColors[g_debugLeader.Hash];
		primaryColor = UI.GetColorValue(colors.PrimaryColor);
		secondaryColor = UI.GetColorValue(colors.SecondaryColor);
	end
	return primaryColor, secondaryColor;
end

-- ===========================================================================
-- Calculate icon tint color
-- Icons generally have light=224, shadow=112 (out of 255).
-- So, to match icons to civ colors, ideally brighten the original color:
-- by 255/224 to match light areas, or by 255/112 to match shadows.
--
-- In practice:
-- Light colors look best as bright as possible without distortion.
-- The darkest colors need shadow=56, light=112, max=128 for legibility.
-- Other colors look good around 1.5-1.8x brightness, matching midtones.
local g_tintCache = {};
function MapTacksIconTint( abgr : number, debug : number )
	if g_tintCache[abgr] ~= nil then return g_tintCache[abgr]; end
	local r = abgr % 256;
	local g = math.floor(abgr / 256) % 256;
	local b = math.floor(abgr / 65536) % 256;
	local max = math.max(r, g, b, 1);  -- avoid division by zero
	local light = 255/max;  -- maximum brightness without distortion
	local dark = 128/max;  -- minimum brightness
	local x = 1.6;  -- match midtones
	if light < x then x = light; elseif x < dark then x = dark; end

	-- sRGB luma
	-- local v = 0.2126 * r + 0.7152 * g + 0.0722 * b;
	-- print(string.format("m%d r%d g%d b%d", max, r, g, b));
	-- print(string.format("%0.3f %0.3f", x, 255/max));
	r = math.min(255, math.floor(x * r + 0.5));
	g = math.min(255, math.floor(x * g + 0.5));
	b = math.min(255, math.floor(x * b + 0.5));
	local tint = ((-256 + b) * 256 + g) * 256 + r;
	g_tintCache[abgr] = tint;
	-- print(string.format("saved %d = tint %d", abgr, tint));
	return tint;
end

-- ===========================================================================
-- Simpler version of DarkenLightenColor
function MapTacksTint( abgr : number, tint : number )
	local r = abgr % 256;
	local g = math.floor(abgr / 256) % 256;
	local b = math.floor(abgr / 65536) % 256;
	r = math.min(math.max(0, r + tint), 255);
	g = math.min(math.max(0, g + tint), 255);
	b = math.min(math.max(0, b + tint), 255);
	return ((-256 + b) * 256 + g) * 256 + r;
end

-- ===========================================================================
-- XXX: Create a test pattern of icons on the map
function MapTacksTestPattern()
	print("MapTacksTestPattern: start");
	local iW, iH = Map.GetGridSize();
	items = MapTacksIconOptions();
	for i, item in ipairs(items) do
		local x = ((i-1) % 15 - 7) % iW;
		local y = 4 - math.floor((i-1) / 15);
		MapTacksTestPin(x, y, item);
	end
	Network.BroadcastPlayerInfo();
	UI.PlaySound("Map_Pin_Add");
	print("MapTacksTestPattern: end");
end

function MapTacksTestPin(x, y, item)
	local name = item and item.name;
	print(string.format("%d %d %s", x, y, tostring(name)));
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local pMapPin = pPlayerCfg:GetMapPin(x, y);
	pMapPin:SetName("");
	pMapPin:SetIconName(name);
	pMapPin:SetVisibility(ChatTargetTypes.CHATTARGET_ALL);
	pPlayerCfg:GetMapPins();
end

-- ===========================================================================
-- Reference info

-- COMMANDS -------------------------------------------------------------------
-- ATTACK:
--   UNITCOMMAND_PRIORITY_TARGET  -- Rise & Fall
-- INPLACE:
--   UNITCOMMAND_WAKE
--   UNITCOMMAND_CANCEL
--   UNITCOMMAND_STOP_AUTOMATION
--   UNITCOMMAND_GIFT
-- MOVE:
--   UNITCOMMAND_AIRLIFT
--   UNITCOMMAND_PARADROP  -- Rise & Fall
--   UNITCOMMAND_MOVE_JUMP  -- Gathering Storm
-- SECONDARY:
--   UNITCOMMAND_DELETE
-- SPECIFIC:
--   UNITCOMMAND_PROMOTE
--   UNITCOMMAND_UPGRADE
--   UNITCOMMAND_ENTER_FORMATION
--   UNITCOMMAND_EXIT_FORMATION
--   UNITCOMMAND_ACTIVATE_GREAT_PERSON
--   UNITCOMMAND_DISTRICT_PRODUCTION
--   UNITCOMMAND_FORM_CORPS
--   UNITCOMMAND_FORM_ARMY
--   UNITCOMMAND_PLUNDER_TRADE_ROUTE
--   UNITCOMMAND_CONDEMN_HERETIC
--   UNITCOMMAND_NAME_UNIT
--   UNITCOMMAND_WONDER_PRODUCTION
--   UNITCOMMAND_HARVEST_WONDER
--   UNITCOMMAND_PROJECT_PRODUCTION  -- Rise & Fall
--
-- OPERATIONS -----------------------------------------------------------------
-- ATTACK:
--   UNITOPERATION_AIR_ATTACK
--   UNITOPERATION_WMD_STRIKE
--   UNITOPERATION_COASTAL_RAID
--   UNITOPERATION_PILLAGE
--   UNITOPERATION_PILLAGE_ROUTE
--   UNITOPERATION_RANGE_ATTACK
-- BUILD:
--   UNITOPERATION_BUILD_IMPROVEMENT
--   UNITOPERATION_BUILD_ROUTE
--   UNITOPERATION_DESIGNATE_PARK
--   UNITOPERATION_PLANT_FOREST
--   UNITOPERATION_REMOVE_FEATURE
--   UNITOPERATION_REMOVE_IMPROVEMENT
--   UNITOPERATION_BUILD_IMPROVEMENT_ADJACENT  -- Gathering Storm
-- INPLACE:
--   UNITOPERATION_FORTIFY
--   UNITOPERATION_HEAL
--   UNITOPERATION_REST_REPAIR
--   UNITOPERATION_SKIP_TURN
--   UNITOPERATION_SLEEP
--   UNITOPERATION_ALERT
-- MOVE:
--   UNITOPERATION_DEPLOY
--   UNITOPERATION_MOVE_TO
--   UNITOPERATION_REBASE
--   UNITOPERATION_SPY_COUNTERSPY  -- special handling in unit panel
--   UNITOPERATION_SPY_TRAVEL_NEW_CITY
--   UNITOPERATION_TELEPORT_TO_CITY
-- OFFENSIVESPY:  -- these do not appear in unit panel
--   UNITOPERATION_SPY_DISRUPT_ROCKETRY
--   UNITOPERATION_SPY_GAIN_SOURCES
--   UNITOPERATION_SPY_GREAT_WORK_HEIST
--   UNITOPERATION_SPY_LISTENING_POST
--   UNITOPERATION_SPY_RECRUIT_PARTISANS
--   UNITOPERATION_SPY_SABOTAGE_PRODUCTION
--   UNITOPERATION_SPY_SIPHON_FUNDS
--   UNITOPERATION_SPY_STEAL_TECH_BOOST
--   UNITOPERATION_SPY_FABRICATE_SCANDAL  -- Rise & Fall
--   UNITOPERATION_SPY_FOMENT_UNREST  -- Rise & Fall
--   UNITOPERATION_SPY_NEUTRALIZE_GOVERNOR  -- Rise & Fall
--   UNITOPERATION_SPY_BREACH_DAM  -- Gathering Storm
-- SECONDARY:
--   UNITOPERATION_AUTOMATE_EXPLORE
-- SPECIFIC:
--   UNITOPERATION_CLEAR_CONTAMINATION
--   UNITOPERATION_CONVERT_BARBARIANS
--   UNITOPERATION_EVANGELIZE_BELIEF
--   UNITOPERATION_EXCAVATE
--   UNITOPERATION_FOUND_CITY
--   UNITOPERATION_FOUND_RELIGION
--   UNITOPERATION_HARVEST_RESOURCE
--   UNITOPERATION_LAUNCH_INQUISITION
--   UNITOPERATION_MAKE_TRADE_ROUTE
--   UNITOPERATION_REMOVE_HERESY
--   UNITOPERATION_REPAIR
--   UNITOPERATION_REPAIR_ROUTE
--   UNITOPERATION_RETRAIN
--   UNITOPERATION_SPREAD_RELIGION
--   UNITOPERATION_UPGRADE
--   UNITOPERATION_RELIGIOUS_HEAL
--   UNITOPERATION_TOURISM_BOMB  -- Gathering Storm
-- vim: sw=4 ts=4
