----------------------------------------------------------------  
-- MapPinPopup
--
-- Popup used for creating and editting map pins.
----------------------------------------------------------------  
include( "PlayerTargetLogic" );
include( "ToolTipHelper" );


----------------------------------------------------------------  
-- Globals
---------------------------------------------------------------- 
local COLOR_YELLOW				:number = 0xFF2DFFF8;
local COLOR_WHITE				:number = 0xFFFFFFFF;
 
local g_editMapPinID :number = nil;
local g_uniqueIconsPlayer :number = nil;  -- tailor UAs to the player
local g_iconOptionEntries = {};
local g_visibilityTargetEntries = {};

local g_desiredIconName :string = "";

-- Default player target is self only.
local g_playerTarget = { targetType = ChatTargetTypes.CHATTARGET_PLAYER, targetID = Game.GetLocalPlayer() };
local g_cachedChatPanelTarget = nil; -- Cached player target for ingame chat panel

-- When we aren't quite so crunched on time, it would be good to add the map pins table to the database
local g_iconPulldownOptions = {};
local g_standardIcons =
{	
-- standard icons
	{ name = "ICON_MAP_PIN_STRENGTH" },
	{ name = "ICON_MAP_PIN_RANGED"   },
	{ name = "ICON_MAP_PIN_BOMBARD"  },
	{ name = "ICON_MAP_PIN_DISTRICT" },
	{ name = "ICON_MAP_PIN_CHARGES"  },
	{ name = "ICON_MAP_PIN_DEFENSE"  },
	{ name = "ICON_MAP_PIN_MOVEMENT" },
	{ name = "ICON_MAP_PIN_NO"       },
	{ name = "ICON_MAP_PIN_PLUS"     },
	{ name = "ICON_MAP_PIN_CIRCLE"   },
	{ name = "ICON_MAP_PIN_TRIANGLE" },
	{ name = "ICON_MAP_PIN_SUN"      },
	{ name = "ICON_MAP_PIN_SQUARE"   },
	{ name = "ICON_MAP_PIN_DIAMOND"  },
};

local sendToChatTTStr = Locale.Lookup( "LOC_MAP_PIN_SEND_TO_CHAT_TT" );
local sendToChatNotVisibleTTStr = Locale.Lookup( "LOC_MAP_PIN_SEND_TO_CHAT_NOT_VISIBLE_TT" );

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
function MapPinVisibilityToPlayerTarget(mapPinVisibility :number, playerTargetData :table)
	if(mapPinVisibility == ChatTargetTypes.CHATTARGET_ALL) then
		playerTargetData.targetType = ChatTargetTypes.CHATTARGET_ALL;
		playerTargetData.targetID = GetNoPlayerTargetID();
	elseif(mapPinVisibility == ChatTargetTypes.CHATTARGET_TEAM) then
		local localPlayerID = Game.GetLocalPlayer();
		local localPlayer = PlayerConfigurations[localPlayerID];
		local localTeam = localPlayer:GetTeam();
		playerTargetData.targetType = ChatTargetTypes.CHATTARGET_TEAM;
		playerTargetData.targetID = localTeam;
	elseif(mapPinVisibility >= 0) then
		-- map pin visibility stores individual player targets as a straight positive number
		playerTargetData.targetType = ChatTargetTypes.CHATTARGET_PLAYER;
		playerTargetData.targetID = mapPinVisibility;
	else
		-- Unknown map pin visibility state
		playerTargetData.targetType = ChatTargetTypes.NO_CHATTARGET;
		playerTargetData.targetID = GetNoPlayerTargetID();
	end
end

function PlayerTargetToMapPinVisibility(playerTargetData :table)
	if(playerTargetData.targetType == ChatTargetTypes.CHATTARGET_ALL) then
		return ChatTargetTypes.CHATTARGET_ALL;
	elseif(playerTargetData.targetType == ChatTargetTypes.CHATTARGET_TEAM) then
		return ChatTargetTypes.CHATTARGET_TEAM;
	elseif(playerTargetData.targetType == ChatTargetTypes.CHATTARGET_PLAYER) then
		-- map pin visibility stores individual player targets as a straight positive number
		return playerTargetData.targetID;
	end

	return ChatTargetTypes.NO_CHATTARGET;
end

