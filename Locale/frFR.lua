--[[ frFR.lua -- French Translations -- Traductions françaises]]

-- Make a localization table if it's not there:
if not GTLocale then
	GTLocale = {}
end


function GTLocale.Get_frFR_Strings()
	local L = {}
	-- L["ChatArgNotFound"] = "§b\"%s\"§r isn't a valid argument for §b\"%s\"§r."
-- L["ChatAutoDepositDisabled"] = "Automatic deposits are disabled."
-- L["ChatCommandNotFound"] = "§b\"%s\"§r was not found. §b/gt help§r shows the commands list."
-- L["ChatDepositTitheAmount"] = "Automatically deposited %s."
-- L["ChatHelpLine1"] = "=== Version §b%s§r - Help ==="
-- L["ChatHelpLine10"] = "total -- Show the total amount you've tithed."
-- L["ChatHelpLine2"] = "Arguments in brackets are optional. Commands separated by slashes are interchangeable."
-- L["ChatHelpLine3"] = "options/config -- Open the options frame."
-- L["ChatHelpLine4"] = "reset (tithe) -- reset the current tithe."
-- L["ChatHelpLine5"] = "reset pos -- Reset the Mini-Frame's position."
-- L["ChatHelpLine6"] = "reset config -- Reset this character's config."
-- L["ChatHelpLine7"] = "current/tithe -- Show your current outstanding tithe."
-- L["ChatHelpLine8"] = "mini -- Toggle the Mini-frame."
-- L["ChatHelpLine9"] = "mini lock -- Lock or unlock the Mini-frame."
-- L["ChatMiniFrameLock"] = "Mini-Frame locked."
-- L["ChatMiniFrameUnlock"] = "Mini-frame unlocked."
-- L["ChatNotEnoughFunds"] = "You don't have enough money to do that!"
-- L["ChatNothingToDeposit"] = "There's nothing to deposit!"
-- L["ChatNoValidDeposits"] = "No vaild windows are open for depositing!"
-- L["ChatOutstandingTithe"] = "Current Tithe - %s"
-- L["ChatSpammyCollectedAmount"] = "%s collected from §b%s§r"
-- L["ChatSpammyNotCollectingSource"] = "Not collecting tithes from §b%s§r"
--[==[ L["DialogResetConfigText"] = [=[§cWARNING!§r
Resetting GuildTithe's settings can't be undone.

Are you sure?]=] ]==]
-- L["DialogResetTitheText"] = "Are you sure you want to reset your current tithe?"
-- L["DialogSkinRequiresReload"] = "Enabling or disabling this feature requires you to reload your User Interface to see the changes."
-- L["Loaded"] = "Guild Tithe version §b%s§r loaded. §b/gt help§r shows command help."
-- L["MiniFrameCurrentTitheText"] = "Current Tithe:"
-- L["OptionsAutoDeposit"] = "Automatically deposit collected tithe"
-- L["OptionsDebug"] = "Debug Mode"
-- L["OptionsElvSkin"] = "Enable ElvUI Skin"
-- L["OptionsExtra2Text"] = "Extra configuration options"
-- L["OptionsExtraText"] = "Allow collection from..."
-- L["OptionsLootText"] = "Looted money"
-- L["OptionsMailText"] = "Mail"
-- L["OptionsMerchantText"] = "Merchants"
-- L["OptionsQuestText"] = "Quest Rewards"
-- L["OptionsSpammy"] = "Output to chat"
-- L["OptionsTitle"] = "GuildTithe Options"
-- L["OptionsTotalTitheText"] = "Grand Total - %s"
-- L["OptionsTradeText"] = "Trade"
-- L["OptionsVersionText"] = "%s"
-- L["TooltipLDBDescriptionCurrent"] = "This is your current tithe."
-- L["TooltipLDBDescriptionTotal"] = "This is your total tithe."

	return L
end