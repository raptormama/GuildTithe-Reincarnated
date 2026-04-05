--[[ enUS.lua -- ENGLISH and DEFUALT LOCALIZATION FOR GUILDTITHE]]

-- Make a localization table if it's not there:
if not GTLocale then
	GTLocale = {}
end

function GTLocale.Get_enUS_Strings()
	local L = {}
L["ChatArgNotFound"] = "§b\"%s\"§r isn't a valid argument for §b\"%s\"§r."
L["ChatAutoDepositDisabled"] = "Automatic deposits are disabled."
L["ChatCommandNotFound"] = "§b\"%s\"§r was not found. §b/gt help§r shows the commands list."
L["ChatDepositTitheAmount"] = "Automatically deposited %s."
L["ChatDepositToGoldCap"] = "Automatically deposited %s of %s (guild bank at gold cap)."
L["ChatHelpLine1"] = "=== Version §b%s§r - Help ==="
L["ChatHelpLine2"] = "total -- Show the total amount you've tithed."
L["ChatHelpLine3"] = "Arguments in brackets are optional. Commands separated by slashes are interchangeable."
L["ChatHelpLine4"] = "options/config -- Open the options frame."
L["ChatHelpLine5"] = "set coppervalue -- Set current tithe to value in copper."
L["ChatHelpLine6"] = "reset (tithe) -- reset the current tithe."
L["ChatHelpLine7"] = "reset pos -- Reset the Mini-Frame's position."
L["ChatHelpLine8"] = "reset config -- Reset this character's config."
L["ChatHelpLine9"] = "current/tithe -- Show your current outstanding tithe."
L["ChatHelpLine10"] = "mini -- Toggle the Mini-frame."
L["ChatHelpLine11"] = "mini lock -- Lock or unlock the Mini-frame."
L["ChatHelpLine12"] = "debug (on/true/off/false) -- Toggle debug mode on and off."
L["ChatHelpLine13"] = "chat (on/true/off/false) -- Toggle chat output on and off."
L["ChatHelpLine14"] = "prettyldb (on/true/off/false) -- Toggle LDB text vs graphical display."
L["ChatHelpLine15"] = "bankhide (on/true/off/false) -- Deposit tithe on bank window hide (default false)"

L["ChatMiniFrameLock"] = "Mini-Frame locked."

L["ChatCommandSetNegative"] = "Tithe cannot be negative."
L["ChatCommandSetOverCap"] = "Tithe cannot exceed gold cap."
L["ChatCommandSetSyntax"] = "Syntax: /gt set <amount in copper>."
L["ChatCommandToggleDebug"] = "Debug mode §c%s§r."
L["ChatCommandToggleChat"] = "Chat mode §c%s§r."
L["ChatCommandDepositOnBankHide"] = "Deposit on bank window frame hide §c%s§r."

L["ChatMiniFrameUnlock"] = "Mini-frame unlocked."
L["ChatNotEnoughFunds"] = "You don't have enough money to do that!"
L["ChatNothingToDeposit"] = "There's nothing to deposit!"
L["ChatNoValidDeposits"] = "No vaild windows are open for depositing!"
L["ChatOutstandingTithe"] = "Current Tithe - %s"
L["ChatSpammyCollectedAmount"] = "%s collected from §b%s§r"
L["ChatSpammyNotCollectingSource"] = "Not collecting tithes from §b%s§r"
L["DialogResetConfigText"] = [=[§cWARNING!§r
Resetting GuildTithe's settings can't be undone.

Are you sure?]=]
L["DialogResetTitheText"] = "Are you sure you want to reset your current tithe?"
L["DialogSkinRequiresReload"] = "Enabling or disabling this feature requires you to reload your User Interface to see the changes."
L["Loaded"] = "Guild Tithe version §b%s§r loaded. §b/gt help§r shows command help."
L["MiniFrameCurrentTitheText"] = "Current Tithe:"
L["OptionsAutoDeposit"] = "Automatically deposit collected tithe"
L["OptionsDebug"] = "Debug Mode"
L["OptionsElvSkin"] = "Enable ElvUI Skin"
L["OptionsExtra2Text"] = "Extra configuration options"
L["OptionsExtraText"] = "Allow collection from..."
L["OptionsLootText"] = "Looted money"
L["OptionsMailText"] = "Mail"
L["OptionsMerchantText"] = "Merchants"
L["OptionsQuestText"] = "Quest Rewards"
L["OptionsSpammy"] = "Output to chat"
L["OptionsTitle"] = "GuildTithe Options"
L["OptionsTotalTitheText"] = "Grand Total - %s"
L["OptionsTradeText"] = "Trade"
L["OptionsVersionText"] = "%s"
L["TooltipLDBDescriptionCurrent"] = "This is your current tithe."
L["TooltipLDBDescriptionTotal"] = "This is your total tithe."

	return L
end