function MapPinIsVisibleToChatTarget(mapPinVisibility :number, chatPlayerTarget :table)
	if(chatPlayerTarget == nil or mapPinVisibility == nil) then
		return false;
	end

	if(mapPinVisibility == ChatTargetTypes.CHATTARGET_ALL) then
		-- All pins are visible to all
		return true;
	elseif(mapPinVisibility == ChatTargetTypes.CHATTARGET_TEAM) then
		-- Team pins are visible in that team's chat and whispers to anyone on that team.
		local localPlayerID = Game.GetLocalPlayer();
		local localPlayer = PlayerConfigurations[localPlayerID];
		local localTeam = localPlayer:GetTeam();
		if(chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_TEAM) then
			if(localTeam == chatPlayerTarget.targetID) then
				return true;
			end
		elseif(chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER and chatPlayerTarget.targetID ~= NO_PLAYERTARGET_ID) then
			local chatPlayerID = chatPlayerTarget.targetID;
			local chatPlayer = PlayerConfigurations[chatPlayerID];
			local chatTeam = chatPlayer:GetTeam();	
			if(localTeam == chatTeam) then
				return true;
			end	
		end
	elseif(mapPinVisibility >= 0) then
		-- Individual map pin is only visible to that player.
		if(chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER and mapPinVisibility == chatPlayerTarget.targetID) then
			return true;
		end
	end

	return false;
end


-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
function SetMapPinIcon(imageControl :table, mapPinIconName :string)
	if(imageControl ~= nil and mapPinIconName ~= nil) then
		imageControl:SetIcon(mapPinIconName);
	end
end

-- ===========================================================================
function AddIcon(name, tooltip)
	table.insert(g_iconPulldownOptions, { name=name, tooltip=tooltip });
	-- print(name, tooltip);
end

-- ===========================================================================
function PopulateIconOptions()
	-- build icon table with default pins + extensions
	g_iconPulldownOptions = {};

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
	for i, item in ipairs(g_standardIcons) do
		AddIcon(item.name);
	end

	-- Districts
	for item in GameInfo.Districts() do
		local itype = item.DistrictType;
		if districts[itype] then
			-- unique district replacements for this civ
			itype = districts[itype]
			AddIcon("ICON_"..itype, itype);
		elseif item.TraitType then
			-- skip other unique districts
		elseif item.InternalOnly then
			-- these districts have icons but not tooltips
			AddIcon("ICON_"..itype);
		else
			AddIcon("ICON_"..itype, itype);
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
			AddIcon(item.Icon, itype);
		end
	end
	-- Unique improvements
	for i, item in ipairs(unique_improvements) do
		AddIcon(item.Icon, item.ImprovementType);
	end
	-- Minor civ improvements
	for i, item in ipairs(minor_civ_improvements) do
		AddIcon(item.Icon, item.ImprovementType);
	end

	-- Great people
	for item in GameInfo.GreatPersonClasses() do
		AddIcon(item.ActionIcon, item.Name);
	end

	-- Unit commands
	-- TODO: these mostly make poor map pins
	for item in GameInfo.UnitCommands() do
		if item.VisibleInUI then
			AddIcon(item.Icon, item.Description);
		end
	end

	-- Unit operations
	-- TODO: only some of these make good map pins
	for item in GameInfo.UnitOperations() do
		if item.VisibleInUI then
			AddIcon(item.Icon, item.Description);
		end
	end

	g_iconOptionEntries = {};
	Controls.IconOptionStack:DestroyAllChildren();

	local controlTable = {};
	local  newIconEntry = {};
	for i, pair in ipairs(g_iconPulldownOptions) do
		controlTable = {};
		newIconEntry = {};
		ContextPtr:BuildInstanceForControl( "IconOptionInstance", controlTable, Controls.IconOptionStack );
		SetMapPinIcon(controlTable.Icon, pair.name);
	    controlTable.IconOptionButton:RegisterCallback(Mouse.eLClick, OnIconOption);
		controlTable.IconOptionButton:SetVoids(i, -1);
		if pair.tooltip ~= nil then
			local tooltip = ToolTipHelper.GetToolTip(pair.tooltip, Game.GetLocalPlayer()) or Locale.Lookup(pair.tooltip);
			controlTable.IconOptionButton:SetToolTipString(tooltip);
		end

		newIconEntry.IconName = pair.name;
		newIconEntry.Instance = controlTable;
		g_iconOptionEntries[i] = newIconEntry;

		UpdateIconOptionColor(i);
	end

	Controls.IconOptionStack:CalculateSize();
	Controls.IconOptionStack:ReprocessAnchoring();
	Controls.OptionsStack:CalculateSize();
	Controls.OptionsStack:ReprocessAnchoring();
	Controls.WindowContentsStack:CalculateSize();
	Controls.WindowContentsStack:ReprocessAnchoring();
	Controls.WindowStack:CalculateSize();
	Controls.WindowStack:ReprocessAnchoring();
	Controls.WindowContainer:ReprocessAnchoring();
