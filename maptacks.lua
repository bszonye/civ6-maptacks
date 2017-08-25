------------------------------------------------------------------
-- MapTacks
-- utility functions

function MapTacksDebug(caller)
	print("maptackscommon", caller);
end

------------------------------------------------------------------
-- Calculate icon tint color
-- Icons generally have light=224, shadow=112 (out of 255).
-- So, to match icons to civ colors, ideally brighten the original color:
-- by 255/224 to match light areas, or by 255/112 to match shadows.
--
-- In practice:
-- Light colors look best as bright as possible without distortion.
-- The darkest colors need shadow=64, light=128, max=144 for legibility.
-- Other colors look good around 1.5-1.8x brightness, matching midtones.
local g_tintCache = {};
function IconTint( abgr : number )
	if g_tintCache[abgr] ~= nil then return g_tintCache[abgr]; end
	local r = abgr % 256;
	local g = math.floor(abgr / 256) % 256;
	local b = math.floor(abgr / 65536) % 256;
	local max = math.max(r, g, b, 1);  -- avoid division by zero
	local light = 255/max;  -- maximum brightness without distortion
	local dark = 144/max;  -- minimum brightness
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

------------------------------------------------------------------
-- XXX debug

function FixColor( abgr : number )
	local r = abgr % 256;
	local g = math.floor(abgr / 256) % 256;
	local b = math.floor(abgr / 65536) % 256;
	return ((-256 + b) * 256 + g) * 256 + r;
end

local g_civInfo :table = nil;
function CivInfo( civ : string )
	if g_civInfo == nil then
		g_civInfo = {};
		for item in GameInfo.PlayerColors() do
			local leader = item.Type:match("LEADER_(.+)");
			if leader then
				local civ = item.PrimaryColor:match("^COLOR_PLAYER_(.*)_[^_]+");
				-- print(item.Type, civ, item.PrimaryColor, item.SecondaryColor);
				g_civInfo[civ] = {
					leader = leader,
					primary = FixColor(UI.GetColorValue(item.PrimaryColor)),
					secondary = FixColor(UI.GetColorValue(item.SecondaryColor))
				}
			end
		end
	end
	return g_civInfo[civ];
end

function CivColors( civ : string, primaryColor, secondaryColor )
	local info = CivInfo(civ);
	if info then
		primaryColor = info.primary;
		secondaryColor = info.secondary;
	end
	return primaryColor, secondaryColor;
end

