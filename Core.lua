--[[
------------------------------------------------------------------------
	Project: GuildTithe Reincarnated
	File: Core rev. 150
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
local WARBAND_GOLD_CAP = GOLD_CAP * 10 -- in enUS, anyway

-- Within-addon variable namespace to communicate with GUI
GuildTitheReincarnated = {}

-- This is now how we handle currency display.
Currency = LibStub("Krowi_Currency-1.0")

-- If a restriction is active, return type.
-- If none are active, return -1.
-- 'mode' argument is for printing info in debug displays and doesn't change
-- how the function works. Any string can be passed in there.

local lastAnnounceTime = GetTime()

function SecretsActive()
	local j = -1
	for i=0,4,1 do
		if C_RestrictedActions.IsAddOnRestrictionActive(i) then
			j = i
		end
	end
	
	return j
end

-- Simple round function for GUI handling (Lua doesn't have a round function)
function GuildTitheReincarnated.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Pretty-print for GUI use (useicons is a boolean. Usually want to pass along PrettyLDB here)
function GuildTitheReincarnated.PrettyPrint(amount, useicons)
	if useicons then
		amount = Currency:FormatMoney(amount, {
			MoneyLabel = "Icon",
			ThousandsSeparator = "Comma",
			MoneyColored = true,
			TextureSize = 10,
		})
	else
		amount = Currency:FormatMoney(amount, {
			MoneyLabel = "Text",
			ThousandsSeparator = "Comma",
			MoneyColored = true,
		})
	end

	return amount
end

function IsWarbandBankOpen()
    local types = C_Bank.FetchViewableBankTypes()
    if not types then return false end

    for _, bankType in ipairs(types) do
        if bankType == Enum.BankType.Account then
            return true
        end
    end

    return false
end

function GuildTitheReincarnated.ToggleMinimapIcon()
	GuildTithe_SavedDB.HideMinimapIcon = not GuildTithe_SavedDB.HideMinimapIcon
	if GuildTithe_SavedDB.HideMinimapIcon then
		LDBIcon:Hide("GuildTitheMinimapButton")
	else
		LDBIcon:Show("GuildTitheMinimapButton")
	end
end

function GuildTitheReincarnated.TogglePrettyLDB()
	GuildTithe_SavedDB.PrettyLDB = not GuildTithe_SavedDB.PrettyLDB
end

function DrawTooltip(tooltip)
	if tooltip and tooltip.AddLine then tooltip:SetText("GuildTithe") end
	if GuildTithe_SavedDB.LDBDisplayTotal then
		tooltip:AddLine(L["TooltipLDBDescriptionTotal"], 0.8, 0.8, 0.8, 1)
	else
		tooltip:AddLine(L["TooltipLDBDescriptionCurrent"], 0.8, 0.8, 0.8, 1)
	end
	tooltip:AddLine("\n" .. GuildTitheReincarnated.GetLDBCoinString(), 1, 1, 1, 1)
	tooltip:AddLine("\n" .. L["TooltipLDBDescriptionInstructions"], 0.8, 0.8, 0.8, 1)
	tooltip:Show()
end

-- debugArgs: Returns literal "nil" or the tostring of all of the arguments passed to it.
function E:debugArgs(...)
	local tmp = {}
	if SecretsActive() <= 0 then
		for i = 1, select("#", ...) do
			tmp[i] = tostring(select(i, ...)) or "nil"
		end
		return table.concat(tmp, ", ") or "nil"
	else
		self:PrintDebug("A secret error caused an issue with debug messaging.")
		return "nil"
	end
end

-- Get a string for the current version of the addon.
function E:GetVerString()
	CURRENT_REVISION = 150
	local v, rev = (C_AddOns.GetAddOnMetadata(addonName, "VERSION") or "???"), CURRENT_REVISION
	
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

GuildTitheReincarnated.version = E:GetVerString()

local SettingsDefaults = {
	SettingsVer = 2,
	CollectSource = {
		Quest = -1,
		Merchant = -1,
		Mail = -1,
		Loot = -1,
		Trade = -1
	},
	CollectFrom = {
		Quest = false,
		Merchant = false,
		Mail = false,
		Loot = false,
		Trade = false
	},
	AutoDeposit = true,
	TimeOfLastDeposit = -1,
	TypeOfLastDeposit = "Unknown",
	AmountOfLastDeposit = -1,
	Spammy = false,
	TotalTithe = 0,
	CurrentTithe = 0,
	MiniFrameShown = true,
	MiniFrameLocked = false,
	GUIIsShown = false,
	--SkinElvUI = true,
	LDBDisplayTotal = false,
	PrettyLDB = true,
	DepositOnBankHide = false,
	DepositToGuild = true,
	DepositToAccount = false,
	MinimapButtonInfo = {
		["minimapPos"] = 100,
		["hide"] = false,
	},
}

-- Storage for current/total tithe amounts for display in GUI
GuildTitheReincarnated.CurrentTithe, GuildTitheReincarnated.TotalTithe = 0

-- Get the coin string for the databroker icon, because it needs to be shorter.
function GuildTitheReincarnated.GetLDBCoinString()
	if GuildTithe_SavedDB.PrettyLDB then
		GuildTitheReincarnated.CurrentTithe = GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.CurrentTithe, true)
		GuildTitheReincarnated.TotalTithe = GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.TotalTithe, true)
	else
		GuildTitheReincarnated.CurrentTithe = GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.CurrentTithe, false)
		GuildTitheReincarnated.TotalTithe = GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.TotalTithe, false)
	end

	if GuildTithe_SavedDB.LDBDisplayTotal then
		return "Total: " .. GuildTitheReincarnated.TotalTithe
	else
		return "Tithe: " .. GuildTitheReincarnated.CurrentTithe
	end
