-- © 2023 Josh 'Kkthnx' Russell All Rights Reserved

-- Create a frame for the module
local Module = CreateFrame("Frame")
-- Register the events for the module
Module:RegisterEvent("PLAYER_LOGIN")
Module:RegisterEvent("VARIABLES_LOADED")

-- Create a lookup table to store the translations
local LocaleTable = {
	-- Translations for the stranger
	["Stranger_deDE"] = "Unbekannt",
	["Stranger_esES"] = "Desconocido",
	["Stranger_esMX"] = "Desconocido",
	["Stranger_frFR"] = "Étranger",
	["Stranger_itIT"] = "Sconosciuto",
	["Stranger_koKR"] = "외딴 사람",
	["Stranger_ptBR"] = "Estranho",
	["Stranger_ruRU"] = "Незнакомец",
	["Stranger_zhCN"] = "陌生人",
	["Stranger_zhTW"] = "陌生人",
	-- Translations for the desc of the addon
	["TradeTargetInfo_deDE"] = "Zeigt den Beziehungsstatus (Fremder, Freund oder Gildenmitglied) des Handelsziels im Handelsfenster an.",
	["TradeTargetInfo_esES"] = "Muestra el estado de la relación (extraño, amigo o miembro de la hermandad) del objetivo del comercio en la ventana de comercio.",
	["TradeTargetInfo_esMX"] = "Muestra el estado de la relación (extraño, amigo o miembro de la hermandad) del objetivo del comercio en la ventana de comercio.",
	["TradeTargetInfo_frFR"] = "Affiche le statut de la relation (inconnu, ami ou membre de guilde) de la cible du commerce dans la fenêtre de commerce.",
	["TradeTargetInfo_itIT"] = "Visualizza lo stato delle relazioni (sconosciuto, amico o membro della gilda) del bersaglio del commercio nella finestra di commercio.",
	["TradeTargetInfo_koKR"] = "거래 대상의 관계 상태 (외로운, 친구 또는 길드 멤버)를 거래 프레임에서 표시합니다.",
	["TradeTargetInfo_ptBR"] = "Exibe o status da relação (estranho, amigo ou membro da guilda) do alvo da negociação na janela de negociação.",
	["TradeTargetInfo_ruRU"] = "Отображает статус отношений (незнакомец, друг или член гильдии) цели торговли в окне торговли.",
	["TradeTargetInfo_zhCN"] = "在交易窗口中显示交易目标的关系状态（陌生人、朋友或公会成员）。",
	["TradeTargetInfo_zhTW"] = "顯示交易對象的關係狀態（陌生人、朋友或公會成員）於交易框架中。",
}

-- Retrieve the current locale and store the translation in `ThanksText`
-- If the locale is not found in the `LocaleTable`, the default value of "Stranger" is used
local StrangerText = LocaleTable["Stranger_" .. GetLocale()] or "Stranger"

-- Retrieve the translation for the `TradeTargetInfo` text, using the current locale
local TradeTargetInfoText = LocaleTable["TradeTargetInfo_" .. GetLocale()] or "Displays the relationship status (stranger, friend, or guild member)|nof the trade target in the Trade Frame."

-- Create a table to store class colors
local TradeTargetClassColors = {}

-- Get the class colors from either CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

-- Store the class colors in TradeTargetClassColors table
for class, value in pairs(colors) do
	TradeTargetClassColors[class] = value
end

-- Get the class color of a unit based on its class
local function TradeTargetUnitClassColor(class)
	-- Get the color of the class
	local color = TradeTargetClassColors[class]

	-- If the color is not found, return default color (white)
	if not color then
		return 1, 1, 1
	end

	-- Return the color of the class
	return color.r, color.g, color.b
end

-- Get the color of a unit
local function TradeTargetUnitColor(unit)
	-- If the unit is not a player, return default color (white)
	if not UnitIsPlayer(unit) then
		return 1, 1, 1
	end

	-- Get the class of the unit
	local class = select(2, UnitClass(unit))

	-- If the class is not found, return default color (white)
	if not class then
		return 1, 1, 1
	end

	-- Return the color of the class
	return TradeTargetUnitClassColor(class)
end

