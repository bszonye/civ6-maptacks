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

-- shorthand for common GameInfo lookups
local cmd = GameInfo.UnitCommands;
local ops = GameInfo.UnitOperations;

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
local g_basicIcons = {
	ICON_BARBARIAN_CAMP,
	ICON_GOODY_HUT,
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
-- Database utility functions
function MapTacks.PlayerTraits()
	-- First, get the true traits.
	local traits = {};
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local leader = GameInfo.Leaders[pPlayerCfg:GetLeaderTypeID()];
	for i, item in ipairs(leader.TraitCollection) do
		traits[item.TraitType] = true;
	end
	local civilization = leader.CivilizationCollection[1];
	for i, item in ipairs(civilization.TraitCollection) do
		traits[item.TraitType] = true;
	end
	local buildops = {};
	-- Then, check the game rules for various abilities and actions.
	-- forest planting
	for item in GameInfo.Features() do
		if item.AddCivic then
			traits.UNITOPERATION_PLANT_FOREST = true;
		end
	end
	-- resource harvesting
	for item in GameInfo.Resources() do
		if #item.Harvests ~= 0 then
			traits.UNITOPERATION_HARVEST_RESOURCE = true;
		end
	end
	-- road building
	for item in GameInfo.Routes() do
		if #item.ValidBuildUnits ~= 0 then
			traits.UNITOPERATION_BUILD_ROUTE = true;
		end
	end
	-- unit abilities: espionage, naturalism, archaeology, trade
	for item in GameInfo.Units() do
		if item.Spy then
			traits.UNIT_SPY = true;
		end
		if item.ParkCharges ~= 0 then
			traits.UNITOPERATION_DESIGNATE_PARK = true;
		end
		if item.ExtractsArtifacts then
			traits.UNITOPERATION_EXCAVATE = true;
		end
		if item.MakeTradeRoute then
			traits.UNITOPERATION_MAKE_TRADE_ROUTE = true;
		end
	end
	return traits;
end

function MapTacks.PlayerDistricts(traits :table)
	-- First, determine which districts to ignore.
	local skipDistricts = {};
	for item in GameInfo.Districts() do
		local itype = item.DistrictType;
		local trait = item.TraitType;
		if itype == "DISTRICT_WONDER" then
			-- this goes in the wonders section instead
			skipDistricts[itype] = itype
		elseif traits[trait] then
			-- unique district for our civ
			-- mark any districts replaced by this one
			for i, swap in ipairs(item.ReplacesCollection) do
				local base = swap.ReplacesDistrictType;
				skipDistricts[base] = itype;
			end
		elseif trait then
			-- unique district for another civ
			skipDistricts[itype] = trait;
		end
	end
	-- Then, collect all of the districts for this civ.
	local districts = {};
	for item in GameInfo.Districts() do
		if not skipDistricts[item.DistrictType] then
			table.insert(districts, item);
		end
	end
	table.sort(districts, MapTacks.TimelineSort);
	return districts;
end

function MapTacks.PlayerImprovements(traits :table)
	-- Improvements
	local builder = {};
	local unique = {};
	local governor = {};
	local minorCiv = {};
	local engineer = {};
	-- read Improvements database
	for item in GameInfo.Improvements() do
		-- does this improvement have a valid build unit?
		local units = item.ValidBuildUnits;
		if #units ~= 0 then
			local unit = GameInfo.Units[units[1].UnitType];
			local trait = item.TraitType or unit.TraitType;
			if trait then
				if traits[trait] then
					table.insert(unique, item);
				elseif trait == "TRAIT_CIVILIZATION_NO_PLAYER" then
					table.insert(governor, item);
				elseif trait:sub(1, 10) == "MINOR_CIV_" then
					table.insert(minorCiv, item);
				end
			elseif unit.UnitType == "UNIT_BUILDER" then
				table.insert(builder, item);
			else
				table.insert(engineer, item);
			end
			-- print(item.Name, MapTacks.Timeline(item));
		end
	end
	-- sort lists by timeline
	table.sort(builder, MapTacks.TimelineSort);
	table.sort(unique, MapTacks.TimelineSort);
	table.sort(governor, MapTacks.TimelineSort);
	table.sort(minorCiv, MapTacks.TimelineSort);
	table.sort(engineer, MapTacks.TimelineSort);
	-- additional engineer operations
	if traits.UNITOPERATION_BUILD_ROUTE then
		table.insert(engineer, 1, ops.UNITOPERATION_BUILD_ROUTE);
	end
	-- additional builder & support operations
	local buildops = {};
	if traits.UNITOPERATION_DESIGNATE_PARK then
		table.insert(buildops, ops.UNITOPERATION_DESIGNATE_PARK);
	end
	if traits.UNITOPERATION_PLANT_FOREST then
		table.insert(buildops, ops.UNITOPERATION_PLANT_FOREST);
	end
	table.insert(buildops, ops.UNITOPERATION_REMOVE_FEATURE);
	-- collect all of the miscellaneous builds & improvements
	local misc = {};
	for i,v in ipairs(governor) do table.insert(misc, v); end
	for i,v in ipairs(minorCiv) do table.insert(misc, v); end
	for i,v in ipairs(engineer) do table.insert(misc, v); end
	for i,v in ipairs(buildops) do table.insert(misc, v); end
	return builder, unique, misc, governor, minorCiv, engineer, buildops;
end

function MapTacks.PlayerActions(traits :table)
	local actions = {};
	table.insert(actions, ops.UNITOPERATION_PILLAGE);
	table.insert(actions, ops.UNITOPERATION_REPAIR);
	if traits.UNITOPERATION_HARVEST_RESOURCE then
		table.insert(actions, ops.UNITOPERATION_HARVEST_RESOURCE);
	end
	if traits.UNITOPERATION_MAKE_TRADE_ROUTE then
		table.insert(actions, ops.UNITOPERATION_MAKE_TRADE_ROUTE);
	end
	if traits.UNIT_SPY then
		table.insert(actions, ICON_SPY);
	end
	if traits.UNITOPERATION_EXCAVATE then
		table.insert(actions, ops.UNITOPERATION_EXCAVATE);
	end
	return actions;
end

function MapTacks.PlayerGreatPeople(traits :table)
	-- If these are not in the current game rules, the values resolve to nil,
	-- which is a no-op in the table.insert below.
	local army = cmd.UNITCOMMAND_FORM_ARMY or cmd.UNITCOMMAND_FORM_CORPS;
	local rockband = ops.UNITOPERATION_TOURISM_BOMB;

	local people = {};
	table.insert(people, army);
	for item in GameInfo.GreatPersonClasses() do
		table.insert(people, item);
	end
	table.insert(people, rockband);

	return people;
end

function MapTacks.PlayerWonders(traits :table)
	local wonders = {};
	for item in GameInfo.Buildings() do
		if item.IsWonder then
			table.insert(wonders, item);
		end
	end
	-- also include the generic icon, if there are any wonders
	if #wonders ~= 0 then
		table.insert(wonders, GameInfo.Districts.DISTRICT_WONDER);
	end
	table.sort(wonders, MapTacks.TimelineSort);
	return wonders;
end

-- ===========================================================================
-- Build the grid of map pin icon options
function MapTacks.IconOptions()
	-- Collect static sets.
	local stock = {};
	for i, item in ipairs(g_stockIcons) do table.insert(stock, item); end
	local basic = {};
	for i, item in ipairs(g_basicIcons) do table.insert(basic, item); end

	-- Gather all of the icon sets from the database.
	local traits = MapTacks.PlayerTraits();
	local districts = MapTacks.PlayerDistricts(traits);
	local builder, unique, miscbuild = MapTacks.PlayerImprovements(traits);
	local actions = MapTacks.PlayerActions(traits);
	local people = MapTacks.PlayerGreatPeople(traits);
	local wonders = MapTacks.PlayerWonders(traits);

	-- Lay out the basic structure.
	-- Start with a preliminary estimate of the grid width.
	local columns = math.max(9, #districts, #builder, #unique + #miscbuild);
	print(columns, "columns (preliminary)");

	-- Consolidate similar rows if possible.
	if #districts + #wonders <= columns then
		-- move all the wonders into the district section
		for i,v in ipairs(wonders) do table.insert(districts, v); end
		wonders = nil;
	end
	if #builder + #unique + #miscbuild <= columns then
		-- move all of the improvements onto a single row
		for i,v in ipairs(unique) do table.insert(builder, i, v); end
		for i,v in ipairs(miscbuild) do table.insert(builder, v); end
		miscbuild = {};
	else
		-- only join the misc build section
		for i,v in ipairs(unique) do table.insert(miscbuild, i, v); end
	end

	-- Now finalize the design width.
	-- TODO: stretch this if a section is only a little over
	columns = math.max(7, #districts, #builder, #miscbuild);
	print(columns, "columns (final)");

	-- Stock map pins
	local stockSpace = math.min(0, columns - #stock);
	if stockSpace == 1 or #basic < stockSpace then
		-- move the Pillage icon to stock if there's room
		table.insert(stock, 1, remove(actions, 1))
	end
	if #basic + #stock <= columns then
		-- move the basic icons to stock if there's room
		for i,v in ipairs(basic) do
			table.insert(stock, i, remove(basic, 1))
		end
	end

	-- Merge basic icons and misc units
	local misc = {};
	for i,v in ipairs(basic) do table.insert(misc, v); end
	for i,v in ipairs(actions) do table.insert(misc, v); end
	-- Merge misc and great people if they fit
	if #misc + #people <= columns then
		for i,v in ipairs(people) do table.insert(misc, v); end
		people = {};
	end

	local sections = {};
	table.insert(sections, stock);
	table.insert(sections, districts);
	table.insert(sections, builder);
	table.insert(sections, miscbuild);
	table.insert(sections, misc);
	table.insert(sections, people);
	table.insert(sections, wonders);

	-- convert everything to the right format
	local grid = {};
	for j,section in ipairs(sections) do
		if #section ~= 0 then
			local row = {};
			for i,item in ipairs(section) do
				table.insert(row, MapTacks.Icon(item));
			end
			table.insert(grid, row);
		end
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
