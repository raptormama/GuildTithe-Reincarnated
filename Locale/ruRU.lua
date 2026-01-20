--[[ ruRU.lua -- Russian translations -- переводы на русский язык]]

-- Translator ZamestoTV
if not GTLocale then
	GTLocale = {}
end


function GTLocale.Get_ruRU_Strings()
	local L = {}
L["ChatArgNotFound"] = "§b\"%s\"§r — недопустимый аргумент для команды §b\"%s\"§r."
L["ChatAutoDepositDisabled"] = "Автоматические взносы отключены."
L["ChatCommandNotFound"] = "§b\"%s\"§r — команда не найдена. §b/gt help§r — список команд."
L["ChatDepositTitheAmount"] = "Автоматически внесено %s."
L["ChatHelpLine1"] = "=== Версия §b%s§r — Справка ==="
L["ChatHelpLine2"] = "Аргументы в скобках — необязательные. Команды через слеш взаимозаменяемы."
L["ChatHelpLine3"] = "options / config — открыть окно настроек"
L["ChatHelpLine4"] = "reset (tithe) — сбросить текущий взнос"
L["ChatHelpLine5"] = "reset pos — сбросить положение мини-окна"
L["ChatHelpLine6"] = "reset config — сбросить настройки этого персонажа"
L["ChatHelpLine7"] = "current / tithe — показать текущую задолженность по взносу"
L["ChatHelpLine8"] = "mini — включить/выключить мини-окно"
L["ChatHelpLine9"] = "mini lock — заблокировать/разблокировать мини-окно"
L["ChatHelpLine10"] = "total — показать общую сумму внесённых взносов"
L["ChatMiniFrameLock"]   = "Мини-окно заблокировано."
L["ChatMiniFrameUnlock"] = "Мини-окно разблокировано."
L["ChatNotEnoughFunds"]      = "У вас недостаточно денег!"
L["ChatNothingToDeposit"]    = "Нечего вносить!"
L["ChatNoValidDeposits"]     = "Нет открытых окон для внесения взноса!"
L["ChatOutstandingTithe"]    = "Текущий взнос — %s"
L["ChatSpammyCollectedAmount"]    = "%s собрано с §b%s§r"
L["ChatSpammyNotCollectingSource"] = "Не собираю взносы с §b%s§r"
L["DialogResetConfigText"] = [=[§cВНИМАНИЕ!§r
Сброс настроек GuildTithe необратим.

Вы уверены?]=]
L["DialogResetTitheText"] = "Вы уверены, что хотите сбросить текущий взнос?"
L["DialogSkinRequiresReload"] = "Включение или отключение этой функции требует перезагрузки интерфейса (/reload), чтобы изменения вступили в силу."
L["Loaded"] = "Аддон Guild Tithe версии §b%s§r загружен. §b/gt help§r — справка по командам."
L["MiniFrameCurrentTitheText"] = "Текущий взнос:"
L["OptionsAutoDeposit"] = "Автоматически вносить собранный взнос"
L["OptionsDebug"] = "Режим отладки"
L["OptionsElvSkin"] = "Включить скин ElvUI"
L["OptionsExtra2Text"] = "Дополнительные настройки"
L["OptionsExtraText"] = "Разрешить сбор взносов из..."
L["OptionsLootText"] = "Добыча (лут)"
L["OptionsMailText"] = "Почта"
L["OptionsMerchantText"] = "Торговцы"
L["OptionsQuestText"] = "Награды за квесты"
L["OptionsSpammy"] = "Выводить в чат"
L["OptionsTitle"] = "Настройки GuildTithe"
L["OptionsTotalTitheText"] = "Общая сумма — %s"
L["OptionsTradeText"] = "Обмен"
L["OptionsVersionText"] = "%s"
L["TooltipLDBDescriptionCurrent"] = "Это ваш текущий взнос."
L["TooltipLDBDescriptionTotal"] = "Это ваша общая сумма взносов."

	return L
end
