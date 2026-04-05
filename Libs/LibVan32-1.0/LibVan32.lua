--[[
------------------------------------------------------------------------
	Project: LibVan32
	File: Core, revision 69
	Date: 2014-10-15T23:51:06Z
	Purpose: Library for common addon functions
	Credits: Code written by Vandesdelca32

	Copyright (C) 2011-2012  Vandesdelca32

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

local MAJOR, MINOR = "LibVan32-1.0", tonumber("69")

-- This is for debug builds
if not MINOR then
	MINOR = 9999
else
	MINOR = MINOR + 99
end

-- GLOBALS: DEFAULT_CHAT_FRAME
-- index locals for faster lookups
local pairs = pairs
local strgsub = string.gsub
local pcall, error, type, unpack = pcall, error, type, unpack

local LibVan32, OLDMINOR = LibStub:NewLibrary(MAJOR, MINOR)

if not LibVan32 then return end -- No upgrade needed

-- Parse the $X Color codes from the PrintMessage function
local function parseMessage(message)
	if not message then return "" end
	local cT = {
		-- Color codes kindly borrowed from Minecraft!
		["§0"]="|cFF000000",	-- Black
		["§1"]="|cFF0000A0",	-- Dark Blue
		["§2"]="|cFF00A000",	-- Dark Green
		["§3"]="|cFF00A0A0",	-- Dark Aqua
		["§4"]="|cFFA00000",	-- Dark Red
		["§5"]="|cFFA000A0",	-- Purple
		["§6"]="|cFFF0A000",	-- Gold
		["§7"]="|cFFA0A0A0",	-- Grey
		["§8"]="|cFF505050",	-- Dark Grey
		["§9"]="|cFF5050F0",	-- Indigo
		["§a"]="|cFF50F050",	-- Bright Green
		["§b"]="|cFF50F0F0",	-- Aqua
		["§c"]="|cFFF05050",	-- Red
		["§d"]="|cFFF050F0",	-- Pink
		["§e"]="|cFFF0F050",	-- Yellow
		["§f"]="|cFFF0F0F0",	-- White
		["§r"]="|r",			-- reset
		["§T"]="|cFFAF96FF",	-- Title, (ltpurple)
		["#c"]="|cFF", 			-- custom color
		--["§E"] = "|cFFff1919",
		
	}
	local str, newStr = message
	for k, v in pairs(cT) do
		newStr = strgsub(str, k, v)
		str = newStr
	end
	return str
end

---Sets the default chat frame used to print messages.
--@usage YourAddon:SetDefaultChatFrame(ChatFrame2)
--@param ChatFrame The frame you want to send messages to. It MUST have an .AddMessage entry
function LibVan32:SetDefaultChatFrame(chatFrame)
	if chatFrame and (not chatFrame.AddMessage) then error("invalid chatFrame specified", 2) end
	
	self._DefaultChatFrame = chatFrame
end


---Used to parse color-coded strings in the same way that PrintMessage does.\\
---Provides users with a way to easily color a dialog's strings in the same theme as the chat.
---@usage string = YourAddon:ParseColorCodedString("string")
---@param str string The string that contains the color-codes.
---@return string str A string with library color codes replaced with the client's color escape sequence. (|cFFFFFFFF, for example)
function LibVan32:ParseColorCodedString(str)
	if type(str) ~= 'string' then error("bad argument #1 to \'ParseColorCodedString\', (string expected, got " .. type(str) ..")", 2) end
	return parseMessage(str)
end

--- Prints a color-coded message to the default chat frame.\\
---Supports Minecraft style escape sequences (§x), where x corresponds to a single hex digit. See library code for color conversions.
---
---The message output is: title: <Debug> [ERROR] message
---@usage YourAddon:PrintMessage("message", [isError], [isDebug], [chatFrame])
---@param message string The message to print to the chat.
---@param isError? boolean Whether or not to flag the message as an error.
---@param isDebug? boolean Whether or not to flag the message as debug.
---@param chatFrame? frame The Frame to send the message through. This frame needs to have an AddMessage method.
function LibVan32:PrintMessage(message, isError, isDebug, chatFrame)
	if type(message) ~= 'string' then error("bad argument #1 to \'PrintMessage\', (string expected, got " .. type(message) ..")", 2) end
	
	if chatFrame and (not chatFrame.AddMessage) then error("invalid chatFrame specified", 2) end
	
	local oM = "§T" .. self._AddonRegisteredName .. "§r: "
	local oF = (chatFrame or self._DefaultChatFrame) or DEFAULT_CHAT_FRAME
	
	-- Check and append debug header
	if isDebug then
		if not self._DebugMode then return end
		oM = oM .. "§8<Debug>§r "
	end
	
	-- Check and add [ERROR] header
	if isError then
		oM = oM .. "§c[ERROR]§r "
	end
	
	-- Append the actual message
	oM = oM .. message
	
	-- Parse the color codes
	return oF:AddMessage(parseMessage(oM))
end

---Prints a message that can only be seen when the calling addon is in debug mode.
---
--This is the same as calling YourAddon:PrintMessage("message", isError, true)
---@usage YourAddon:PrintDebug("message", [isError], [chatFrame])
---@param message string The message to print to the chat frame.
---@param isError? boolean Whether or not to flag the message as also being an error.
---@param chatFrame? frame The Frame to send the message through. This frame needs to have an AddMessage method.
function LibVan32:PrintDebug(message, isError, chatFrame)
	if type(message) ~= 'string' then error("bad argument #1 to \'PrintDebug\', (string expected, got " .. type(message) ..")", 2) end
	
	return self:PrintMessage(message, isError, true, chatFrame)
end

---Prints a message that will be flagged to the user as an error.\\
---
---This is the same as calling YourAddon:PrintMessage("message", true, isDebug)
---@usage YourAddon:PrintErr("message", [isDebug], [chatFrame])
---@param message string The message to print to the chat frame.
---@param isDebug? boolean Also mark this message as a debug message. (It's preferred that you call :PrintDebug("message", true) for this)
---@param chatFrame? frame The Frame object to send the message to. The frame requires the AddMessage method.
function LibVan32:PrintErr(message, isDebug, chatFrame)
	if type(message) ~= 'string' then error("bad argument #1 to \'PrintError\', (string expected, got " .. type(message) ..")", 2) end
	
	return self:PrintMessage(message, true, isDebug, chatFrame)
end

-- Timers Library
LibVan32.timers = {}

---Create a recurring or single-tick timer.
---
---For example: calling a function after 5 seconds, or updating a list of objects every half-second
---@usage Timer = YourAddon:SetTimer(interval, callback, [recur, [uID]], [...])
---@param interval number The delay, in seconds, that you want before excecuting `callback`.
---@param callback function The function to excecute when `interval` time has passed.
---@param recur boolean Whether or not the timer will repeat each `interval` seconds.
---@param uID any A Unique identifier assigned to a timer instance. You can use this, for instance, in a recursive function that iterates on a timer. Setting this field will deny creation of any new timers with the exact same uID. I reccomend using a string for this field, since it is global, however it will accept anything.
---@param ... ...  A list of arguments to pass to 'callback'.
---@return table|number timer The instance of the timer created, if successful, otherwise -1.
function LibVan32:SetTimer(interval, callback, recur, uID, ...)
	--Redundancy checks
	if type(interval) ~= 'number' then error("bad argument #1 to \'SetTimer\', (number expected, got " .. type(interval) ..")", 2) end
	if type(callback) ~= 'function' then error("bad argument #2 to \'SetTimer\', (function expected, got " .. type(callback) ..")", 2) end
	
	local timer = {
		interval = interval,
		callback = callback,
		recur = recur,
		uID = nil or (recur and uID),
		update = 0,
		...
	}
	
	if uID then
		-- Check the timers existing:
		for k, _ in pairs(LibVan32.timers) do
			if k.uID == uID then
				return -1
			end
		end
	end
	LibVan32.timers[timer] = timer
	return timer
end

---Stop an existing timer. This function requires a timer instance created with :SetTimer()
---@usage YourAddon:KillTimer(timer)
---@param timer table The timer you wish to stop.
---@return table|nil timer This function returns `nil` if the timer was sucessfully stopped, making it easier for you to clear the variable you stored the timer instance in originally. If it did not find a timer, it will return the variable you sent to it, so that it's not completely lost.
function LibVan32:KillTimer(timer)
	if type(timer) ~= 'table' then error("bad argument #1 to \'KillTimer\', (table expected, got " .. type(timer) ..")", 2) end
	if LibVan32.timers[timer] then
		LibVan32.timers[timer] = nil
		return nil
	else
		return timer
	end
end


-- How often to check timers. Lower values are more CPU intensive.
local granularity = 0.1

local totalElapsed = 0
local function OnUpdate(self, elapsed)
   totalElapsed = totalElapsed + elapsed
   if totalElapsed > granularity then
	  for k,t in pairs(LibVan32.timers) do
		 t.update = t.update + totalElapsed
		 if t.update > t.interval then
			local success, rv = pcall(t.callback, unpack(t))
			if not rv and t.recur then
			   t.update = 0
			else
			   LibVan32.timers[t] = nil
			   if not success then error("Timer Callback failed:" .. rv, 0) end
			end
		 end
	  end
	  totalElapsed = 0
   end
end
CreateFrame("Frame"):SetScript("OnUpdate", OnUpdate)

LibVan32.mixinTargets = LibVan32.mixinTargets or {}
local mixins = {
	"KillTimer",
	"SetTimer",
	"PrintMessage",
	"PrintErr",
	"PrintDebug",
	"SetDefaultChatFrame",
	"ParseColorCodedString",
}

---Embed this library into an addon, and store it's 'short title' for addon output.
---
---The addonName is used in PrintMessage, showing which addon is accosting the user with information.
---
--If you wish to change the default color used by the title, it's possible, by adding your color string in the `addonName` field.
---@param target table The table you want to embed the library into.
---@param addonName string The short title of your addon, used in PrintMessage calls.
---@usage LibStub:GetLibrary("LibVan32-1.0"):Embed(YourAddon, "addonName")
function LibVan32:Embed(target, addonName)
	--Redundancy checks
	if type(target) ~= 'table' then error("bad argument #1 to \'Embed\', (table expected, got " .. type(target) ..")", 2) end
	if type(addonName) ~= 'string' then error("bad argument #2 to \'Embed\', (string expected, got " .. type(addonName) ..")", 2) end
	
	for _, name in pairs(mixins) do
		target[name] = LibVan32[name]
	end
	-- Pass Lib variables to the addon as well on embed.
	target._AddonRegisteredName = addonName
	target._DefaultChatFrame = DEFAULT_CHAT_FRAME
	target._DebugMode = false
	
	LibVan32.mixinTargets[target] = true
end

-- Update the old embeds
for target, _ in pairs(LibVan32.mixinTargets) do
	LibVan32:Embed(target, target._AddonRegisteredName)
end
