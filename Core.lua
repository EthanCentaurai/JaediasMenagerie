
-- libraries
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- namespace
local ID, Jaedia = ...

-- locals
local _
local db, options, index, spellID, numCompanions
local values = {}

-- upvalues
local GetNumCompanions	= _G.GetNumCompanions
local GetCompanionInfo	= _G.GetCompanionInfo
local CallCompanion	= _G.CallCompanion
local random		= _G.math.random
local wipe		= _G.wipe


--@debug@--
local debug = false
--@end-debug@--


-- config, loaded on demand
function Jaedia:Set(_, spellID, value)
	--@debug@--
	if debug then
		if value then print(spellID, "has been blacklisted.")
		else print(spellID, "is no longer blacklisted.")
	end
	--@end-debug@--

	db[spellID] = value
	AceConfigRegistry:NotifyChange(ID)
end

function Jaedia:GetValues()
	wipe(values)

	for spellID, value in pairs(db) do
		if value then
			values[spellID] = true
		end
	end

	return values
end


function Jaedia:OpenConfig()
	options = {
		name = "Jaedia's Menagerie", type = "group", handler = Jaedia,
		args = {
			description = {
				order = 1, type = "description", -- hurr :B
				name = "This addon allows you to choose which companions are picked by the /randompet slash command.\n\nSimply drag and drop a companion from your spellbook into the Blacklist section below to prevent that companion being picked.",
			},
			blacklist = {
				order = 2, type = "multiselect",
				name = "Blacklist",
				dialogControl = "CompanionList",
				width = "full",
				get = function() return true end,
				set = "Set",
				values = "GetValues",
			},
			--@debug@--
			debug = {
				order = 3, type = "toggle",
				name = "Debug",
				get = function() return debug end,
				set = function() debug = not debug end,
			},
			--@end-debug@--
		},
	}

	return options
end


-- enable
function Jaedia:OnEnable()
	self.db = LibStub("AceDB-3.0"):New("JaediasMenagerieDB", {
		profile = {
			[92395] = true, [92396] = true, [92397] = true, [92398] = true, -- blacklist the Guild Squire/Page by default
		}
	}, "Default")

	db = self.db.profile

	AceConfig:RegisterOptionsTable(ID, self.OpenConfig)
	AceConfigDialog:SetDefaultSize(ID, 575, 400)

	_G["SLASH_JAEDIA1"] = "/jaediasmenagerie"
	_G["SLASH_JAEDIA2"] = "/jaedia"
	_G["SLASH_JAEDIA3"] = "/jae"

	_G.SlashCmdList["JAEDIA"] = function() AceConfigDialog:Open(ID) end

	-- leave this until last so if something above breaks this *should* be left untouched
	_G.SlashCmdList["RANDOMPET"] = function()
		numCompanions = GetNumCompanions("CRITTER")

		if numCompanions > 0 then
			repeat
				index = random(1, numCompanions)
				_, _, spellID = GetCompanionInfo("CRITTER", index)

				--@debug@--
				if debug then
					if db[spellID] then print(spellID, "is blacklisted, retrying.")
					else print(spellID, "is safe, summoning.") end
				end
				--@end-debug@--

			until not db[spellID]

			CallCompanion("CRITTER", index)
		end
	end
end


-- execute
Jaedia = LibStub("AceAddon-3.0"):NewAddon(Jaedia, ID)
