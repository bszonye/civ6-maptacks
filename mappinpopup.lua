----------------------------------------------------------------
-- MapPinPopup
--
-- Popup used for creating and editting map pins.
----------------------------------------------------------------

include( "PlayerTargetLogic" );
include( "ToolTipHelper" );
include( "MapTacks" );


----------------------------------------------------------------  
-- Globals
---------------------------------------------------------------- 
local COLOR_YELLOW : number = UI.GetColorValue("COLOR_YELLOW");
local COLOR_WHITE  : number = UI.GetColorValue("COLOR_WHITE");
 
local NO_EDIT_PIN_ID :number = -1;
local g_editPinID :number = NO_EDIT_PIN_ID;
-- layout tables are tailored to the current player
local g_iconLayoutPlayerID :number = nil;
-- the tables are organized by section: grid[section][index]
local g_iconPulldownOptions = {};  -- icon metadata from MapTacks.IconOptions()
local g_iconOptionEntries = {};  -- icon control objects

local g_desiredIconName :string = "";

local g_visibilityTargetEntries = {};
-- Default player target is self only.
local g_playerTarget = { targetType = ChatTargetTypes.CHATTARGET_PLAYER, targetID = Game.GetLocalPlayer() };
local g_cachedChatPanelTarget = nil; -- Cached player target for ingame chat panel

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
		if not imageControl:SetIcon(mapPinIconName) then
			imageControl:SetIcon(MapTacks.UNKNOWN);
		end
	end
end

