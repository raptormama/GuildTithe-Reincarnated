--[[
------------------------------------------------------------------------
	Project: GuildTithe Reincarnated
	File: Core rev. 138
	Date: 2024-01-10T02:30Z
	Purpose: Core Addon Code
	Credits: Code written by Vandesdelca32, updated for Dragonflight by Miragosa

	Copyright (C) 2011  Vandesdelca32
	Copyright (C) 2024  Miragosa

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]

-- Import engine and the localization table.
local addonName, _ = ...
local E, L = unpack(select(2, ...))
local GOLD_CAP = (9999999 * COPPER_PER_GOLD) + (99 * COPPER_PER_SILVER) + 99

-- debugArgs: Returns literal "nil" or the tostring of all of the arguments passed to it.
function E:debugArgs(...)
	local tmp = {}
	for i = 1, select("#", ...) do
		tmp[i] = tostring(select(i, ...)) or "nil"
	end
	if not IsSecretValue(table) then return table.concat(tmp, ", ") else return nil end
end

-- Get a string for the current version of the addon.
function E:GetVerString()
	CURRENT_REVISION = 138
	local v, rev = (C_AddOns.GetAddOnMetadata(addonName, "VERSION") or "???"), CURRENT_REVISION

	--[===[@debug@
	-- If this code is run, it's an unpackaged version, show this:
	if v == "release_v2.6.0" then v = "DEV_VERSION"; end
	--@end-debug@]===]

	if short then
		-- Try to discern what release stage:
		if strfind(v, "release") then
			return "r" .. rev
		elseif strfind(v, "beta") then
			return "b" .. rev
		else
			return "a" .. rev
		end
	end
	return v .. "." .. rev
end

local SettingsDefaults = {
	SettingsVer = 2,
	CollectSource = {
		Quest = -1,
		Merchant = -1,
		Mail = -1,
		Loot = -1,
		Trade = -1
	},
	AutoDeposit = true,
	Spammy = false,
	TotalTithe = 0,
	CurrentTithe = 0,
	MiniFrameShown = true,
	MiniFrameLocked = false,
	SkinElvUI = true,
	LDBDisplayTotal = false,
	PrettyLDB = false,
	DepositOnBankHide = false,
}

-- Get the coin string for the databroker icon, because it needs to be shorter.
local function GetLDBCoinString()
	local text = ""
	local ct = GuildTithe_SavedDB.CurrentTithe
	local tt = GuildTithe_SavedDB.TotalTithe

	if GuildTithe_SavedDB.LDBDisplayTotal then
		local gold = floor(tt / COPPER_PER_GOLD)
		local silver = floor(tt / SILVER_PER_GOLD) % COPPER_PER_SILVER
		local copper = floor(tt % COPPER_PER_SILVER)
		if gold ~= 0 then
			text = format("%s|cffffd700g|r %s|cffc7c7cfs|r %s|cffeda55fc|r", gold, silver, copper)
		elseif silver ~= 0 then
			text = format("%s|cffc7c7cfs|r %s|cffeda55fc|r", silver, copper)
		else
			text = format("%s|cffeda55fc|r", copper)
		end
	else
		local gold = floor(ct / COPPER_PER_GOLD)
		local silver = floor(ct / SILVER_PER_GOLD) % COPPER_PER_SILVER
		local copper = floor(ct % COPPER_PER_SILVER)
		if gold ~= 0 then
			text = format("%s|cffffd700g|r %s|cffc7c7cfs|r %s|cffeda55fc|r", gold, silver, copper)
		elseif silver ~= 0 then
			text = format("%s|cffc7c7cfs|r %s|cffeda55fc|r", silver, copper)
		else
			text = format("%s|cffeda55fc|r", copper)
		end
	end

	if GuildTithe_SavedDB.PrettyLDB then
		if GuildTithe_SavedDB.LDBDisplayTotal then
			return "Total: " .. GetMoneyString(tt,true)
		else
			return "Tithe: " .. GetMoneyString(ct, true)
		end
	else
		return text
	end
end

function E:Init()
	--[===[@alpha@
	E._DebugMode = true
	--@end-alpha@]===]

	E.Info = {}

	-- Set up the LDB datastream
	local t = {
		type = "data source",
		text = "",
		icon = "Interface\\ICONS\\inv_misc_coin_17.blp",
		label = "Tithe",
		OnClick = function(frame, button)
			GameTooltip:Hide()
			if button == "LeftButton" then
				E.FrameScript_MiniTitheFrameOnClick()
			elseif button == "RightButton" then
				if not GuildTithe_SavedDB.LDBDisplayTotal then
					GuildTithe_SavedDB.LDBDisplayTotal = true
				else
					GuildTithe_SavedDB.LDBDisplayTotal = false
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			if tooltip and tooltip.AddLine then
				tooltip:SetText("GuildTithe")
				if GuildTithe_SavedDB.LDBDisplayTotal then
					tooltip:AddLine(L.TooltipLDBDescriptionTotal, 0.8, 0.8, 0.8, 1)
				else
					tooltip:AddLine(L.TooltipLDBDescriptionCurrent, 0.8, 0.8, 0.8, 1)
				end
				tooltip:AddLine("\nHint: Left-Click with the guild bank or a letter open to deposit your tithe! Right-Click to toggle between total and current tithes.", 0, 1, 0, 1)
				tooltip:Show()
			end
		end,
	}
	E.Info.LDBData = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("GuildTithe", t)

	-- Check the settings:
	if not GuildTithe_SavedDB or GuildTithe_SavedDB.SettingsVer < SettingsDefaults.SettingsVer then
		GuildTithe_SavedDB = SettingsDefaults
	end

	-- Load the frames
	GT_MiniTitheFrame:EnableMouse(not GuildTithe_SavedDB.MiniFrameLocked)
	if GuildTithe_SavedDB.MiniFrameShown then
		GT_MiniTitheFrame:Show()
	end

	-- existing users won't have a setting for PrettyLDB/when to deposit. Fix that. (Defaults to off to preserve existing behavior)
	if (GuildTithe_SavedDB.PrettyLDB == nil or GuildTithe_SavedDB.PrettyLDB == '') then
		GuildTithe_SavedDB.PrettyLDB = false
	end

	if GuildTithe_SavedDB.DepositOnBankHide == nil then
		GuildTithe_SavedDB.DepositOnBankHide = false
	end
end

function E:ResetWindowSettings()
	GT_OptionsFrame:SetUserPlaced(false)
	GT_MiniTitheFrame:SetUserPlaced(false)
	ReloadUI()
end

function E:ResetCurrentTithe()
	GuildTithe_SavedDB.CurrentTithe = 0
end

-- Reset default settings
function E:ResetConfig()
	GuildTithe_SavedDB = SettingsDefaults
	if GT_OptionsFrame:IsShown() then
		self.UpdateOptions(GT_OptionsFrame)
	end
	return self:ResetWindowSettings()
end

-- This is used to check the special tithe amounts for merchant/mail/trade.
-- They all need the same function, but have slightly different methods. THis way is faster.
local function CheckSpecialTitheAmounts(source, startGold, finishGold)

	local titheAmount

	-- Get the 'difference' in money
	local diff
	diff = finishGold - startGold

	-- Check for profit
	if diff <= 0 then
		diff = 0
	end

	-- Update
	titheAmount = diff

	return titheAmount or 0
end

-- Quest, Merchant, Mail, Loot, Trade
-- Updates the current tithe, passing update will update the totals.
function E:UpdateOutstandingTithe(source, update, ...)
	self:PrintDebug("UpdateOutstandingTithe(" .. self:debugArgs(source, update, ...) .. ")")

	if not update then
		self.Info.CurrentGold = GetMoney()
		return
	else
		self.Info.FinishGold = GetMoney()
	end
	self:PrintDebug("   CurrentGold = " .. self:debugArgs(self.Info.CurrentGold) .. ", FinishGold = " .. self:debugArgs(self.Info.FinishGold))

	-- Try to extract what GOLD, SILVER, and COPPER are in the client language
	local GOLD = strmatch(format(GOLD_AMOUNT, 20), "%d+%s(.+)") -- This will return what's in the brackets, which on enUS would be "Gold"
	local SILVER = strmatch(format(SILVER_AMOUNT, 20), "%d+%s(.+)")
	local COPPER = strmatch(format(COPPER_AMOUNT, 20), "%d+%s(.+)")
	---self:PrintDebug(self:debugArgs(GOLD, SILVER, COPPER))


	-- Make some storage for the tithe amount
	local titheAmount

	-- Checking the source of the money event
	-- From Loot, Quest
	if source == "Loot" or source == "Quest" then
		local arg1 = ...
		--Try and parse the current amount from the string.
		local g = tonumber(arg1:match("(%d+)%s" .. GOLD)) or 0
		local s = tonumber(arg1:match("(%d+)%s" .. SILVER)) or 0
		local c = tonumber(arg1:match("(%d+)%s" .. COPPER)) or 0

		titheAmount = (g * COPPER_PER_GOLD) + (s * SILVER_PER_GOLD) + c

	-- From Merchants, or Mail, or Trade
	elseif source == "Merchant" or source == "Mail" or source == "Trade" then
		-- Check and make a table for cooldown info storage
		if not E.Info.checkDelays then
			E.Info.checkDelays = {}
		end

		--Check the cooldown timer, we're gonna hardcode 2s
		if (not E.Info.checkDelays[source]) or (GetTime() >= E.Info.checkDelays[source] + 2) then
			E.Info.checkDelays[source] = GetTime()

			-- Sanity checks.
			if not (self.Info.FinishGold and self.Info.CurrentGold) then
				E:PrintDebug("Invalid Type, proper information not available", true)
				return
			end

			-- Is this a trade? It needs special conditions
			if source == "Trade" then
				-- Trade is a bit laggy, so we pass the guessed gold amount over through this
				-- and assume that the finishgold is == currentgold+ trade amount.
				local arg1 = ...
				if tonumber(arg1) and tonumber(arg1) >= 0 then
					self:PrintDebug("   tradeGold = " .. tonumber(arg1))
					self.Info.FinishGold = self.Info.CurrentGold + tonumber(arg1)
				end
			end
			titheAmount = CheckSpecialTitheAmounts(source, self.Info.CurrentGold, self.Info.FinishGold)

		else
			self:PrintDebug("ON ".. source .." CD", true)
			return
		end
	end
	self:PrintDebug("   titheAmount = " .. tostring(titheAmount))

	-- Do some maths
	if (GuildTithe_SavedDB.CollectSource[source]
		and GuildTithe_SavedDB.CollectSource[source] >= 1) then
		-- Collecting from this source, get the actual amount we're taking from this
		local actualTithe = floor((titheAmount * (GuildTithe_SavedDB.CollectSource[source] / 100)))
		self:PrintDebug("   actualTithe = " .. tostring(actualTithe))
		GuildTithe_SavedDB.CurrentTithe = GuildTithe_SavedDB.CurrentTithe + actualTithe

		-- Clear the info table for the next guy
		self.Info.CurrentGold = nil
		self.Info.FinishGold = nil

		-- Tell the user what we collected if they want to know
		if GuildTithe_SavedDB.Spammy and actualTithe > 0 then
			self:PrintMessage(format(L.ChatSpammyCollectedAmount, C_CurrencyInfo.GetCoinTextureString(actualTithe), strlower(source)))
		end
	else
		self:PrintDebug("   " .. source .. " not collecting", true)
		-- if GuildTithe_SavedDB.Spammy then
		-- 	self:PrintMessage(format(L.ChatSpammyNotCollectingSource, source))
		-- end
	end
end


-- Handles depositing the tithe
-- NB: deposit by mail won't work when mailbox replacement addons are active e.g. Tradeskillmaster
function E:DepositTithe(clicked, isMail)
	self:PrintDebug("DepositTithe(".. self:debugArgs(clicked, isMail) .. ") -- ACTUAL DEPOSIT IS DISABLED IN DEBUG MODE")
	if not clicked and not GuildTithe_SavedDB.AutoDeposit then
		if GuildTithe_SavedDB.Spammy then
			self:PrintMessage(L.ChatAutoDepositDisabled)
		end
		self:PrintDebug("   AutoDeposit Disabled")
		return
	end

	-- Sanity Check, (stop the error speech when trying to deposit 0c)
	if GuildTithe_SavedDB.CurrentTithe == 0 then
		if GuildTithe_SavedDB.Spammy then
			self:PrintMessage(L.ChatNothingToDeposit)
		end
		return
	end


	-- auto prorate tithe when bank will exceed GOLD_CAP
	local tithe = GuildTithe_SavedDB.CurrentTithe
	local bank = GetGuildBankMoney()

	if not isMail and (bank + tithe > GOLD_CAP) then
		tithe = GOLD_CAP - bank
	end

	-- Make sure the player has enough money first, then spam them out if they don't!
	if GetMoney() < tithe then
		self:PrintMessage(L["ChatNotEnoughFunds"], true)
		return
	end

	-- Deposit the money, then adjust CurrentTithe and update TotalTithe
	if not E._DebugMode then
		if isMail then
			-- postal fix
			local goldAmount = floor(GuildTithe_SavedDB.CurrentTithe / COPPER_PER_GOLD)
			local silverAmount = floor((GuildTithe_SavedDB.CurrentTithe % COPPER_PER_GOLD) / COPPER_PER_SILVER)
			local copperAmount = floor(GuildTithe_SavedDB.CurrentTithe % COPPER_PER_SILVER)
			SendMailMoneyGold:SetText(goldAmount)
			SendMailMoneySilver:SetText(silverAmount)
			SendMailMoneyCopper:SetText(copperAmount)
		else
			-- begin temporary test spam
			-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Tithe before deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe))))
			-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Guild bank before deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GetGuildBankMoney()))))
			-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Own balance before deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GetMoney()))))
			-- end temporary test spam

			if not GuildTithe_SavedDB.DepositOnBankHide then
				C_Timer.After(1, function() DepositGuildBankMoney(tithe) end)
			else
				DepositGuildBankMoney(tithe)
			end
		end
	end

	if GuildTithe_SavedDB.Spammy or E._DebugMode then
		if tithe ~= GuildTithe_SavedDB.CurrentTithe then
			self:PrintMessage(format(L.ChatDepositToGoldCap, C_CurrencyInfo.GetCoinTextureString(tithe), C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe)), false, E._DebugMode)
		else
			self:PrintMessage(format(L.ChatDepositTitheAmount, C_CurrencyInfo.GetCoinTextureString(tithe), false, E._DebugMode))
		end
	end

	if not E._DebugMode then
		GuildTithe_SavedDB.TotalTithe = GuildTithe_SavedDB.TotalTithe + tithe
		GuildTithe_SavedDB.CurrentTithe = GuildTithe_SavedDB.CurrentTithe - tithe
		-- begin temporary test spam
		-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Tithe after deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe))))
		-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Guild bank after deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GetGuildBankMoney()))))
		-- print(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(format("Own balance after deposit: %s.",C_CurrencyInfo.GetCoinTextureString(GetMoney()))))
		-- end temporary test spam

		if not GuildTithe_SavedDB.LDBDisplayTotal or not E.ShowTotalTimer then
			GuildTithe_SavedDB.LDBDisplayTotal = true
			E.ShowTotalTimer = E:SetTimer(10, function() GuildTithe_SavedDB.LDBDisplayTotal = false; end)
		end
	end
