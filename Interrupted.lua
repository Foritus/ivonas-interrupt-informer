-- Addon written by Ivona, Terenas, EU.
-- rich@aornis.com

-- Derived client version
local clientVersionNumber

-- Alias' for global methods
local GetTime = _G.GetTime
local UnitGUID = _G.UnitGUID
local UnitExists = _G.UnitExists

-- Array of raid marker symbols
local symbols = {"{star}", "{circle}", "{diamond}", "{triangle}", "{moon}", "{square}", "{cross}", "{skull}"}

-- Spell ID's and text names of spell interrupts that we want to announce misses for
local interrupts = {
	[1766] = "Kick",
	[6552] = "Pummel",
	[2139] = "Counterspell",
	[34490] = "Silencing Shot",
	[47476] = "Strangulate",
	[47528] = "Mind Freeze",
	[57994] = "Wind Shear",
	[96231] ="Rebuke",
	[80964] = "Skull Bash (Bear)",
	[80965] = "Skull Bash (Cat)",
	[102060] = "Disrupting Shout",
	[106839] = "Skull Bash",
	[116705] = "Spear Hand Strike"
}

-- Determines where to send message depending upon player context
local function getMessageChannel()

	local inInstance, instanceType = IsInInstance()

	if instanceType == "arena" then
		return "say"
	elseif instanceType == "pvp" then	
		return "say"
	elseif IsInRaid() then
		return "say"
	elseif GetNumGroupMembers() > 0 then
		return "say"
	else
		return nil
	end
end

-- Wrapper function for sending text output
local function sendMessage(msg)
	-- Get the chat channel we're writing to
	local destination = getMessageChannel()

	-- Only output if needed
	if destination == nil then
		return
	end

	SendChatMessage(msg, destination)
end

-- Main event loop handler
function handleEvent(self, event, ... )

	
	-- Variables used for event loop processing
	local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, extraArg1, extraArg2, extraArg3, extraArg4, extraArg5, extraArg6, extraArg7, extraArg8, extraArg9, extraArg10 = CombatLogGetCurrentEventInfo()
		
	-- Event not connected to the current user? Then we don't care.
	if sourceGUID ~= UnitGUID("player") then
		return
	end
			
	-- If this was a spell interrupt from the current player
	if eventType == "SPELL_INTERRUPT" then

		local srcSpellId, srcSpellName, srcSpellSchool, dstSpellId, dstSpellSchool, dstSpellName = select(12, CombatLogGetCurrentEventInfo());
		
		-- Current raid target icon ID
		local currentTargetIcon

		-- Get the current raid target icon if applicable
		if destGUID == UnitGUID("target") then
			currentTargetIcon = GetRaidTargetIndex("target")
		elseif destGUID == UnitGUID("focus") then
			currentTargetIcon = GetRaidTargetIndex("focus")
		elseif destGUID == UnitGUID("mouseover") then
			currentTargetIcon = GetRaidTargetIndex("mouseover")
		else 
			currentTargetIcon = nil
		end
			
		-- If no icon is set on the current target, default to the "blank" entry at the start of the array
		if currentTargetIcon ~= nil then 
			symbol = symbols[currentTargetIcon]
		else
			symbol = ""
		end

		-- Write message to client
		sendMessage( string.format("Interrupted %s%s's%s %s!", symbol, destName, symbol, GetSpellLink(dstSpellId) ))
		
	elseif eventType == "SPELL_MISSED" and interrupts[spellID] then
		-- Allocate miss message
		local reason
		-- Text formatting
		if missType == "IMMUNE" then
			reason = "Immune"
		elseif missType == "MISS" then
			reason = "Missed"
		elseif missType == "BLOCK" then
			reason = "Blocked"
		elseif missType == "PARRY" then
			reason = "Parried"
		elseif missType == "DODGE" then
			reason = "Dodged"
		end

		-- Write message to client
		sendMessage(string.format("%s failed on %s (%s)", spellName, dstName, reason or missType))
	end
end

function Interrupted_OnLoad(self)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:SetScript("OnEvent", handleEvent);

	clientVersionNumber = select(4, GetBuildInfo())
end