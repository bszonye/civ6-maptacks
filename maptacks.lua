-- ===========================================================================
-- MapTacks
-- utility functions

-- ===========================================================================
-- Global data

-- Note that this is not shared between different calling modules.
-- To get that you either need to share data through ExposedMembers:
--     ExposedMembers.MapTacks = ExposedMembers.MapTacks or {};
--     MapTacks = ExposedMembers.MapTacks;
-- or share functions through LuaEvents:
--     LuaEvents.MapTacks_Function.Add(MapTacks.Function);

MapTacks = MapTacks or {};
local MapTacks = MapTacks;  -- localize access

-- Values for MapTacks.iconTypes["ICON_NAME"]:
MapTacks.STOCK = 1;  -- stock icons
MapTacks.WHITE = 2;  -- white icons (units, spy ops)
MapTacks.GRAY = 3;   -- gray shaded icons (improvements, commands)
MapTacks.COLOR = 4;  -- full color icons (buildings, wonders)
MapTacks.HEX = 5;  -- full color icons with hex backgrounds (districts)
MapTacks.iconSizes = { 24, 26, 26, 32, 32, };

-- Other constants
MapTacks.UNKNOWN = "ICON_CIVILIZATION_UNKNOWN";

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

-- synthetic icons (not in database)
local ICON_BARBARIAN_CAMP = {
	name="ICON_NOTIFICATION_BARBARIANS_SIGHTED",
	tooltip="LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME",
};
local ICON_GOODY_HUT = {
	name="ICON_NOTIFICATION_DISCOVER_GOODY_HUT",
	tooltip="LOC_IMPROVEMENT_GOODY_HUT_NAME",
};
local ICON_SPY = {
	name="ICON_UNITOPERATION_SPY_COUNTERSPY_ACTION",
	-- tooltip="LOC_UNIT_SPY_NAME",
	tooltip="LOC_PROMOTION_CLASS_SPY_NAME",
};

-- TODO: clean up this mess
local g_buildActions = {
	-- CategoryInUI = BUILD
	GameInfo.UnitOperations.UNITOPERATION_PLANT_FOREST,  -- Conservation
	GameInfo.UnitOperations.UNITOPERATION_DESIGNATE_PARK,  -- Conservation
	GameInfo.UnitOperations.UNITOPERATION_BUILD_ROUTE,
	-- GameInfo.UnitOperations.UNITOPERATION_BUILD_IMPROVEMENT,
	-- GameInfo.UnitOperations.UNITOPERATION_REMOVE_FEATURE,
	-- GameInfo.UnitOperations.UNITOPERATION_REMOVE_IMPROVEMENT,
	-- GameInfo.UnitOperations.UNITOPERATION_BUILD_IMPROVEMENT_ADJACENT,  -- GS
};
local g_removeActions = {  -- remove, harvest, repair, clear
	-- CategoryInUI = BUILD
	GameInfo.UnitOperations.UNITOPERATION_REMOVE_FEATURE,
	-- CategoryInUI = SPECIFIC
	GameInfo.UnitOperations.UNITOPERATION_HARVEST_RESOURCE,
	GameInfo.UnitOperations.UNITOPERATION_REPAIR,
	-- GameInfo.UnitOperations.UNITOPERATION_CLEAR_CONTAMINATION,
	-- GameInfo.UnitOperations.UNITOPERATION_REPAIR_ROUTE,
};
local g_attackActions = {
	-- GameInfo.UnitOperations.UNITOPERATION_COASTAL_RAID,
	GameInfo.UnitOperations.UNITOPERATION_PILLAGE,
	-- GameInfo.UnitOperations.UNITOPERATION_PILLAGE_ROUTE,
	GameInfo.UnitOperations.UNITOPERATION_RANGE_ATTACK,
	GameInfo.UnitOperations.UNITOPERATION_AIR_ATTACK,
	GameInfo.UnitOperations.UNITOPERATION_WMD_STRIKE,
}
local g_basicIcons = {
	ICON_BARBARIAN_CAMP,
	ICON_GOODY_HUT,
	GameInfo.UnitOperations.UNITOPERATION_PILLAGE,
	-- ICON_SPY,
	-- GameInfo.Units.UNIT_TRADER,
	-- GameInfo.Units.UNIT_SPY,
	-- GameInfo.Units.UNIT_ARCHAEOLOGIST,
};
local g_miscIcons = {
	-- ICON_BARBARIAN_CAMP,
	-- ICON_GOODY_HUT,
	-- GameInfo.UnitOperations.UNITOPERATION_PILLAGE,
	GameInfo.UnitOperations.UNITOPERATION_MAKE_TRADE_ROUTE,
	ICON_SPY,
	GameInfo.UnitOperations.UNITOPERATION_EXCAVATE,
	-- GameInfo.Units.UNIT_TRADER,
	-- GameInfo.Units.UNIT_SPY,
	-- GameInfo.Units.UNIT_ARCHAEOLOGIST,
	GameInfo.UnitCommands.UNITCOMMAND_FORM_ARMY,
};