-- ===========================================================================
-- XXX debug
local g_civs = {  -- max luma
	"RUSSIA",     --  20   20
	"GERMANY",    --  63   61
	"NUBIA",      -- 108   74
	"ARABIA",     -- 118   99
	"PERSIA",     -- 164   69
	"JAPAN",      -- 166   64
	"AZTEC",      -- 181   98
	"SCYTHIA",    -- 184   67
	"KONGO",      -- 207   74
	"INDIA",      -- 239  216
	"SPARTA",     -- 239  232
	"SPAIN",      -- 241  214
	"BRAZIL",     -- 245  221
	"SUMERIA",    -- 246  171
	"NORWAY",     -- 254  104
	"ROME",       -- 255  212
	"MACEDON",    -- 255  238
	"EGYPT",      -- 255  244
	"FRANCE",     -- 255  248
	"POLAND",     -- 255  251
	"AMERICA",    -- 255  255
	"AUSTRALIA",  -- 255  255
	"CHINA",      -- 255  255
	"ENGLAND",    -- 255  255
	"GREECE",     -- 255  255
};
local g_icons = {
	"ICON_MAP_PIN_STRENGTH",
	"ICON_MAP_PIN_RANGED",
	"ICON_MAP_PIN_BOMBARD",
	"ICON_MAP_PIN_DISTRICT",
	"ICON_MAP_PIN_CHARGES",
	"ICON_MAP_PIN_DEFENSE",
	"ICON_MAP_PIN_MOVEMENT",
	"ICON_MAP_PIN_NO",
	"ICON_MAP_PIN_PLUS",
	"ICON_MAP_PIN_CIRCLE",
	"ICON_MAP_PIN_TRIANGLE",
	"ICON_MAP_PIN_SUN",
	"ICON_MAP_PIN_SQUARE",
	"ICON_MAP_PIN_DIAMOND",
	"ICON_DISTRICT_CITY_CENTER",
	"ICON_DISTRICT_HOLY_SITE",
	"ICON_DISTRICT_CAMPUS",
	"ICON_DISTRICT_ENCAMPMENT",
	"ICON_DISTRICT_HARBOR",
	"ICON_DISTRICT_AERODROME",
	"ICON_DISTRICT_COMMERCIAL_HUB",
	"ICON_DISTRICT_ENTERTAINMENT_COMPLEX",
	"ICON_DISTRICT_THEATER",
	"ICON_DISTRICT_INDUSTRIAL_ZONE",
	"ICON_DISTRICT_NEIGHBORHOOD",
	"ICON_DISTRICT_AQUEDUCT",
	"ICON_DISTRICT_SPACEPORT",
	"ICON_DISTRICT_WONDER",
	"ICON_IMPROVEMENT_FARM",
	"ICON_IMPROVEMENT_MINE",
	"ICON_IMPROVEMENT_QUARRY",
	"ICON_IMPROVEMENT_FISHING_BOATS",
	"ICON_IMPROVEMENT_PASTURE",
	"ICON_IMPROVEMENT_PLANTATION",
	"ICON_IMPROVEMENT_CAMP",
	"ICON_IMPROVEMENT_LUMBER_MILL",
	"ICON_IMPROVEMENT_OIL_WELL",
	"ICON_IMPROVEMENT_OFFSHORE_OIL_RIG",
	"ICON_IMPROVEMENT_FORT",
	"ICON_IMPROVEMENT_AIRSTRIP",
	"ICON_IMPROVEMENT_BEACH_RESORT",
	"ICON_IMPROVEMENT_MISSILE_SILO",
	"ICON_IMPROVEMENT_COLOSSAL_HEAD",
	"ICON_IMPROVEMENT_ALCAZAR",
	"ICON_IMPROVEMENT_MONASTERY",
	"ICON_UNITOPERATION_GENERAL_ACTION",
	"ICON_UNITOPERATION_ADMIRAL_ACTION",
	"ICON_UNITOPERATION_ENGINEER_ACTION",
	"ICON_UNITOPERATION_MERCHANT_ACTION",
	"ICON_UNITOPERATION_FOUND_RELIGION",
	"ICON_UNITOPERATION_SCIENTIST_ACTION",
	"ICON_UNITOPERATION_WRITER_ACTION",
	"ICON_UNITOPERATION_ARTIST_ACTION",
	"ICON_UNITOPERATION_MUSICIAN_ACTION",
	"ICON_UNITCOMMAND_PROMOTE",
	"ICON_UNITCOMMAND_UPGRADE",
	"ICON_UNITCOMMAND_WAKE",
	"ICON_UNITCOMMAND_CANCEL",
	"ICON_UNITCOMMAND_STOP_AUTOMATION",
	"ICON_UNITCOMMAND_DELETE",
	"ICON_UNITCOMMAND_GIFT",
	"ICON_UNITCOMMAND_ENTER_FORMATION",
	"ICON_UNITCOMMAND_EXIT_FORMATION",
	"ICON_UNITCOMMAND_ACTIVATE_GREAT_PERSON",
	"ICON_UNITCOMMAND_DISTRICT_PRODUCTION",
	"ICON_UNITCOMMAND_FORM_CORPS",
	"ICON_UNITCOMMAND_FORM_ARMY",
	"ICON_UNITCOMMAND_PLUNDER_TRADE_ROUTE",
	"ICON_UNITCOMMAND_NAME_UNIT",
	"ICON_UNITCOMMAND_WONDER_PRODUCTION",
	"ICON_UNITCOMMAND_HARVEST_WONDER",
	"ICON_UNITCOMMAND_AIRLIFT",
	"ICON_UNITOPERATION_AIR_ATTACK",
	"ICON_UNITOPERATION_AUTO_EXPLORE",
	"ICON_UNITOPERATION_BUILD_IMPROVEMENT",
	"ICON_UNITOPERATION_BUILD_ROUTE",
	"ICON_UNITOPERATION_CLEAR_CONTAMINATION",
	"ICON_UNITOPERATION_CONVERT_BARBARIANS",
	"ICON_UNITOPERATION_DEPLOY",
	"ICON_UNITOPERATION_DESIGNATE_PARK",
	"ICON_UNITOPERATION_EVANGELIZE_BELIEF",
	"ICON_UNITOPERATION_EXCAVATE",
	"ICON_UNITOPERATION_FORTIFY",
	"ICON_UNITOPERATION_HEAL",
	"ICON_UNITOPERATION_FOUND_CITY",
	"ICON_UNITOPERATION_FOUND_RELIGION",
	"ICON_UNITOPERATION_HARVEST_RESOURCE",
	"ICON_UNITOPERATION_LAUNCH_INQUISITION",
	"ICON_UNITOPERATION_MAKE_TRADE_ROUTE",
	"ICON_UNITOPERATION_MOVE_TO",
	"ICON_UNITOPERATION_WMD_STRIKE",
	"ICON_UNITOPERATION_COASTAL_RAID",
	"ICON_UNITOPERATION_PILLAGE",
	"ICON_UNITOPERATION_PILLAGE_ROUTE",
	"ICON_UNITOPERATION_PLANT_FOREST",
	"ICON_UNITOPERATION_RANGE_ATTACK",
	"ICON_UNITOPERATION_REBASE",
	"ICON_UNITOPERATION_REMOVE_FEATURE",
	"ICON_UNITOPERATION_SPREAD_RELIGION",
	"ICON_UNITOPERATION_REMOVE_IMPROVEMENT",
	"ICON_UNITOPERATION_REPAIR",
	"ICON_UNITOPERATION_REPAIR_ROUTE",
	"ICON_UNITOPERATION_HEAL",
	"ICON_UNITOPERATION_RETRAIN",
	"ICON_UNITOPERATION_SKIP_TURN",
	"ICON_UNITOPERATION_SLEEP",
	"ICON_UNITOPERATION_SPREAD_RELIGION",
	"ICON_UNITOPERATION_SPY_COUNTERSPY",
	"ICON_UNITOPERATION_SPY_DISRUPT_ROCKETRY",
	"ICON_UNITOPERATION_SPY_GAIN_SOURCES",
	"ICON_UNITOPERATION_SPY_GREAT_WORK_HEIST",
	"ICON_UNITOPERATION_SPY_LISTENING_POST",
	"ICON_UNITOPERATION_SPY_RECRUIT_PARTISANS",
	"ICON_UNITOPERATION_SPY_SABOTAGE_PRODUCTION",
	"ICON_UNITOPERATION_SPY_SIPHON_FUNDS",
	"ICON_UNITOPERATION_SPY_STEAL_TECH_BOOST",
	"ICON_UNITOPERATION_SPY_TRAVEL_NEW_CITY",
	"ICON_UNITOPERATION_TELEPORT_TO_CITY",
	"ICON_UNITOPERATION_UPGRADE",
	"ICON_UNITOPERATION_ALERT",
};

