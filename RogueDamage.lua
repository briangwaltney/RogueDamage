-- DEBUG TOOL
local function printTable(table, indent)
	indent = indent or 0
	local indentStr = string.rep(" ", indent)

	for key, value in pairs(table) do
		if type(value) == "table" then
			print(indentStr .. key .. ":")
			printTable(value, indent + 4)
		else
			print(indentStr .. key .. ": " .. tostring(value))
		end
	end
end

local spellReqs = {}

spellReqs["Backstab"] = function()
	return true
end

spellReqs["Sinister Strike"] = function()
	return true
end

spellReqs["Eviscerate"] = function()
	return not IsStealthed()
end

spellReqs["Ambush"] = function()
	return IsStealthed()
end

spellReqs["Ghostly Strike"] = function()
	return true
end

spellReqs["Garrote"] = function()
	return IsStealthed()
end

spellReqs["Rupture"] = function()
	return not IsStealthed()
end

local spells = {}

local getBaseDamage = function()
	local low, high = UnitDamage("player")
	local baseDamage = (low + high) / 2
	return baseDamage
end

spells["Sinister Strike"] = function(id, baseDamage)
	-- 1752
	local desc = GetSpellDescription(id)
	local addDamage = tonumber(string.match(desc, "%d+"))
	local dmg = math.floor(baseDamage + addDamage)

	return {
		{
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
		},
		1,
	}
end

spells["Eviscerate"] = function(id)
	-- 2098
	local desc = GetSpellDescription(id)

	local list = { 0 }
	for line in string.gmatch(desc, "[^\n]+") do
		local min = string.match(line, "(%d+)-%d+")
		local max = string.match(line, "%d+-(%d+)")
		if min ~= nil then
			local avg = math.floor((tonumber(min) + tonumber(max)) / 2)
			table.insert(list, avg)
		end
	end

	return { list, 2 }
end

spells["Backstab"] = function(id, baseDamage)
	-- 53
	local desc = GetSpellDescription(id)
	local addDamage = tonumber(string.match(desc, "plus (%d+)"))
	local dmg = math.floor(baseDamage * 1.5 + addDamage)

	return {
		{
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
		},
		3,
	}
end

spells["Ambush"] = function(id, baseDamage)
	-- 8676
	local desc = GetSpellDescription(id)
	local addDamage = tonumber(string.match(desc, "plus (%d+)"))
	local dmg = math.floor(baseDamage * 2.5 + addDamage)
	return {
		{
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
		},
		4,
	}
end

spells["Ghostly Strike"] = function(_, baseDamage)
	-- 14278
	local dmg = math.floor(baseDamage * 1.5)
	return {
		{
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
			dmg,
		},
		5,
	}
end

spells["Garrote"] = function(id)
	-- 703
	local desc = GetSpellDescription(id)
	local dmg = tonumber(string.match(desc, "causing (%d+)"))
	return {
		{
			dmg,
			0,
			0,
			0,
			0,
			0,
		},
		6,
	}
end

spells["Rupture"] = function(id)
	-- 1943
	local desc = GetSpellDescription(id)
	local list = { 0 }
	for line in string.gmatch(desc, "[^\n]+") do
		local dmg = string.match(line, ": (%d+)")
		table.insert(list, dmg)
	end

	return { list, 7 }
end

local function getSpellDmg(key)
	local comboPoints = GetComboPoints("player", "target")
	return spells[key][comboPoints + 1]
end

local function getSpellList()
	local dmgList = {}

	local function shouldParse(name)
		for spell in pairs(spells) do
			if spell == name then
				return true
			end
		end
		return false
	end
	-- Cycle through all spells in spellbook
	for rank = 1, GetNumSpellTabs() do
		local _, _, offset, numSpells = GetSpellTabInfo(rank)
		for i = offset + 1, offset + numSpells do
			local spellType, _, dbSpellId = GetSpellBookItemName(i, "spell")
			local baseDamage = getBaseDamage()
			if shouldParse(spellType) then
				dmgList[spellType] = {
					spells[spellType](dbSpellId, baseDamage)[1],
					spells[spellType](dbSpellId, baseDamage)[2],
				}
			end
		end
	end

	return dmgList
end

-- DISPLAY CALCS

local function createPrintList()
	local currentDamage = {}
	local comboPoints = GetComboPoints("player", "target")
	local dmgList = getSpellList()

	for key, _ in pairs(dmgList) do
		local spellDmg = dmgList[key][1][comboPoints + 1]
		local spellPos = dmgList[key][2]
		currentDamage[key] = { spellDmg, spellPos }
	end

	return currentDamage
end

local fontPath = "Fonts\\FRIZQT__.TTF"
local frames = {}

for key, _ in pairs(spells) do
	frames[key] = CreateFrame("Frame", key, UIParent)
	frames[key]:SetWidth(32)
	frames[key]:SetHeight(32)
	frames[key]:SetPoint("CENTER", 0, 0)
	frames[key]:SetMovable(true)
	frames[key]:EnableMouse(true)
	frames[key]:RegisterForDrag("RightButton")
	frames[key]:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frames[key]:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	local text = frames[key]:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER", 0, 32)
	text:SetFont(fontPath, 16)

	frames[key].text = text
end

local printLines = function()
	local className = UnitClass("player")
	if className ~= "Rogue" then
		frames.List:Hide()
		return
	end

	local targetHealth = UnitHealth("target")
	local printList = createPrintList()

	for key, value in pairs(printList) do
		local texture = frames[key]:CreateTexture(nil, "BACKGROUND")
		texture:SetAllPoints(true)

		if spellReqs[key]() then
			frames[key]:Show()
		else
			frames[key]:Hide()
		end

		-- Get the spell texture (icon)
		local spellTexture = GetSpellTexture(key)

		if spellTexture then
			texture:SetTexture(spellTexture)
		end

		frames[key].text:SetText(value[1])

		if value[1] >= targetHealth and targetHealth > 0 then
			frames[key].text:SetTextColor(0, 1, 0)
		else
			frames[key].text:SetTextColor(1, 1, 1)
		end

		local comboPoints = GetComboPoints("player", "target")
		if comboPoints == 5 then
			frames[key].text:SetFont(fontPath, 24)
		else
			frames[key].text:SetFont(fontPath, 16)
		end
	end
end

local comboTracker = CreateFrame("FRAME")
comboTracker:RegisterEvent("UNIT_POWER_UPDATE")
comboTracker:SetScript("OnEvent", function()
	printLines()
end)

local colorAdjust = CreateFrame("FRAME")
colorAdjust:RegisterEvent("UNIT_HEALTH")
colorAdjust:SetScript("OnEvent", function()
	printLines()
end)

local targetChange = CreateFrame("FRAME")
targetChange:RegisterEvent("PLAYER_TARGET_CHANGED")
targetChange:SetScript("OnEvent", function()
	printLines()
end)

local stealthCheck = CreateFrame("FRAME")
stealthCheck:RegisterEvent("UPDATE_STEALTH")
stealthCheck:SetScript("OnEvent", function()
	printLines()
end)