end

function E:Init()
	--[===[@alpha@
	E._DebugMode = true
	--@end-alpha@]===]

	-- When we first load, the GUI isn't displaying
	GuildTithe_SavedDB.GUIIsShown = false

	E.Info = {}
	--local MinimapIcon = LibStub("LibDBIcon-1.0")
	
	local t = {
		type = "data source",
		text = "GuildTithe",
		icon = "Interface\\ICONS\\inv_misc_coin_17.blp",
		label = "Tithe",
		OnClick = function(frame, button)
			GameTooltip:Hide()
			if button == "LeftButton" then
				GuildTitheReincarnated.DrawMainUIFrame()
			elseif button == "RightButton" then
				GuildTithe_SavedDB.LDBDisplayTotal = not GuildTithe_SavedDB.LDBDisplayTotal
			end
		end,
		OnTooltipShow = function(tooltip)
			if tooltip and tooltip.AddLine then
				tooltip:SetText("GuildTithe")
				if GuildTithe_SavedDB.LDBDisplayTotal then
					tooltip:AddLine(L["TooltipLDBDescriptionTotal"], 0.8, 0.8, 0.8, 1)
				else
					tooltip:AddLine(L["TooltipLDBDescriptionCurrent"], 0.8, 0.8, 0.8, 1)
				end
				tooltip:AddLine("\n" .. GuildTitheReincarnated.GetLDBCoinString(), 1, 1, 1, 1)

				tooltip:AddLine("\n" .. L["TooltipLDBDescriptionInstructions"], 1, 1, 1, 1)
				tooltip:Show()
			end
		end,
	}

	E.Info.LDBData = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("GuildTithe", t)

	-- Initialise GUI display track for new GUI
	if GuildTithe_SavedDB.GUIIsShown == nil then GuildTithe_SavedDB.GUIIsShown = false end

	-- existing users won't have a setting for PrettyLDB/when to deposit. Fix that. (Now defaulting to on)
	if (GuildTithe_SavedDB.PrettyLDB == nil or GuildTithe_SavedDB.PrettyLDB == '') then
		GuildTithe_SavedDB.PrettyLDB = true
	end

	if GuildTithe_SavedDB.DepositOnBankHide == nil then
		GuildTithe_SavedDB.DepositOnBankHide = false
	end

	-- Handle it when the user hasn't yet had a version that can handle account deposit.
	-- Match the defaults that are set for new users or when settings are reset.
	if (GuildTithe_SavedDB.DepositToGuild == nil) and (GuildTithe_SavedDB.DepositToAccount == nil) then
		GuildTithe_SavedDB.DepositToGuild = true
		GuildTithe_SavedDB.DepositToAccount = false
	end

	-- Set up new collect-from checkbox state storage for existing users. The new GUI
	-- uses a slightly different setup to enable categories, but ties into existing code.
	if GuildTithe_SavedDB.CollectFrom == nil then
		GuildTithe_SavedDB.CollectFrom = {"Quest","Merchant","Mail","Loot","Trade"}
		for i,v in pairs(GuildTithe_SavedDB.CollectSource) do
			if v >= 1 then
				GuildTithe_SavedDB.CollectFrom[i] = true
			else
				GuildTithe_SavedDB.CollectFrom[i] = false
			end
		end
	end

	-- Set up tithe date/time tracking for new installs/updates
	if GuildTithe_SavedDB.TimeOfLastDeposit == nil then GuildTithe_SavedDB.TimeOfLastDeposit = -1 end
	if GuildTithe_SavedDB.TypeOfLastDeposit == nil then GuildTithe_SavedDB.TypeOfLastDeposit = "Unknown" end
	if GuildTithe_SavedDB.AmountOfLastDeposit == nil then GuildTithe_SavedDB.AmountOfLastDeposit = -1 end

	-- print all keys of table `t'
	print("debug")
    for k in pairs(GuildTithe_SavedDB.CollectFrom) do print(k) end

	-- Initialise minimap button.
	if GuildTithe_SavedDB.MinimapButtonInfo == nil then
		GuildTithe_SavedDB.MinimapButtonInfo = {
			minimapPos = 100,
			hide = false
		}
	end

	LDB = LibStub("LibDataBroker-1.1", true)
	LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
	if LDB then
		local GTIcon = LDB:NewDataObject("GuildTitheMinimapButton", {
		type = "launcher",
			text = "GuildTithe",
			icon = "Interface\\ICONS\\inv_misc_coin_17.blp",
			OnClick = function(_, button)
					if button == "LeftButton" then
						if GuildTithe_SavedDB.GUIIsShown then
							GuildTithe_SavedDB.GUIIsShown = false
							AceGUI:Release(GuildTitheReincarnated.GTSettingsFrame)
						else
							GuildTitheReincarnated.DrawMainUIFrame()
						end
					end
				end,
				OnTooltipShow = function(tooltip)
					DrawTooltip(tooltip)
				end,
			})
		if LDBIcon then
			LDBIcon:Register("GuildTitheMinimapButton", GTIcon, GuildTithe_SavedDB.MinimapButtonInfo)
		end
	end
end

function GuildTitheReincarnated:HandleSliderChange(source, newvalue)
	GuildTithe_SavedDB.CollectSource[source] = (GuildTitheReincarnated.round(newvalue,0))
end

function GuildTitheReincarnated:HandleCheckboxChange(source,newvalue)
	if newvalue then
		GuildTithe_SavedDB.CollectFrom[source] = true
	end
	if not newvalue then
		GuildTithe_SavedDB.CollectFrom[source] = false
	end
end

function GuildTitheReincarnated:HandleDepositChange(source,newvalue)
	if source == "Guild" then GuildTithe_SavedDB.DepositToGuild = newvalue end
	if source == "Account" then GuildTithe_SavedDB.DepositToAccount = newvalue end
end

function E:ResetCurrentTithe()
	GuildTithe_SavedDB.CurrentTithe = 0
end

-- Reset default settings
function E:ResetConfig()
	GuildTithe_SavedDB = SettingsDefaults
end

-- This is used to check the special tithe amounts for merchant/mail/trade.
-- They all need the same function, but have slightly different methods. This way is faster.
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
	self:PrintDebug(self:debugArgs(GOLD, SILVER, COPPER))

	-- Make some storage for the tithe amount
	local titheAmount

	-- Checking the source of the money event
	-- From Loot, Quest
	if source == "Loot" or source == "Quest" then
		local arg1 = ...
		--Try and parse the current amount from the string.
		local g, s, c
		if canaccessvalue (arg1) then
			g = tonumber(arg1:match("(%d+)%s" .. GOLD)) or 0
			s = tonumber(arg1:match("(%d+)%s" .. SILVER)) or 0
		    c = tonumber(arg1:match("(%d+)%s" .. COPPER)) or 0
		else
			g = 0 --Unfortunately, in combat lockdown we have to be wary of taint.
			s = 0 --This should only affect attempts to loot during boss encounters.
			c = 0 --Alas, exceptions aren't up to addons. We deposit when we can.
		end

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
	local warband = C_Bank.FetchDepositedMoney(Enum.BankType.Account)

	if not IsWarbandBankOpen() then
		if not isMail and (bank + tithe > GOLD_CAP) then
			tithe = GOLD_CAP - bank
		end
	else
		if not isMail and (warband + tithe > WARBAND_GOLD_CAP) then
			tithe = WARBAND_GOLD_CAP - warband
		end
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
			tithe = tonumber(tithe)
			GuildTithe_SavedDB.AmountOfLastDeposit = tithe
			
			-- format this for GUI
			GuildTitheReincarnated.AmountOfLastDeposit = GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.AmountOfLastDeposit,
				GuildTithe_SavedDB.PrettyLDB)

			if not GuildTithe_SavedDB.DepositOnBankHide then
				C_Timer.After(2, function()
						if IsWarbandBankOpen() then
							C_Bank.DepositMoney(Enum.BankType.Account, tithe)
							GuildTithe_SavedDB.TypeOfLastDeposit = "Warband"
						else
							--C_Bank.DepositMoney(Enum.BankType.Guild, tithe) --This didn't work for me, but should have. Weird.
							DepositGuildBankMoney(tithe) --So we use the old method for now
							GuildTithe_SavedDB.TypeOfLastDeposit = "Guild"
						end
					end)
			else
				if IsWarbandBankOpen() then
					C_Bank.DepositMoney(Enum.BankType.Account, tithe)
					GuildTithe_SavedDB.TypeOfLastDeposit = "Warband"
				else
					--C_Bank.DepositMoney(Enum.BankType.Guild, tithe)
					DepositGuildBankMoney(tithe)
					GuildTithe_SavedDB.TypeOfLastDeposit = "Guild"
				end
			end
		end
	end	

	if GuildTithe_SavedDB.Spammy or E._DebugMode then
		if tithe ~= GuildTithe_SavedDB.CurrentTithe then
			self:PrintMessage(format(L.ChatDepositToGoldCap,
				GuildTitheReincarnated.PrettyPrint(tithe,GuildTithe_SavedDB.PrettyLDB),
				GuildTitheReincarnated.PrettyPrint(GuildTithe_SavedDB.CurrentTithe,GuildTithe_SavedDB.PrettyLDB)),
				false, E._DebugMode
			)
		else
			self:PrintMessage(format(L.ChatDepositTitheAmount,
				GuildTitheReincarnated.PrettyPrint(tithe,GuildTithe_SavedDB.PrettyLDB),
				false, E._DebugMode)
			)
		end
	end

	if not E._DebugMode then
		GuildTithe_SavedDB.TotalTithe = GuildTithe_SavedDB.TotalTithe + tithe
		GuildTithe_SavedDB.CurrentTithe = GuildTithe_SavedDB.CurrentTithe - tithe

		if not GuildTithe_SavedDB.LDBDisplayTotal or not E.ShowTotalTimer then
			GuildTithe_SavedDB.LDBDisplayTotal = true
			E.ShowTotalTimer = E:SetTimer(10, function() GuildTithe_SavedDB.LDBDisplayTotal = false; end)
		end
	end

	GuildTithe_SavedDB.TimeOfLastDeposit = date() -- local OS clock time as UNIX epoch
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
			--self:ResetWindowSettings()
		elseif args == "config" then
			StaticPopup_Show("GUILDTITHE_RESETCONFIG")
		else
			self:PrintMessage(format(L.ChatArgNotFound, args or "", cmd), true)
		end

	-- Show the options frame, we don't save this
	elseif cmd == "options" or cmd == "config" or cmd == "show" then
		GuildTitheReincarnated.DrawMainUIFrame()

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
		E.Info.LDBData.text = GuildTitheReincarnated.GetLDBCoinString()

	-- Show/hide or toggle the minimap icon.
	elseif cmd == "icon" then
		GuildTitheReincarnated.ToggleMinimapIcon()

	-- Show/hide or toggle the mini frame.
	elseif cmd == "mini" then
		print(L["FeatureDeprecated"])
		
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
end

function E.EventHandler(self, event, ...)
	local arg1, arg2, arg3, arg4 = ...

	if event == "ADDON_LOADED" and arg1 == "GuildTithe" then
		return E:Init()

	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Establish database
		if not GuildTithe_SavedDB or GuildTithe_SavedDB.SettingsVer < SettingsDefaults.SettingsVer then
			GuildTithe_SavedDB = SettingsDefaults
		end

		if not E.Loaded then
			E:PrintMessage(format(L.Loaded, E:GetVerString()))
			-- Execute minimap icon display check so user choice persists across UI loads.
			if GuildTithe_SavedDB.HideMinimapIcon then
				LDBIcon:Hide("GuildTitheMinimapButton")
			else
				LDBIcon:Show("GuildTitheMinimapButton")
			end
			E:PrintDebug("Loaded in §bDebug Mode§r! This will print a lot of extra, mostly useless information to your chat. You can disable debug mode by unchecking the box marked \"Debug mode\" in the options.")
			E:SetTimer(2, function()
					E.Info.LDBData.text = GuildTitheReincarnated.GetLDBCoinString();
			end, true, "GT_CTUPDATE")
			E.Loaded = true
		end

	-- GUILDBANKFRAME_OPENED: The GB was opened, deposit the outstanding tithe.
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.GuildBanker then
		if not GuildTithe_SavedDB.DepositOnBankHide then
			if GuildTithe_SavedDB.DepositToGuild then E:DepositTithe() end
		end
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.Banker then
		if not GuildTithe_SavedDB.DepositOnBankHide then
			if GuildTithe_SavedDB.DepositToAccount then E:DepositTithe() end
		end
		elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and tonumber(arg1) == Enum.PlayerInteractionType.AccountBanker then
		if not GuildTithe_SavedDB.DepositOnBankHide then
			if GuildTithe_SavedDB.DepositToAccount then E:DepositTithe() end
		end
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and tonumber(arg1) == Enum.PlayerInteractionType.GuildBanker then
		if GuildTithe_SavedDB.DepositOnBankHide then
			if GuildTithe_SavedDB.DepositToGuild then E:DepositTithe() end
		end
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and tonumber(arg1) == Enum.PlayerInteractionType.Banker then
		if GuildTithe_SavedDB.DepositOnBankHide then
			if GuildTithe_SavedDB.DepositToAccount then E:DepositTithe() end
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
		GuildTitheReincarnated.DrawMainUIFrame()
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