-- ===========================================================================
function PopulateIconOptions()
	-- unique icons are specific to the current player
	g_iconLayoutPlayerID = Game.GetLocalPlayer();
	-- build icon table with default pins + extensions
	g_iconPulldownOptions = MapTacks.IconOptions(g_iconLayoutPlayerID);

	g_iconOptionEntries = {};
	Controls.IconOptionStack:DestroyAllChildren();
	
	-- Fit the icons within 1024x768
	-- If a mod adds a ton of new improvements/districts we might need to add a scrollbar
	local MIN_COLS = 8;
	local MAX_COLS = 16;
	local MAX_ROWS = 12;

	-- find the dimensions that have the fewest blank spaces that fits the minimum resolution
	local columns = MAX_COLS;
	local nMinBlanks = MAX_COLS * MAX_ROWS;
	for i=MIN_COLS,MAX_COLS do
		local nBlanks = 0;
		local nRows = 0;
		for j, section in ipairs(g_iconPulldownOptions) do
			nRows = nRows + math.ceil(#section / i);
			local remainder = #section % i;
			if remainder > 0 then
				nBlanks = nBlanks + (i - remainder);
			end
		end
		if nBlanks < nMinBlanks and nRows <= MAX_ROWS then
			nMinBlanks = nBlanks;
			columns = i;
		end
	end
	print("Selected " .. columns .. " columns");

	local controlTable = {};
	local newIconEntry = {};
	for j, section in ipairs(g_iconPulldownOptions) do
		g_iconOptionEntries[j] = {};
		local sectionTable = {};
		ContextPtr:BuildInstanceForControl( "IconOptionRowInstance", sectionTable, Controls.IconOptionStack );
		-- dynamically determine section spacing
		local ht = math.floor((#section + columns - 1) / columns);
		local wd = columns;
		sectionTable.IconOptionRowStack:SetWrapWidth(44 * wd);
		if j > 1 and (ht > 1 or columns < #g_iconPulldownOptions[j - 1]) then
			-- leave a break around multi-row sections
			sectionTable.IconOptionRowStack:SetOffsetY(8);
		end
		for i, pair in ipairs(section) do
			controlTable = {};
			newIconEntry = {};
			ContextPtr:BuildInstanceForControl( "IconOptionInstance", controlTable, sectionTable.IconOptionRowStack );
			SetMapPinIcon(controlTable.Icon, pair.name);
			controlTable.IconOptionButton:RegisterCallback(Mouse.eLClick, OnIconOption);
			controlTable.IconOptionButton:SetVoids(i, j);
			if pair.tooltip then
				local tooltip = ToolTipHelper.GetToolTip(pair.tooltip, Game.GetLocalPlayer()) or Locale.Lookup(pair.tooltip);
				controlTable.IconOptionButton:SetToolTipString(tooltip);
			end

			newIconEntry.IconName = pair.name;
			newIconEntry.Instance = controlTable;
			g_iconOptionEntries[j][i] = newIconEntry;

			UpdateIconOptionColor(i, j);
			
			if (#section % wd) ~= 0 then
				-- this section has a partially filled row, create a new stack at
				-- the end of the final full row, so it can be centered properly
				if (i % wd) == 0 and (i / wd) == (ht - 1) then
					sectionTable = {};
					ContextPtr:BuildInstanceForControl( "IconOptionRowInstance", sectionTable, Controls.IconOptionStack );
					sectionTable.IconOptionRowStack:SetWrapWidth(44 * wd);
				end
			end
		end
	end

	-- set width dynamically according to widest section
	Controls.Window:SetSizeX(44 * columns + 30);
	Controls.OptionsStack:SetWrapWidth(44 * columns + 8);
	Controls.IconOptionStack:CalculateSize();
	Controls.OptionsStack:CalculateSize();
	Controls.WindowContentsStack:CalculateSize();
	Controls.WindowStack:CalculateSize();
end

-- ===========================================================================
function UpdateIconOptionColors()
	for j, section in ipairs(g_iconOptionEntries) do
		for i, icon in ipairs(section) do
			UpdateIconOptionColor(i, j);
		end
	end
end

-- ===========================================================================
function UpdateIconOptionColor(index :number, section :number)
	local iconEntry :table = g_iconOptionEntries[section][index];
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
function RequestMapPin(hexX :number, hexY :number)
	local activePlayerID = Game.GetLocalPlayer();
	-- update UA icons if the active player has changed
	if g_iconLayoutPlayerID ~= activePlayerID then PopulateIconOptions(); end
	local pPlayerCfg = PlayerConfigurations[activePlayerID];
	local pMapPin = pPlayerCfg:GetMapPin(hexX, hexY);
	if(pMapPin ~= nil) then
		g_editPinID = pMapPin:GetID();
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
-- Returns the map pin configuration for the pin we are currently editing.
-- Do not cache the map pin configuration because it will get destroyed by other processes.  Use it and get out!
function GetEditPinConfig()
	if(g_editPinID ~= NO_EDIT_PIN_ID) then
		local activePlayerID = Game.GetLocalPlayer();
		local pPlayerCfg = PlayerConfigurations[activePlayerID];
		local pMapPin = pPlayerCfg:GetMapPinID(g_editPinID);
		return pMapPin;
	end

	return nil;
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
	local editPin = GetEditPinConfig();
	if(editPin == nil) then
		return;
	end

	local privatePin = editPin:IsPrivate();
	local showSendButton = GameConfiguration.IsNetworkMultiplayer() and not privatePin;

	Controls.SendToChatButton:SetHide(not showSendButton);

	-- Send To Chat disables itself if the current chat panel target is not visible to the map pin.
	if(showSendButton) then
		local chatVisible = MapPinIsVisibleToChatTarget(editPin:GetVisibility(), g_cachedChatPanelTarget);
		Controls.SendToChatButton:SetDisabled(not chatVisible);
		if(chatVisible) then
			Controls.SendToChatButton:SetToolTipString(sendToChatTTStr);
		else
			Controls.SendToChatButton:SetToolTipString(sendToChatNotVisibleTTStr);
		end
	end
end

-- ===========================================================================
function OnIconOption( index :number, section :number )
	local iconOptions :table = g_iconPulldownOptions[section][index];
	if(iconOptions) then
		local newIconName :string = iconOptions.name;
		g_desiredIconName = newIconName;
		UpdateIconOptionColors();
	end
end

-- ===========================================================================
function OnOk()
	if( not ContextPtr:IsHidden() ) then
		local editPin = GetEditPinConfig();
		if(editPin ~= nil) then
			editPin:SetName(Controls.PinName:GetText());
			editPin:SetIconName(g_desiredIconName);

			local newMapPinVisibility = PlayerTargetToMapPinVisibility(g_playerTarget);
			editPin:SetVisibility(newMapPinVisibility);

			Network.BroadcastPlayerInfo();
			UI.PlaySound("Map_Pin_Add");
		end

		UIManager:DequeuePopup( ContextPtr );
	end
end


-- ===========================================================================
function OnSendToChatButton()
	local editPinCfg = GetEditPinConfig();
	if(editPinCfg ~= nil) then
		editPinCfg:SetName(Controls.PinName:GetText());
		LuaEvents.MapPinPopup_SendPinToChat(editPinCfg:GetPlayerID(), editPinCfg:GetID());
	end
end

-- ===========================================================================
function OnDelete()
	local editPinCfg = GetEditPinConfig();
	if(editPinCfg ~= nil) then
		local activePlayerID = Game.GetLocalPlayer();
		local pPlayerCfg = PlayerConfigurations[activePlayerID];
		local deletePinID = editPinCfg:GetID();

		g_editPinID = NO_EDIT_PIN_ID;
		pPlayerCfg:DeleteMapPin(deletePinID);
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
	PlayerTarget_OnPlayerInfoChanged( playerID, Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true);
end

function OnLocalPlayerChanged()
	g_playerTarget.targetID = Game.GetLocalPlayer();
	PopulateTargetPull(Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull);

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
	PopulateTargetPull(Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull);
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

	local canChangeName = GameCapabilities.HasCapability("CAPABILITY_RENAME");
	if(not canChangeName) then
		Controls.PinFrame:SetHide(true);
	end

end
Initialize();