function MapTacksTestPattern()
	print("MapTacksTestPattern: start");
	local civs = {};
	for item in GameInfo.PlayerColors() do
		if item.Type:find("^LEADER_") then
			local civ = item.PrimaryColor:match("^COLOR_PLAYER_(.*)_[^_]+");
			table.insert(civs, civ);
		end
	end
	table.sort(civs);
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local pMapPin = pPlayerCfg:GetMapPin(hexX, hexY);
	for i, leaderName in ipairs(g_civs) do
		for j, icon in ipairs({17, 14, 108, 29, 30, 31, 33, 34, 51, 80}) do
			local pMapPin = pPlayerCfg:GetMapPin(j-1, #civs-i);
			local iconName = g_icons[icon];
			-- print(string.format("i=%d, j=%d %s %s", i, j, leaderName, iconName));
			pMapPin:SetName(leaderName);
			pMapPin:SetIconName(iconName);
		end
	end
	Network.BroadcastPlayerInfo();
	UI.PlaySound("Map_Pin_Add");
end

-- ===========================================================================
function MapTacksIconOptions(standardIcons : table)
	local icons = {};
	local activePlayerID = Game.GetLocalPlayer();
	g_uniqueIconsPlayer = activePlayerID;
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local civ = pPlayerCfg:GetCivilizationTypeName();
	-- civ = 'CIVILIZATION_GREECE';
	-- civ = 'CIVILIZATION_ROME';
	-- civ = 'CIVILIZATION_GERMANY';
	-- civ = 'CIVILIZATION_RUSSIA';
	-- civ = 'CIVILIZATION_KONGO';
	-- civ = 'CIVILIZATION_BRAZIL';
	-- civ = 'CIVILIZATION_ENGLAND';
	-- civ = 'CIVILIZATION_CHINA';
	-- print(civ);

	-- Table of special/indirect traits
	local extra_traits = {
		IMPROVEMENT_ROMAN_FORT="TRAIT_CIVILIZATION_UNIT_ROMAN_LEGION",
	}
	-- Get unique traits for the player civilization
	local traits = {};
	for item in GameInfo.CivilizationTraits() do
		if item.CivilizationType == civ then
			-- print(item.TraitType);
			traits[item.TraitType] = true;
		end
	end
	-- Get unique district replacement info
	local districts = {};
	for item in GameInfo.Districts() do
		if item.TraitType and traits[item.TraitType] then
			local swap = GameInfo.DistrictReplaces[item.DistrictType];
			districts[swap.ReplacesDistrictType] = item.DistrictType;
			-- print(item.DistrictType, "replaces", base);
		end
	end
	-- for i, item in pairs(traits) do print(i, item); end

	-- Standard map pins
	for i, item in ipairs(standardIcons) do
		table.insert(icons, { name=item.name });
	end

	-- Districts
	for item in GameInfo.Districts() do
		local itype = item.DistrictType;
		if districts[itype] then
			-- unique district replacements for this civ
			itype = districts[itype]
			table.insert(icons, { name="ICON_"..itype, tooltip=itype });
		elseif item.TraitType then
			-- skip other unique districts
		elseif item.InternalOnly then
			-- these districts have icons but not tooltips
			table.insert(icons, { name="ICON_"..itype });
		else
			table.insert(icons, { name="ICON_"..itype, tooltip=itype });
		end
	end

	-- Improvements
	local minor_civ_improvements = {};
	local unique_improvements = {};
	for item in GameInfo.Improvements() do
		local itype = item.ImprovementType;
		if item.BarbarianCamp or item.Goody then
			-- skip
		elseif item.TraitType then
			-- organize unique & city state improvements
			if item.TraitType:find("^TRAIT_CIVILIZATION_") then
				if traits[item.TraitType] then
					table.insert(unique_improvements, item);
				end
			elseif item.TraitType:find("^MINOR_CIV_") then
				table.insert(minor_civ_improvements, item);
			end
		elseif extra_traits[itype] then
			-- handle special cases like the Roman Fort
			if traits[extra_traits[itype]] then
				table.insert(unique_improvements, item);
			end
		else
			table.insert(icons, { name=item.Icon, tooltip=itype });
		end
	end
	-- Unique improvements
	for i, item in ipairs(unique_improvements) do
		table.insert(icons, { name=item.Icon, tooltip=item.ImprovementType });
	end
	-- Minor civ improvements
	for i, item in ipairs(minor_civ_improvements) do
		table.insert(icons, { name=item.Icon, tooltip=item.ImprovementType });
	end

	-- Great people
	for item in GameInfo.GreatPersonClasses() do
		table.insert(icons, { name=item.ActionIcon, tooltip=item.Name });
	end

	-- Unit commands
	-- TODO: these mostly make poor map pins
	for item in GameInfo.UnitCommands() do
		if item.VisibleInUI then
			table.insert(icons, { name=item.Icon, tooltip=item.Description });
		end
	end

	-- Unit operations
	-- TODO: only some of these make good map pins
	for item in GameInfo.UnitOperations() do
		if item.VisibleInUI then
			table.insert(icons, { name=item.Icon, tooltip=item.Description });
		end
	end

	return icons;
end

-- vim: sw=4 ts=4