-- Creates a font string to display information about the trade target
function Module:CreateTradeTargetInfo()
	-- Create a font string using the "ARTWORK" layer and "GameFontHighlightMedium" font style
	self.infoText = TradeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")

	-- Clear any previously set points for the font string
	self.infoText:ClearAllPoints()

	-- Set the position of the font string to be below the trade target's name text
	self.infoText:SetPoint("TOP", TradeFrameRecipientNameText, "BOTTOM", 0, -8)

	-- Update the color of the text that displays information about the trade target
	local function UpdateTradeTargetInfoColor()
		-- Get the RGB values for the trade target's class color
		local r, g, b = TradeTargetUnitColor("NPC")
		TradeFrameRecipientNameText:SetTextColor(r, g, b)

		-- Get the GUID of the trade target
		local guid = UnitGUID("NPC")
		if not guid then
			-- If there's no trade target, clear the text
			self.infoText:SetText("")
			return
		end

		-- Check if the trade target is a friend, guild member, or neither
		local isFriend = C_FriendList.IsFriend(guid)
		local isGuildMember = IsGuildMember(guid)
		local isBNetFriend = C_BattleNet.GetGameAccountInfoByGUID(guid)
		local text

		if isBNetFriend or isFriend then
			-- If the trade target is a friend, set the text color to yellow
			text = "|cffffff00" .. FRIEND
		elseif isGuildMember then
			-- If the trade target is a guild member, set the text color to green
			text = "|cff00ff00" .. GUILD
		else
			-- If the trade target is neither, set the text color to red
			text = "|cffff0000" .. StrangerText
		end

		-- Set the text to display the result of the check
		self.infoText:SetText(text)
	end

	if TradeTargetInfoDB.enabled then
		hooksecurefunc("TradeFrame_Update", UpdateTradeTargetInfoColor)
	end
end

function Module:UpdateTradeTargetInfo()
	-- Check if TradeTargetInfo is enabled
	if not TradeTargetInfoDB.enabled then
		-- If infoText is not nil, hide it
		if self.infoText then
			self.infoText:Hide()
		end
		return
	end

	-- If infoText is nil, create it
	if not self.infoText then
		self:CreateTradeTargetInfo()
	end

	-- Show infoText
	self.infoText:Show()
end

function Module:CreateTradeTargetInfoOptions()
	-- Determine which options panel to use
	local optionsPanel = WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE and SettingsPanel.Container or InterfaceOptionsFramePanelContainer

	-- Define the default saved variable values
	local TradeTargetInfoDefaults = {
		-- Boolean indicating if the trade target info feature is enabled
		enabled = false,
	}

	-- Create the saved variable or use the existing one
	TradeTargetInfoDB = TradeTargetInfoDB or CopyTable(TradeTargetInfoDefaults)

	-- Create the config panel frame
	self.ConfigPanel = CreateFrame("Frame")
	-- Set the name of the config panel to be displayed in the Interface Options
	self.ConfigPanel.name = "|cff669DFFTradeTargetInfo|r"

	-- Create the scroll frame and position it within the panel
	local scrollFrame = CreateFrame("ScrollFrame", nil, self.ConfigPanel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 3, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", -27, 6)

	-- Create the scroll child frame and set its width to fit within the panel
	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(optionsPanel:GetWidth() - 18)

	-- Set a minimum height for the scroll child frame
	scrollChild:SetHeight(1)

	-- Add widgets to the scrolling child frame as desired
	local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	title:SetPoint("TOP")
	title:SetText(self.ConfigPanel.name)

	local description = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	description:SetPoint("TOP", 0, -26)
	description:SetText(TradeTargetInfoText)

	-- Create the Enable/Disable checkbox for the Thanks Module
	local EnableCheckbox = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	-- Set the position of the checkbox on the config panel
	EnableCheckbox:SetPoint("TOPLEFT", 0, -80)
	-- Set the text of the checkbox
	EnableCheckbox.Text:SetText("Enable and add a player known info to the trade frame")
	-- Add an OnClick event to the checkbox
	EnableCheckbox:SetScript("OnClick", function()
		-- Save the state of the checkbox to the saved variable TradeTargetInfoDB
		TradeTargetInfoDB.enabled = EnableCheckbox:GetChecked()

		-- If the checkbox is checked (enabled), then show the button and register TRADE_SHOW event
		if TradeTargetInfoDB.enabled then
			Module:UpdateTradeTargetInfo()
			-- If the checkbox is not checked (disabled), then hide the button and unregister TRADE_SHOW event
		else
			Module:UpdateTradeTargetInfo()
		end
	end)
	EnableCheckbox:SetChecked(TradeTargetInfoDB.enabled)

	-- Add the config panel to the Interface Options
	InterfaceOptions_AddCategory(self.ConfigPanel)
end

-- Function to handle events
Module:SetScript("OnEvent", function(self, event)
	-- Check if the event is "PLAYER_LOGIN"
	if event == "PLAYER_LOGIN" then
		if TradeTargetInfoDB.enabled then
			self:CreateTradeTargetInfo()
		end
	-- Check if the event is "VARIABLES_LOADED"
	elseif event == "VARIABLES_LOADED" then
		-- Call the functions to create the options panel and unregister the event
		self:CreateTradeTargetInfoOptions()
		self:UnregisterEvent(event)
	end
end)

-- Define the slash commands for opening the options panel
SLASH_TRADETARGETINFO1 = "/tti"
SLASH_TRADETARGETINFO2 = "/tradetargetinfo"
SlashCmdList.TRADETARGETINFO = function()
	-- Open the options panel to the "Module.ConfigPanel" category
	InterfaceOptionsFrame_OpenToCategory(Module.ConfigPanel)
end