end

-- ===========================================================================
function UpdateIconOptionColors()
	for iconIndex, iconEntry in pairs(g_iconOptionEntries) do
		UpdateIconOptionColor(iconIndex);
	end
end

-- ===========================================================================
function UpdateIconOptionColor(iconEntryIndex :number)
	local iconEntry :table = g_iconOptionEntries[iconEntryIndex];
	if(iconEntry ~= nil) then
		if(iconEntry.IconName == g_desiredIconName) then
			-- Selected icon
			iconEntry.Instance.IconOptionButton:SetSelected(true);
		else
			iconEntry.Instance.IconOptionButton:SetSelected(false);
		end
	end
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
function MapTacksTestPattern()
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
		for j, icon in ipairs({17, 14, 109, 29, 30, 31, 33, 34, 52, 81}) do
			local pMapPin = pPlayerCfg:GetMapPin(j-1, #civs-i);
			local iconName = g_iconPulldownOptions[icon].name;
			-- print(string.format("i=%d, j=%d %s %s", i, j, leaderName, iconName));
			pMapPin:SetName(leaderName);
			pMapPin:SetIconName(iconName);
		end
	end
	Network.BroadcastPlayerInfo();
	UI.PlaySound("Map_Pin_Add");
end

-- ===========================================================================
function GetMapPinID(id :number)
	if id == nil then return nil; end
	local activePlayerID = Game.GetLocalPlayer();
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	return pPlayerCfg:GetMapPinID(id);
end

-- ===========================================================================
function RequestMapPin(hexX :number, hexY :number)
	local activePlayerID = Game.GetLocalPlayer();
	-- update UA icons if the active player has changed
	if g_uniqueIconsPlayer ~= activePlayerID then PopulateIconOptions(); end
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local pMapPin = pPlayerCfg:GetMapPin(hexX, hexY);
	if(pMapPin ~= nil) then
		g_editMapPinID = pMapPin:GetID()

		g_desiredIconName = pMapPin:GetIconName();
		if GameConfiguration.IsAnyMultiplayer() then
			MapPinVisibilityToPlayerTarget(pMapPin:GetVisibility(), g_playerTarget);
			UpdatePlayerTargetPulldown(Controls.VisibilityPull, g_playerTarget);
			Controls.VisibilityContainer:SetHide(false);
		else
			Controls.VisibilityContainer:SetHide(true);
		end

		Controls.PinName:SetText(pMapPin:GetName());
		Controls.PinName:TakeFocus();

		UpdateIconOptionColors();
		ShowHideSendToChatButton();

		Controls.IconOptionStack:CalculateSize();
		Controls.IconOptionStack:ReprocessAnchoring();
		Controls.OptionsStack:CalculateSize();
		Controls.OptionsStack:ReprocessAnchoring();
		Controls.WindowContentsStack:CalculateSize();
		Controls.WindowContentsStack:ReprocessAnchoring();
		Controls.WindowStack:CalculateSize();
		Controls.WindowStack:ReprocessAnchoring();
		Controls.WindowContainer:ReprocessAnchoring();

		UIManager:QueuePopup( ContextPtr, PopupPriority.Current);
		Controls.PopupAlphaIn:SetToBeginning();
		Controls.PopupAlphaIn:Play();
		Controls.PopupSlideIn:SetToBeginning();
		Controls.PopupSlideIn:Play();
	end
end

-- ===========================================================================
function OnChatPanel_PlayerTargetChanged(playerTargetTable)
	g_cachedChatPanelTarget = playerTargetTable;
	if( not ContextPtr:IsHidden() ) then
		ShowHideSendToChatButton();
	end
end

-- ===========================================================================
function ShowHideSendToChatButton()
	local pMapPin = GetMapPinID(g_editMapPinID);
	local showSendButton = pMapPin ~= nil and not pMapPin:IsPrivate() and GameConfiguration.IsNetworkMultiplayer();

	Controls.SendToChatButton:SetHide(not showSendButton);

	-- Send To Chat disables itself if the current chat panel target is not visible to the map pin.
	if(showSendButton) then
		local chatVisible = MapPinIsVisibleToChatTarget(pMapPin:GetVisibility(), g_cachedChatPanelTarget);
		Controls.SendToChatButton:SetDisabled(not chatVisible);
		if(chatVisible) then
			Controls.SendToChatButton:SetToolTipString(sendToChatTTStr);
		else
			Controls.SendToChatButton:SetToolTipString(sendToChatNotVisibleTTStr);
		end
	end
end

-- ===========================================================================
function OnIconOption( iconPulldownIndex :number, notUsed :number )
	local iconOptions :table = g_iconPulldownOptions[iconPulldownIndex];
	if(iconOptions) then
		local newIconName :string = iconOptions.name;
		g_desiredIconName = newIconName;
		UpdateIconOptionColors();
	end
end

-- ===========================================================================
function OnOk()
	if( not ContextPtr:IsHidden() ) then
		local pMapPin = GetMapPinID(g_editMapPinID);
		if(pMapPin ~= nil) then
			pMapPin:SetName(Controls.PinName:GetText());
			pMapPin:SetIconName(g_desiredIconName);

			local newMapPinVisibility = PlayerTargetToMapPinVisibility(g_playerTarget);
			pMapPin:SetVisibility(newMapPinVisibility);

			Network.BroadcastPlayerInfo();
			UI.PlaySound("Map_Pin_Add");
		end

		UIManager:DequeuePopup( ContextPtr );
	end
end


-- ===========================================================================
function OnSendToChatButton()
	local pMapPin = GetMapPinID(g_editMapPinID);
	if(pMapPin ~= nil) then
		pMapPin:SetName(Controls.PinName:GetText());
		LuaEvents.MapPinPopup_SendPinToChat(pMapPin:GetPlayerID(), pMapPin:GetID());
	end
end

-- ===========================================================================
function OnDelete()
	if(g_editMapPinID ~= nil) then
		local activePlayerID = Game.GetLocalPlayer();
		local pPlayerCfg = PlayerConfigurations[activePlayerID];
		pPlayerCfg:DeleteMapPin(g_editMapPinID);
		Network.BroadcastPlayerInfo();
		UI.PlaySound("Map_Pin_Remove");
	end
	UIManager:DequeuePopup( ContextPtr );
end

function OnCancel()
	UIManager:DequeuePopup( ContextPtr );
end
----------------------------------------------------------------  
-- Event Handlers
---------------------------------------------------------------- 
function OnMapPinPlayerInfoChanged( playerID :number )
	PlayerTarget_OnPlayerInfoChanged( playerID, Controls.VisibilityPull, nil, g_visibilityTargetEntries, g_playerTarget, true);
end

function OnLocalPlayerChanged()
	g_playerTarget.targetID = Game.GetLocalPlayer();
	PopulateTargetPull(Controls.VisibilityPull, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull);

	if( not ContextPtr:IsHidden() ) then
		UIManager:DequeuePopup( ContextPtr );
	end
end

-- ===========================================================================
--	Keyboard INPUT Handler
-- ===========================================================================
function KeyHandler( key:number )
	if (key == Keys.VK_ESCAPE) then OnCancel(); return true; end
	return false;
end
-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then return KeyHandler( pInputStruct:GetKey() ); end;
	return false;
end
-- ===========================================================================
--	INITIALIZE
-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( OnInputHandler, true );

	PopulateIconOptions();
	PopulateTargetPull(Controls.VisibilityPull, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull);
	Controls.DeleteButton:RegisterCallback(Mouse.eLClick, OnDelete);
	Controls.DeleteButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.SendToChatButton:RegisterCallback(Mouse.eLClick, OnSendToChatButton);
	Controls.SendToChatButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.OkButton:RegisterCallback(Mouse.eLClick, OnOk);
	Controls.OkButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.PinName:RegisterCommitCallback( OnOk );
	
	LuaEvents.MapPinPopup_RequestMapPin.Add(RequestMapPin);
	LuaEvents.ChatPanel_PlayerTargetChanged.Add(OnChatPanel_PlayerTargetChanged);

	-- When player info is changed, this pulldown needs to know so it can update itself if it becomes invalid.
	Events.PlayerInfoChanged.Add(OnMapPinPlayerInfoChanged);
	Events.LocalPlayerChanged.Add(OnLocalPlayerChanged);

	-- Request the chat panel's player target so we have an initial value. 
	-- We have to do this because the map pin's context is loaded after the chat panel's 
	-- and the chat panel's show/hide handler is not triggered as expected.
	LuaEvents.MapPinPopup_RequestChatPlayerTarget();
		
	-- XXX debug
	LuaEvents.MapTacksTestPattern.Add(MapTacksTestPattern);
end
Initialize();

-- vim: sw=4 ts=4
