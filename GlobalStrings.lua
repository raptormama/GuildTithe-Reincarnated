--[[
------------------------------------------------------------------------
	Project: GuildTithe
	File: GlobalStrings rev. 65
	Date: 2012-04-22T23:37:30Z
	Purpose: The Global and localizable strings for this addon
	Credits: Code written by Vandesdelca32

    Copyright (C) 2011  Vandesdelca32

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

-- Import the addon table
local addonName, Engine = ...

-- This is called if a localization can't be found for that key
local function notFound(t,k)
	return tostring("§c" .. k .. "§r")
end

-- Get and load a localization
local function GetL()
	-- Store this temporarily
	local rv
	if not GTLocale["Get_"..GetLocale().."_Strings"] then
		rv = GTLocale.Get_enUS_Strings()
	else
		rv = GTLocale["Get_"..GetLocale().."_Strings"]()
	end
	return setmetatable(rv, {__index=notFound})
end

-- BITCH, WHY DOESN'T THIS FUCKING WORK?!
local L = GetL()

-- Initialize the addon:
Engine[1] = {}
LibStub:GetLibrary("LibVan32-1.0"):Embed(Engine[1], "GuildTithe")
Engine[2] = L


_G[addonName] = Engine