end

local numHelpLines = 15
-- Print Help
function E:PrintHelpMessages()
	for i = 1, numHelpLines do
		if i == 1 then
			self:PrintMessage(format(L["ChatHelpLine1"], self:GetVerString()))
		else
			self:PrintMessage(L["ChatHelpLine" .. i])
		end
	end
	self:PrintMessage("=== Status ===")
	self:PrintMessage(format(L.ChatCommandToggleDebug, tostring(E._DebugMode)), false, E._DebugMode )
	self:PrintMessage(format(L.ChatCommandToggleChat, tostring(GuildTithe_SavedDB.Spammy)))
	self:PrintMessage(format(L.ChatCommandDepositOnBankHide ,tostring(GuildTithe_SavedDB.DepositOnBankHide)))
end

-- Handles slash commands
function E:OnChatCommand(msg)
	local cmd, args = strsplit(" ", strlower(msg))

	-- toggle debug mode without opening the config window
	if cmd == "debug" then
		if args == "on" or args == "true" then
			E._DebugMode = true
		elseif args == "off" or args == "false" then
			E._DebugMode = false
		else
			E._DebugMode = not E._DebugMode
		end
		self:PrintMessage(format(L.ChatCommandToggleDebug, tostring(E._DebugMode)), false, E._DebugMode )
		return
	end

	self:PrintDebug("OnChatCommand(" .. self:debugArgs(msg) .. ")")
	self:PrintDebug("cmd = " .. tostring(cmd) .. ", args = " .. tostring(args))

	if msg == "" or cmd == "help" then
		-- Print Help
		self:PrintHelpMessages()

	-- want to reset settings?
	elseif cmd == "reset" then
		if not args or args == "tithe" then
			StaticPopup_Show("GUILDTITHE_RESETTITHE")
		elseif args == "pos" then
			self:ResetWindowSettings()
		elseif args == "config" then
			StaticPopup_Show("GUILDTITHE_RESETCONFIG")
		else
			self:PrintMessage(format(L.ChatArgNotFound, args or "", cmd), true)
		end

	-- Show the options frame, we don't save this
	elseif cmd == "options" or cmd == "config" or cmd == "show" then
		GT_OptionsFrame:Show()

	-- Get the current tithe
	elseif cmd == "current" or cmd == "tithe" then
		self:PrintMessage(format(L.ChatOutstandingTithe, C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe)))

	-- Toggle pretty LDB display (requires more room on LDB bar than existing basic default)
	elseif cmd == "prettyldb" then
		if args == "on" or args == "true" then
			GuildTithe_SavedDB.PrettyLDB = true
		elseif args == "off" or args == "false" then
			GuildTithe_SavedDB.PrettyLDB = false
		else -- No args clause, toggle.
			GuildTithe_SavedDB.PrettyLDB = not(GuildTithe_SavedDB.PrettyLDB)
		end
		E.Info.LDBData.text = GetLDBCoinString()

	-- Show/hide or toggle the mini frame.
	elseif cmd == "mini" then
		-- Show or hide the mini frame, this can be forced, or toggled when passed with no args
		if args == "show" then
			GT_MiniTitheFrame:Show()
			GuildTithe_SavedDB.MiniFrameShown = true
		elseif args == "hide" then
			GT_MiniTitheFrame:Hide()
			GuildTithe_SavedDB.MiniFrameShown = false
		-- Lock the mini-frame
		elseif args == "lock" then -- This is a toggle
			if GuildTithe_SavedDB.MiniFrameLocked then
				self:PrintMessage(L.ChatMiniFrameUnlock)
				GT_MiniTitheFrame:EnableMouse(true)
				GuildTithe_SavedDB.MiniFrameLocked = false
			else
				self:PrintMessage(L.ChatMiniFrameLock)
				GT_MiniTitheFrame:EnableMouse(false)
				GuildTithe_SavedDB.MiniFrameLocked = true
			end
		else -- No args clause, toggle.
			if GuildTithe_SavedDB.MiniFrameShown then
				GT_MiniTitheFrame:Hide()
				GuildTithe_SavedDB.MiniFrameShown = false
			else
				GT_MiniTitheFrame:Show()
				GuildTithe_SavedDB.MiniFrameShown = true
			end
		end

	-- display tithe running total
	elseif cmd == "total" then
		self:PrintMessage(format(L.OptionsTotalTitheText, C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.TotalTithe)))

	-- set the tithe to an arbitrary value (0 to GOLD_CAP)
	elseif cmd == "set" then
		local newTithe = tonumber(args)
		if not newTithe then
			self:PrintErr(L.ChatCommandSetSyntax)
		elseif newTithe < 0 then
			self:PrintErr(L.ChatCommandSetNegative)
		elseif newTithe > GOLD_CAP then
			self:PrintErr(L.ChatCommandSetOverCap)
		else
			GuildTithe_SavedDB.CurrentTithe = newTithe
			self:PrintMessage(format(L.ChatOutstandingTithe, C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe)))
		end

	-- taggle chat output
	elseif cmd == "chat" then
		if args == "on" or args == "true" then
			GuildTithe_SavedDB.Spammy = true
		elseif args == "off" or args == "false" then
			GuildTithe_SavedDB.Spammy = false
		else -- No args clause, toggle.
			GuildTithe_SavedDB.Spammy = not GuildTithe_SavedDB.Spammy
		end
		self:PrintMessage(format(L.ChatCommandToggleChat, tostring(GuildTithe_SavedDB.Spammy)))

	-- deposit on bank window open or close (potential fix for server lag)
	elseif cmd == "bankhide" then
		if args == "on" or args == "true" then
			GuildTithe_SavedDB.DepositOnBankHide = true
		elseif args == "off" or args == "false" then
			GuildTithe_SavedDB.DepositOnBankHide = false
		else
			GuildTithe_SavedDB.DepositOnBankHide = not GuildTithe_SavedDB.DepositOnBankHide
		end
		self:PrintMessage(format(L.ChatCommandDepositOnBankHide, tostring(GuildTithe_SavedDB.DepositOnBankHide)))

	-- This is where we're going to actually print the help info... Later though.
	else
		self:PrintMessage(format(L.ChatCommandNotFound, msg), true)
	end