-- ===========================================================================
-- Timeline value based on tech/civic cost
function MapTacks.Timeline(a)
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

function MapTacks.TimelineSort(a, b)
	local atime = MapTacks.Timeline(a);
	local btime = MapTacks.Timeline(b);
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

function MapTacks.DescriptionSort(a, b)
	aname = Locale.Lookup(a.Description);
	bname = Locale.Lookup(b.Description);
	return Locale.Compare(aname, bname) == -1;
end

-- ===========================================================================
-- Build the grid of map pin icon options
function MapTacks.IconOptions()

	-- get player configuration
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local leader = GameInfo.Leaders[pPlayerCfg:GetLeaderTypeID()];
	local civ = leader.CivilizationCollection[1];

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
	local improvementIcons = {};
	local uniqueIcons = {};
	local governorIcons = {};
	local minorCivIcons = {};
	local engineerIcons = {};
	for item in GameInfo.Improvements() do
		-- does this improvement have a valid build unit?
		local units = item.ValidBuildUnits;
		if #units ~= 0 then
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
				table.insert(improvementIcons, item);
			else
				table.insert(engineerIcons, item);
			end
			-- print(item.Name, MapTacks.Timeline(item));
		end
	end

	-- TODO: refine this?
	-- TODO: make the variable section assignment less awful
	-- TODO: join lines if they fit in 7-9 columns combined
	local columns = math.max(#districtIcons, #improvementIcons);

	-- Stock map pins
	local stockSection = {};
	if #g_stockIcons + #g_basicIcons <= columns then
		for i,v in ipairs(g_basicIcons) do table.insert(stockSection, v); end
	end
	for i, item in ipairs(g_stockIcons) do
		table.insert(stockSection, item);
	end

	-- sort icons according to tech cost
	table.sort(districtIcons, MapTacks.TimelineSort);
	table.sort(improvementIcons, MapTacks.TimelineSort);
	table.sort(uniqueIcons, MapTacks.TimelineSort);
	table.sort(governorIcons, MapTacks.TimelineSort);
	table.sort(minorCivIcons, MapTacks.TimelineSort);
	table.sort(engineerIcons, MapTacks.TimelineSort);

	local districtSection = {};
	for i,v in ipairs(districtIcons) do table.insert(districtSection, v); end
	local improvementSection = {};
	for i,v in ipairs(improvementIcons) do table.insert(improvementSection, v); end
	-- TODO: put the repair icon on the engineer line instead
	if #improvementIcons + #g_removeActions <= columns then
		for i,v in ipairs(g_removeActions) do table.insert(improvementSection, v); end
	end
	local buildSection = {};
	-- TODO: add spacers if < 2 unique improvements
	for i,v in ipairs(uniqueIcons) do table.insert(buildSection, v); end
	for i,v in ipairs(governorIcons) do table.insert(buildSection, v); end
	for i,v in ipairs(minorCivIcons) do table.insert(buildSection, v); end
	for i,v in ipairs(g_buildActions) do table.insert(buildSection, v); end
	for i,v in ipairs(engineerIcons) do table.insert(buildSection, v); end

	-- TODO: clean this up
	-- local removeSection = {};
	-- for i,v in ipairs(g_removeActions) do table.insert(removeSection, v); end
	-- local attackSection = {};
	-- for i,v in ipairs(g_attackActions) do table.insert(attackSection, v); end

	local miscSection = {};
	if #g_stockIcons + #g_basicIcons > columns then
		for i,v in ipairs(g_basicIcons) do table.insert(miscSection, v); end
	end
	if #improvementIcons + #g_removeActions > columns then
		for i,v in ipairs(g_removeActions) do table.insert(miscSection, v); end
	end
	for i,v in ipairs(g_miscIcons) do table.insert(miscSection, v); end
	-- table.insert(miscSection, GameInfo.UnitCommands.UNITCOMMAND_ACTIVATE_GREAT_PERSON);
	for item in GameInfo.GreatPersonClasses() do
		table.insert(miscSection, item);
	end
	-- without the expansion this will be nil, but Lua will ignore it
	rockband = GameInfo.UnitOperations.UNITOPERATION_TOURISM_BOMB;
	table.insert(miscSection, rockband);

	-- Wonders
	local wonderIcons = {};
	for item in GameInfo.Buildings() do
		if item.IsWonder then
			table.insert(wonderIcons, item);
		end
	end
	if #wonderIcons ~= 0 then
		-- skip this icon if no wonders at all, e.g. in some scenarios
		table.insert(wonderIcons, GameInfo.Districts.DISTRICT_WONDER);
	end
	table.sort(wonderIcons, MapTacks.TimelineSort);

	local wonderSection = {};
	for i,v in ipairs(wonderIcons) do table.insert(wonderSection, v); end

	-- TODO: skip adding empty sections
	local sections = {};
	table.insert(sections, stockSection);
	table.insert(sections, districtSection);
	table.insert(sections, improvementSection);
	table.insert(sections, buildSection);
	-- table.insert(sections, removeSection);
	-- table.insert(sections, attackSection);
	table.insert(sections, miscSection);
	table.insert(sections, wonderSection);

	-- convert everything to the right format
	local grid = {};
	for j,section in ipairs(sections) do
		local row = {};
		for i,item in ipairs(section) do table.insert(row, MapTacks.Icon(item)); end
		table.insert(grid, row);
	end
	return grid;
end

-- ===========================================================================
-- Given a GameInfo object, determine its icon and tooltip
function MapTacks.Icon(item)
	local name :string = nil;
	local tooltip :string = nil;
	if item == nil then
		return nil
	elseif item.name then
		-- already constructed
		return item;
	elseif item.GreatPersonClassType then  -- this must come before districts
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
local function InitializeTypes()
	-- initialize global type table
	MapTacks.iconTypes = {};
	for i, item in ipairs(g_stockIcons) do
		MapTacks.iconTypes[item.name] = MapTacks.STOCK;
	end
	for item in GameInfo.Units() do
		MapTacks.iconTypes["ICON_"..item.UnitType] = MapTacks.WHITE;
	end
	MapTacks.iconTypes[ICON_BARBARIAN_CAMP.name] = MapTacks.GRAY;
	MapTacks.iconTypes[ICON_GOODY_HUT.name] = MapTacks.GRAY;
	MapTacks.iconTypes[ICON_SPY.name] = MapTacks.GRAY;
	for item in GameInfo.Improvements() do
		MapTacks.iconTypes[item.Icon] = MapTacks.GRAY;
	end
	for item in GameInfo.UnitCommands() do
		MapTacks.iconTypes[item.Icon] = MapTacks.GRAY;
	end
	for item in GameInfo.UnitOperations() do
		MapTacks.iconTypes[item.Icon] = MapTacks.GRAY;
	end
	for item in GameInfo.GreatPersonClasses() do
		MapTacks.iconTypes[item.ActionIcon] = MapTacks.GRAY;
	end
	for item in GameInfo.Buildings() do
		MapTacks.iconTypes["ICON_"..item.BuildingType] = MapTacks.COLOR;
	end
	for item in GameInfo.Districts() do
		MapTacks.iconTypes["ICON_"..item.DistrictType] = MapTacks.HEX;
	end
end

-- ===========================================================================
-- Given an icon name, determine its color and size profile
function MapTacks.IconType(pin :table)
	if not pin then return nil; end
	local iconName = pin:GetIconName();
	-- look up icon types recorded during initialization
	if MapTacks.iconTypes == nil then InitializeTypes(); end
	local iconType = MapTacks.iconTypes[iconName];
	if iconType then return iconType; end
	-- print(iconName, iconType);  -- debug
	-- fallback code in case some random/modded stuff falls through the cracks
	if iconName:sub(1,5) ~= "ICON_" then return nil; end
	local iconType = iconName:sub(6, 10);
	if iconType == "MAP_P" then
		return MapTacks.STOCK;
	elseif iconType == "UNIT_" then
		return MapTacks.WHITE;
	elseif iconType == "BUILD" then  -- wonders
		return MapTacks.COLOR;
	elseif iconType == "DISTR" then
		return MapTacks.HEX;
	else
		return MapTacks.GRAY;
	end
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
function MapTacks.IconTint( abgr : number, debug : number )
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
function MapTacks.Tint( abgr : number, tint : number )
	local r = abgr % 256;
	local g = math.floor(abgr / 256) % 256;
	local b = math.floor(abgr / 65536) % 256;
	r = math.min(math.max(0, r + tint), 255);
	g = math.min(math.max(0, g + tint), 255);
	b = math.min(math.max(0, b + tint), 255);
	return ((-256 + b) * 256 + g) * 256 + r;
end

-- ===========================================================================
-- Dump reference info
function MapTacks.ReferenceInfo()
	-- Unit Commands/Operations
	print("COMMANDS --------------------------------------------------------");
	for item in GameInfo.UnitCommands() do
		if item.VisibleInUI then
			print(item.CategoryInUI, item.CommandType);
		end
	end
	print("OPERATIONS ------------------------------------------------------");
	for item in GameInfo.UnitOperations() do
		if item.VisibleInUI then
			print(item.CategoryInUI, item.OperationType);
		end
	end
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
