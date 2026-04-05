--[[
------------------------------------------------------------------------
	Project: GuildTithe
	File: Frame scripts rev. 118
	Date: 2014-10-17T00:50:40Z
	Purpose: Miscellaneous Frame Scripts.
	Credits: Code written by Vandesdelca32

    Copyright (C) 2011  Vandesdelca32
    This version made in 2023-later by Miragosa.

    Released to public domain.

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
local E, L = unpack(select(2, ...))

-- Skin the frames to look like ElvUI's frames, if it's available
function E:SkinFrames()
	if not ElvUI or not GuildTithe_SavedDB.SkinElvUI then return end
	local ElvEngine, ElvLocale, ElvProfile, ElvGlobal = unpack(ElvUI)

	local S = ElvEngine:GetModule("Skins")

	local fList = {
		"GT_MiniTitheFrame",
		"GT_OptionsFrame",
		--"GT_OptionsFrame_Title",
		"GT_OptionsFrame_Seperator",
	}
	local chbList = {
		"GT_OptionsFrame_QuestOptions_Check",
		"GT_OptionsFrame_LootOptions_Check",
		"GT_OptionsFrame_MerchantOptions_Check",
		"GT_OptionsFrame_MailOptions_Check",
        "GT_OptionsFrame_TradeOptions_Check",
		"GT_OptionsFrame_Seperator_ExtraOption1",
		"GT_OptionsFrame_Seperator_ExtraOption2",
		"GT_OptionsFrame_Seperator_ExtraOption3",
		"GT_OptionsFrame_Seperator_ExtraOption4",
	}
	local sbList = {
		"GT_OptionsFrame_QuestOptions_Slider",
		"GT_OptionsFrame_LootOptions_Slider",
		"GT_OptionsFrame_MerchantOptions_Slider",
		"GT_OptionsFrame_MailOptions_Slider",
        "GT_OptionsFrame_TradeOptions_Slider",
	}
	local ebList = {
		"GT_OptionsFrame_QuestOptions_Text",
		"GT_OptionsFrame_LootOptions_Text",
		"GT_OptionsFrame_MerchantOptions_Text",
		"GT_OptionsFrame_MailOptions_Text",
        "GT_OptionsFrame_TradeOptions_Text",
	}

	-- Here's where the magic happens
	for _, v in pairs(fList) do
		_G[v]:SetTemplate("Transparent")
	end
	-- Tweak the frames
	GT_OptionsFrame_Title:StripTextures()
	GT_OptionsFrame:SetHeight(292)
    GT_OptionsFrame:SetWidth(420)
	GT_MiniTitheFrame.CurrentTithe:Point("BOTTOM", GT_MiniTitheFrame, "BOTTOM", 0, -1)

	-- Close button
	S:HandleCloseButton(GT_OptionsFrame_CloseButton, GT_OptionsFrame)
	S:HandleCloseButton(GT_MiniTitheFrame_Close, GT_MiniTitheFrame)

	-- Check Buttons
	for _, v in pairs(chbList) do
		S:HandleCheckBox(_G[v])
		_G[v]:SetSize(24, 24)
	end

	-- Sliders. These need special handling, they need the thumbs resized or else it will make them HUUUUGE
	for _, v in pairs(sbList) do
		S:HandleSliderFrame(_G[v])
		_G[v]:SetHeight(12)
		_G[v]:GetThumbTexture():SetSize(10, 14)
		_G[v .. "Low"]:Point("TOPLEFT", _G[v], "BOTTOMLEFT", 0, -2)
		_G[v .. "High"]:Point("TOPRIGHT", _G[v], "BOTTOMRIGHT", 0, -2)
	end

	-- EditBoxes:
	for _, v in pairs(ebList) do
		S:HandleEditBox(_G[v])
		_G[v]:SetHeight(20)
	end


	-- Mark the addon as skinned
	E.ElvSkinned = true
end

-- The script called by the template, used to keep the edit box in check
function E.FrameScript_EditBoxOnEnterPressed(self)
	-- Get the text
	local num = self:GetText()

	-- Check to see if the user put a % sign in, because the field implies it is there.
	if strfind(num, "%%") then return end

	num = tonumber(num)
	if not num then return end
	if num < 1 then
		num = 1
		self:SetText("1")
	elseif num > 100 then
		num = 100
		self:SetText("100")
	end
	self:GetParent().Slider:SetValue(num)
	self:ClearFocus()
end

function E.FrameScript_UpdateOptionRow(self)
	if not self:GetChecked() then
		self:GetParent().Text:Disable();
		self:GetParent().Slider:Disable();
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	else
		self:GetParent().Slider:Enable();
		self:GetParent().Text:Enable();
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end

function E.FrameScript_OptionRowChangeState(self, state)
	if not E.ElvSkinned then
		if state == "DISABLE" then
			self:GetThumbTexture():SetVertexColor(0.5, 0.5, 0.5)
			_G[self:GetName() .. "Low"]:SetFontObject(GameFontDisableSmall)
			_G[self:GetName() .. "High"]:SetFontObject(GameFontDisableSmall)
		elseif state == "ENABLE" then
			self:GetThumbTexture():SetVertexColor(1, 1, 1)
			_G[self:GetName() .. "Low"]:SetFontObject(GameFontHighlightSmall)
			_G[self:GetName() .. "High"]:SetFontObject(GameFontHighlightSmall)
		else
			return
		end
	else
		-- Need a different method for this if we're skinning it through ElvUI
		if state == "DISABLE" then
			self:GetThumbTexture():Hide()
			_G[self:GetName() .. "Low"]:SetFontObject(GameFontDisableSmall)
			_G[self:GetName() .. "High"]:SetFontObject(GameFontDisableSmall)
		elseif state == "ENABLE" then
			self:GetThumbTexture():Show()
			_G[self:GetName() .. "Low"]:SetFontObject(GameFontHighlightSmall)
			_G[self:GetName() .. "High"]:SetFontObject(GameFontHighlightSmall)
		end
	end
end

function E.FrameScript_MiniTitheFrameOnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.Label1:SetText(L.MiniFrameCurrentTitheText)
end


function E.FrameScript_MiniTitheFrameOnClick(self, button)
	E:PrintDebug("MiniFrame OnClick()")
	if (C_AddOns.IsAddOnLoaded("Blizzard_GuildBankUI") and GuildBankFrame:IsVisible()) or
	(C_AddOns.IsAddOnLoaded("Arkinventory") and ARKINV_Frame4TitleArkBorder:IsVisible()) then
		E:DepositTithe(1)
	elseif SendMailFrame:IsVisible() then
		E:DepositTithe(1,1)
	else
		if GuildTithe_SavedDB.Spammy then
			E:PrintMessage(L.ChatNoValidDeposits, true)
		end
	end
end

-- Load the localization-specific strings
function E.LoadOptionsFrame(self)
	-- Set the strings
	self.Title.Text:SetText(L.OptionsTitle)
	self.Info.text:SetText(L.OptionsExtraText)
	self.Version.text:SetText(format(L.OptionsVersionText, E:GetVerString()))

	--Set the row's text here.
	self.QuestOptions.Check.text:SetText(L.OptionsQuestText)
	self.LootOptions.Check.text:SetText(L.OptionsLootText)
	self.MerchantOptions.Check.text:SetText(L.OptionsMerchantText)
	self.MailOptions.Check.text:SetText(L.OptionsMailText)
    self.TradeOptions.Check.text:SetText(L.OptionsTradeText)

	-- Extra Options
	self.Extra.AutoDeposit.text:SetText(L.OptionsAutoDeposit)
	self.Extra.AutoDeposit.text:SetFontObject(GameFontHighlight)

	self.Extra.Spammy.text:SetText(L.OptionsSpammy)
	self.Extra.Spammy.text:SetFontObject(GameFontHighlight)

	self.Extra.Debug.text:SetText(L.OptionsDebug)

	if ElvUI then
		self.Extra.SkinElv:Show()
		self.Extra.SkinElv.text:SetText(L.OptionsElvSkin)
		self.Extra.SkinElv.text:SetFontObject(GameFontHighlight)
	else
		self.Extra.SkinElv:Hide()
	end
end

-- Show the user thier options when they open the form.
function E.UpdateOptions(self)
	-- load options
	-- Quests?
	if (GuildTithe_SavedDB.CollectSource.Quest
		and GuildTithe_SavedDB.CollectSource.Quest ~= -1) then
		self.QuestOptions.Check:SetChecked(1)
		self.QuestOptions.Slider:SetValue(GuildTithe_SavedDB.CollectSource.Quest)
	else
		self.QuestOptions.Check:SetChecked(false)
		self.QuestOptions.Slider:SetValue(20)
	end

	-- Loot?
	if (GuildTithe_SavedDB.CollectSource.Loot
		and GuildTithe_SavedDB.CollectSource.Loot ~= -1) then
		self.LootOptions.Check:SetChecked(true)
		self.LootOptions.Slider:SetValue(GuildTithe_SavedDB.CollectSource.Loot)
	else
		self.LootOptions.Check:SetChecked(false)
		self.LootOptions.Slider:SetValue(20)
	end

	-- Merchant?
	if (GuildTithe_SavedDB.CollectSource.Merchant
		and GuildTithe_SavedDB.CollectSource.Merchant ~= -1) then
		self.MerchantOptions.Check:SetChecked(true)
		self.MerchantOptions.Slider:SetValue(GuildTithe_SavedDB.CollectSource.Merchant)
	else
		self.MerchantOptions.Check:SetChecked(false)
		self.MerchantOptions.Slider:SetValue(20)
	end

	-- Mail?
	if (GuildTithe_SavedDB.CollectSource.Mail
		and GuildTithe_SavedDB.CollectSource.Mail ~= -1) then
		self.MailOptions.Check:SetChecked(true)
		self.MailOptions.Slider:SetValue(GuildTithe_SavedDB.CollectSource.Mail)
	else
		self.MailOptions.Check:SetChecked(false)
		self.MailOptions.Slider:SetValue(20)
	end

    -- Trade?
    if (GuildTithe_SavedDB.CollectSource.Trade
		and GuildTithe_SavedDB.CollectSource.Trade ~= -1) then
        self.TradeOptions.Check:SetChecked(true)
        self.TradeOptions.Slider:SetValue(GuildTithe_SavedDB.CollectSource.Trade)
    else
        self.TradeOptions.Check:SetChecked(false)
        self.TradeOptions.Slider:SetValue(20)
    end

	-- Misc options
	self.Extra.AutoDeposit:SetChecked(GuildTithe_SavedDB.AutoDeposit)
	self.Extra.Spammy:SetChecked(GuildTithe_SavedDB.Spammy)
	self.Extra.Debug:SetChecked(E._DebugMode)
	self.Extra.SkinElv:SetChecked(GuildTithe_SavedDB.SkinElvUI)

	-- Total Tithe
	self.TotalTithe.text:SetFormattedText(L.OptionsTotalTitheText,  C_CurrencyInfo.GetCoinTextureString(GuildTithe_SavedDB.TotalTithe))

	-- Force the frame to properly update state.
	E.FrameScript_UpdateOptionRow(self.QuestOptions.Check)
	E.FrameScript_UpdateOptionRow(self.LootOptions.Check)
	E.FrameScript_UpdateOptionRow(self.MerchantOptions.Check)
	E.FrameScript_UpdateOptionRow(self.MailOptions.Check)
	E.FrameScript_UpdateOptionRow(self.TradeOptions.Check)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
end

-- Save the config when the user closes the form.
function E.SaveOptions(self)
	local GuildTithe_SavedDB = GuildTithe_SavedDB

	-- Inc tedium, we're setting the option to the value, or -1 if the check isn't set.
	-- Quest
	if self.QuestOptions.Check:GetChecked() then
		GuildTithe_SavedDB["CollectSource"]["Quest"] = self.QuestOptions.Slider:GetValue()
	else
		GuildTithe_SavedDB["CollectSource"]["Quest"] = -1
	end

	-- Loot
	if self.LootOptions.Check:GetChecked() then
		GuildTithe_SavedDB["CollectSource"]["Loot"] = self.LootOptions.Slider:GetValue()
	else
		GuildTithe_SavedDB["CollectSource"]["Loot"] = -1
	end

	-- Mail
	if self.MailOptions.Check:GetChecked() then
		GuildTithe_SavedDB["CollectSource"]["Mail"] = self.MailOptions.Slider:GetValue()
	else
		GuildTithe_SavedDB["CollectSource"]["Mail"] = -1
	end

	-- Merchant
	if self.MerchantOptions.Check:GetChecked() then
		GuildTithe_SavedDB["CollectSource"]["Merchant"] = self.MerchantOptions.Slider:GetValue()
	else
		GuildTithe_SavedDB["CollectSource"]["Merchant"] = -1
	end

    -- Trade
    if self.TradeOptions.Check:GetChecked() then
        GuildTithe_SavedDB["CollectSource"]["Trade"] = self.TradeOptions.Slider:GetValue()
    else
        GuildTithe_SavedDB["CollectSource"]["Trade"] = -1
    end

	GuildTithe_SavedDB["AutoDeposit"] = self.Extra.AutoDeposit:GetChecked()
	GuildTithe_SavedDB["Spammy"] = self.Extra.Spammy:GetChecked()
	GuildTithe_SavedDB["SkinElvUI"] = self.Extra.SkinElv:GetChecked()
	-- DebugMode is never saved, but update the user's choice:
	if self.Extra.Debug:GetChecked() then
		E._DebugMode = true
	else
		E._DebugMode = false
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
end

