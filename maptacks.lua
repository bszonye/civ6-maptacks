-- ===========================================================================
-- MapTacks utility functions
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
local g_gameTraitsCache :table = nil;
function MapTacks.GameTraits()
	local traits = {};

	-- Return a copy of the global cache, if it's initialized.
	if g_gameTraitsCache then
		for k,v in pairs(g_gameTraitsCache) do traits[k] = v; end
		return traits;
	end

	-- Otherwise, analyze the game info for available features.
	-- print("initializing MapTacks.GameTraits()");

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
	-- unit classes: paradrop, rock band
	local paradrop = {};
	local rockband = {};
	for item in GameInfo.TypeTags() do
		if item.Tag == "CLASS_PARADROP" then
			paradrop[item.Type] = true;
		end
		if item.Tag == "CLASS_ROCK_BAND" then
			rockband[item.Type] = true;
		end
	end
	-- unit abilities: espionage, naturalism, archaeology, trade
	for item in GameInfo.Units() do
		if item.Spy then
			traits.ICON_SPY = true;
		end
		if item.ParkCharges ~= 0 then
			traits.UNITOPERATION_DESIGNATE_PARK = true;
		end
		if item.ExtractsArtifacts then
			traits.UNITOPERATION_EXCAVATE = true;
		end
		if item.MakeTradeRoute then
			-- if we have traders, include the trade AND road icons
			traits.UNITOPERATION_MAKE_TRADE_ROUTE = true;
			traits.UNITOPERATION_BUILD_ROUTE = true;
		end
		if rockband[item.UnitType] then
			traits.UNITOPERATION_TOURISM_BOMB = true;
		end
		if paradrop[item.UnitType] then
			traits.UNITCOMMAND_PARADROP = true;
		end
	end

	-- Cache a copy of the traits.
	-- Do not return the cache directly, as the caller will be adding
	-- player-specific traits to the returned table.
	g_gameTraitsCache = {};
	for k,v in pairs(traits) do g_gameTraitsCache[k] = v; end
	return traits;
end

function MapTacks.PlayerTraits(playerID :number)
	-- First, get the player-independent game info.
	local traits = MapTacks.GameTraits();
	-- Then, add the player-specific traits.
	local playerConfig = PlayerConfigurations[playerID];
	if playerConfig == nil then return traits; end  -- e.g. in benchmark mode
	local leader = GameInfo.Leaders[playerConfig:GetLeaderTypeID()];
	for i, item in ipairs(leader.TraitCollection) do
		traits[item.TraitType] = true;
	end
	local civilization = leader.CivilizationCollection[1];
	for i, item in ipairs(civilization.TraitCollection) do
		traits[item.TraitType] = true;
	end
	return traits;
end

function MapTacks.StockIcons()
	stock = {
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
	-- This creates a different table each time, which is important because the
	-- layout algorithm adds more icons to this section.
	return stock;
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
	if traits.UNITOPERATION_HARVEST_RESOURCE then
		table.insert(buildops, ops.UNITOPERATION_HARVEST_RESOURCE);
	end
	table.insert(buildops, ops.UNITOPERATION_REMOVE_FEATURE);
	table.insert(buildops, ops.UNITOPERATION_REPAIR);
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
	-- Note that all of these ops/cmd lookups degrade gracefully to nil,
	-- and table.insert(actions, nil) is a safe no-op.
	table.insert(actions, ops.UNITOPERATION_PILLAGE);
	if traits.UNITOPERATION_MAKE_TRADE_ROUTE then
		table.insert(actions, ops.UNITOPERATION_MAKE_TRADE_ROUTE);
	end
	if traits.ICON_SPY then
		table.insert(actions, ICON_SPY);
	end
	if traits.UNITOPERATION_EXCAVATE then
		table.insert(actions, ops.UNITOPERATION_EXCAVATE);
	end
	if traits.UNITOPERATION_TOURISM_BOMB then
		table.insert(actions, ops.UNITOPERATION_TOURISM_BOMB);
	end
	if traits.UNITCOMMAND_PARADROP then
		table.insert(actions, cmd.UNITCOMMAND_PARADROP);
	end
	table.insert(actions, cmd.UNITCOMMAND_FORM_CORPS);
	table.insert(actions, cmd.UNITCOMMAND_FORM_ARMY);
	return actions;
end

function MapTacks.PlayerGreatPeople(traits :table)
	local people = {};
	for item in GameInfo.GreatPersonClasses() do
		table.insert(people, item);
	end
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
local g_playerIconsCache = {};
function MapTacks.IconOptions(playerID :number)
	-- Return cached values if we have seen this player before.
	local cache = g_playerIconsCache[playerID];
	if cache then return cache; end
	print(string.format("initializing MapTacks.IconOptions(%d)", playerID));

	-- Gather all of the icon sets from the database.
	local stock = MapTacks.StockIcons();
	local traits = MapTacks.PlayerTraits(playerID);
	local districts = MapTacks.PlayerDistricts(traits);
	local builder, unique, buildmisc = MapTacks.PlayerImprovements(traits);
	local actions = MapTacks.PlayerActions(traits);
	local people = MapTacks.PlayerGreatPeople(traits);
	local wonders = MapTacks.PlayerWonders(traits);
	
	-- We decided to simplify the groupings of icons so they are more consistent
	-- across different rulesets, MapPinPopup will find the best layout that fits 
	-- in the minimum resolution and will center partial rows -kjones

	-- Add these to the first row
	table.insert(stock, 1, ICON_GOODY_HUT);
	table.insert(stock, 2, ICON_BARBARIAN_CAMP);

	-- Group together unit actions/improvements/greatpeople
	for i,v in ipairs(unique) do table.insert(builder, i, v); end
	for i,v in ipairs(buildmisc) do table.insert(builder, v); end
	for i,v in ipairs(actions) do table.insert(builder, v); end
	for i,v in ipairs(people) do table.insert(builder, v); end

	-- Merge small district & wonder sections.
	if #wonders <= 3 or #districts + #wonders <= 16 then
		for i,v in ipairs(wonders) do table.insert(districts, v); end
		wonders = {};
	elseif #districts <= 3 then
		for i,v in ipairs(districts) do table.insert(wonders, i, v); end
		districts = {};
	end
	
	local sections = {};
	table.insert(sections, stock);
	table.insert(sections, districts);
	table.insert(sections, builder);
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
	-- cache and return the results
	g_playerIconsCache[playerID] = grid;
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
	stock = MapTacks.StockIcons();
	for i, item in ipairs(stock) do
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
	-- print(iconName, iconType);
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
-- by 255/224 to match light areas, or by 128/112 to match shadows.
--
-- brightens colors without changing hue
-- if luma == 0, aim for .25 luma
-- if luma == 1, aim for 1.0 luma
-- linearly blend between 0 and 1
function MapTacks.IconTint(abgr :number)
	local r, g, b, a = UI.SRGBToLinear(abgr);
	local luma = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
	
	local epsilon = 1.0 / 1024;
	if luma < epsilon then
		-- pure black will be tinted to gray
		return UI.LinearToSRGB(0.25, 0.25, 0.25, a);
	end

	local scale = ((0.75 * luma) + 0.25) / luma;
	r = math.min(1.0, r * scale);
	g = math.min(1.0, g * scale);
	b = math.min(1.0, b * scale);
	
	return UI.LinearToSRGB(r, g, b, a);
end