end

function GuildTithe_OnLoad(self)
	-- Register events
	self:RegisterEvent("ADDON_LOADED")
	-- The money events.
	self:RegisterEvent("CHAT_MSG_MONEY")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_CLOSED")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("TRADE_SHOW") -- Trade Opened
	self:RegisterEvent("TRADE_CLOSED") -- Trade closed
	self:RegisterEvent("TRADE_MONEY_CHANGED") -- Player's money was updated (used after a trade)
	self:RegisterEvent("TRADE_REQUEST_CANCEL") -- Cancelled trade.
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

	--Other events
	self:RegisterEvent("CHAT_MSG_SYSTEM") -- Quest rewards
	self:RegisterEvent("PLAYER_LEAVING_WORLD") -- For saving options when we log and the form is closed.
	self:RegisterEvent("PLAYER_ENTERING_WORLD") -- For updating the frames and output.

	self:SetScript("OnEvent", E.EventHandler)

	-- Register /commands
	SLASH_GUILDTITHE_MAIN1="/gt"
	SLASH_GUILDTITHE_MAIN2="/tithe"
	SLASH_GUILDTITHE_MAIN3="/guildtithe"

	-- We set up the slash command like this, so we can call the function as a method, instead of a table index.
	SlashCmdList["GUILDTITHE_MAIN"] = function(msg, editBox)
		E:OnChatCommand(msg)
	end

	-- Register dialogs
	StaticPopupDialogs["GUILDTITHE_RESETTITHE"] = {
		text = L.DialogResetTitheText,
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			E:ResetCurrentTithe()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["GUILDTITHE_RESETCONFIG"] = {
		text = E:ParseColorCodedString(L.DialogResetConfigText),
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			E:ResetConfig()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		showAlert = true,
		cancels = "GUILDTITHE_RESETTITHE",
	}

	StaticPopupDialogs["GUILDTITHE_SKINRELOADWARNING"] = {
		text = L.DialogSkinRequiresReload,
		button1 = OKAY,
		button2 = NO,
		OnAccept = function()
			ReloadUI()
		end,
		OnCancel = function()
			GT_OptionsFrame_Seperator_ExtraOption4:SetChecked(GuildTithe_SavedDB.SkinElvUI)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

function E.EventHandler(self, event, ...)
	local arg1, arg2, arg3, arg4 = ...

	if event == "ADDON_LOADED" and arg1 == "GuildTithe" then
		return E:Init()

	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Hide the options frame
		GT_OptionsFrame:Hide()
		-- Skin the frames
		E:SkinFrames()
		if not E.Loaded then
			E:PrintMessage(format(L.Loaded, E:GetVerString()))
			E:PrintDebug("Loaded in §bDebug Mode§r! This will print a lot of extra, mostly useless information to your chat. You can disable debug mode by unchecking the box marked \"Debug mode\" in the options.")
			E:SetTimer(2, function()
					GT_MiniTitheFrame.CurrentTithe:SetText(C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.CurrentTithe));
					E.Info.LDBData.text = GetLDBCoinString();
			end, true, "GT_CTUPDATE")
			E.Loaded = true
		end

	-- GUILDBANKFRAME_OPENED: The GB was opened, deposit the outstanding tithe.
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.GuildBanker then
		if not GuildTithe_SavedDB.DepositOnBankHide then
			E:DepositTithe()
		end
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and tonumber(arg1) == Enum.PlayerInteractionType.GuildBanker then
		if GuildTithe_SavedDB.DepositOnBankHide then
			E:DepositTithe()
		end
		-- Mail_*: Update outstanding tithe from Mail sources
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.MailInfo then
		return E:UpdateOutstandingTithe("Mail")
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and tonumber(arg1) == Enum.PlayerInteractionType.MailInfo then
		return E:UpdateOutstandingTithe("Mail", true)

	-- Merchant_*: Update outstanding tithe from merchants
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.Merchant then
		return E:UpdateOutstandingTithe("Merchant")
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and tonumber(arg1) == Enum.PlayerInteractionType.MailInfo then
		return E:UpdateOutstandingTithe("Merchant", true)
	elseif event == "MERCHANT_SHOW" then
		return E:UpdateOutstandingTithe("Merchant")
	elseif event == "MERCHANT_CLOSED" then
		return E:UpdateOutstandingTithe("Merchant", true)

	-- TRADE_*: Update trade amounts;
	elseif event == "TRADE_SHOW" then
		return E:UpdateOutstandingTithe("Trade")
	elseif event == "TRADE_REQUEST_CANCEL" then
		E.Info.TotalTradeAmount = nil
		E:UpdateOutstandingTithe("Trade", true, 0)
	elseif event == "TRADE_CLOSED" then
		E:UpdateOutstandingTithe("Trade", true, E.Info.TotalTradeAmount or 0)
		E.Info.TotalTradeAmount = nil
	elseif event == "TRADE_MONEY_CHANGED" then
		E.Info.TotalTradeAmount = TradeRecipientMoneyFrame.staticMoney

	-- CHAT_MSG_SYSTEM: Update tithe from Quest rewards
	elseif event == "CHAT_MSG_SYSTEM" then
		return E:UpdateOutstandingTithe("Quest", true, arg1)

	-- CHAT_MSG_MONEY: Update tithe from Loot
	elseif event == "CHAT_MSG_MONEY" then
		return E:UpdateOutstandingTithe("Loot", true, arg1)

	-- PLAYER_LEAVING_WORLD
	elseif event == "PLAYER_LEAVING_WORLD" then
		GT_OptionsFrame:Hide()
		-- The options frame doesn't need to remember where it was.
		GT_OptionsFrame:SetUserPlaced(false)
	end
end

-- Support addon compartment.
local aboutText = "GuildTithe";
local mouseButtonNote = "\nShow configuration window\n" ..
						"/gt for command line options"
AddonCompartmentFrame:RegisterAddon({
	text = aboutText,
	icon = "Interface\\ICONS\\inv_misc_coin_17.blp",
	notCheckable = true,
	func = function(button, menuInputData, menu)
		GT_OptionsFrame:Show()
	end,
	funcOnEnter = function(button)
		MenuUtil.ShowTooltip(button, function(tooltip)
			tooltip:SetText(aboutText .. mouseButtonNote)
		end)
	end,
	funcOnLeave = function(button)
		MenuUtil.HideTooltip(button)
	end,
})
