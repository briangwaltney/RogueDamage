-- DEBUG TOOL
-- local function printTable(table, indent)
--   indent = indent or 0
--   local indentStr = string.rep(" ", indent)
--
--   for key, value in pairs(table) do
--     if type(value) == "table" then
--       print(indentStr .. key .. ":")
--       printTable(value, indent + 4)
--     else
--       print(indentStr .. key .. ": " .. tostring(value))
--     end
--   end
-- end

local spellReqs = {}

spellReqs["Backstab"] = function()
  return true
end

spellReqs["Sinister Strike"] = function()
  return true
end

spellReqs["Eviscerate"] = function()
  return true
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
  return true
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
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
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

  return list
end

spells["Backstab"] = function(id, baseDamage)
  -- 53
  local desc = GetSpellDescription(id)
  local addDamage = tonumber(string.match(desc, "plus (%d+)"))
  local dmg = math.floor(baseDamage * 1.5 + addDamage)

  return {
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
  }
end

spells["Ambush"] = function(id, baseDamage)
  -- 8676
  local desc = GetSpellDescription(id)
  local addDamage = tonumber(string.match(desc, "plus (%d+)"))
  local dmg = math.floor(baseDamage * 2.5 + addDamage)
  return {
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
  }
end

spells["Ghostly Strike"] = function(_, baseDamage)
  -- 14278
  local dmg = math.floor(baseDamage * 1.5)
  return {
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
    dmg,
  }
end

spells["Garrote"] = function(id)
  -- 703
  local desc = GetSpellDescription(id)
  local dmg = tonumber(string.match(desc, "causing (%d+)"))
  return {
    dmg,
    0,
    0,
    0,
    0,
    0,
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

  return list
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
        dmgList[spellType] = spells[spellType](dbSpellId, baseDamage)
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
    local spellDmg = dmgList[key][comboPoints + 1]
    if
    -- IsUsableSpell(key) and
        spellDmg > 0 and spellReqs[key]()
    then
      currentDamage[key] = spellDmg
    end
  end

  local seq = {}
  for key, value in pairs(currentDamage) do
    table.insert(seq, { key, value })
  end

  table.sort(seq, function(a, b)
    return a[2] > b[2]
  end)

  local sorted = {}

  for _, entry in ipairs(seq) do
    table.insert(sorted, entry[1] .. ": " .. entry[2])
  end

  return sorted, seq
end

local f = CreateFrame("Frame", "MyAddonFrame", UIParent)
f:SetWidth(100)
f:SetHeight(200)
f:SetPoint("CENTER", -250, 0)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self)
  self:StartMoving()
end)
f:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
end)

local fontPath = "Fonts\\FRIZQT__.TTF"

local targetHealthText = f:CreateFontString(nil, "OVERLAY")
targetHealthText:SetPoint("TOPLEFT", 0, 0)
targetHealthText:SetJustifyH("RIGHT")
targetHealthText:SetFont(fontPath, 13)

local text1 = f:CreateFontString(nil, "OVERLAY")
text1:SetPoint("TOPLEFT", 0, -25)
text1:SetJustifyH("RIGHT")
text1:SetFont(fontPath, 16)

local text2 = f:CreateFontString(nil, "OVERLAY")
text2:SetPoint("TOPLEFT", 0, -50)
text2:SetJustifyH("RIGHT")
text2:SetFont(fontPath, 14)

local text3 = f:CreateFontString(nil, "OVERLAY")
text3:SetPoint("TOPLEFT", 0, -70)
text3:SetJustifyH("RIGHT")
text3:SetFont(fontPath, 14)

local text4 = f:CreateFontString(nil, "OVERLAY")
text4:SetPoint("TOPLEFT", 0, -90)
text4:SetJustifyH("RIGHT")
text4:SetFont(fontPath, 14)

local text5 = f:CreateFontString(nil, "OVERLAY")
text5:SetPoint("TOPLEFT", 0, -110)
text5:SetJustifyH("RIGHT")
text5:SetFont(fontPath, 14)

local text6 = f:CreateFontString(nil, "OVERLAY")
text6:SetPoint("TOPLEFT", 0, -130)
text6:SetJustifyH("RIGHT")
text6:SetFont(fontPath, 14)

local textLines = {
  text1,
  text2,
  text3,
  text4,
  text5,
  text6,
}

local printLines = function()
  local className = UnitClass("player")
  if className ~= "Rogue" then
    f:Hide()
    return
  end

  local targetHealth = UnitHealth("target")
  targetHealthText:SetText("Target Health: " .. targetHealth)
  local line, damages = createPrintList()

  -- length of line
  local length = 0

  for i, pair in ipairs(damages) do
    if pair[2] >= targetHealth and targetHealth > 0 then
      textLines[i]:SetTextColor(0, 1, 0)
      textLines[i]:SetFont(fontPath, 18)
    else
      textLines[i]:SetTextColor(1, 1, 1)
    end
    textLines[i]:SetText(line[i])
    length = length + 1
  end

  for i = length + 1, 6 do
    textLines[i]:SetText("")
  end

  f:Show()
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
stealthCheck:RegisterEvent("UPDATE_STEALT")
stealthCheck:SetScript("OnEvent", function()
  printLines()
end)
