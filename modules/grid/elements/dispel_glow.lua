
local dispelClass = {
	["PRIEST"] = { ["Disease"] = true, ["Magic"] = true, }, --Purify
	["SHAMAN"] = { ["Curse"] = true, ["Magic"] = true, }, --Purify Spirit
	["PALADIN"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Cleanse
	["MAGE"] = { ["Curse"] = true, }, --Remove Curse
	["DRUID"] = { ["Curse"] = true, ["Poison"] = true, ["Magic"] = true, }, --Nature's Cure
	["MONK"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Detox
}
local dispelColors = {
	['Magic'] = {.16, .5, .81, 1},
	['Poison'] = {.12, .76, .36, 1},
	['Disease'] = {.76, .46, .12, 1},
	['Curse'] = {.80, .33, .95, 1},
}

--===========================================
-- DISPEL / GLOWING
--===========================================
local function dispelAndGlow(self, event, unit)
	if (unit ~= self.unit) then return end

	local foundGlow = false
	local foundDispel = false
	local noMoreDebuffs = false -- let's us exit loop early if we run out of one or both aura types
	local noMoreBuffs = false -- let's us exit loop early if we run out of one or both aura types

	for i = 1, 40 do

		if (not noMoreDebuffs) then
			local debuff, icon, count, debuffType = UnitDebuff(unit, i)
			if (not debuff) then
				noMoreDebuffs = true
			else
				if (dispelColors[debuffType]) then
					foundDispel = debuffType
					noMoreDebuffs = true
				end

				if (config.specialalerts[debuff] or bdCore:isGlow(debuff)) then
					foundGlow = true
					noMoreBuffs = true
					noMoreDebuffs = true
				end
			end
		end

		-- glow
		if (not noMoreBuffs) then
			local buff = UnitBuff(unit, i)
			if (not buff) then
				noMoreBuffs = true
			end

			if (config.specialalerts[buff] or bdCore:isGlow(buff)) then
				foundGlow = true
				noMoreBuffs = true
			end
		end
		
		-- breka if possible
		if ((foundGlow and foundDispel) or (noMoreBuffs and noMoreDebuffs)) then
			break
		end
	end

	if (foundDispel) then
		self.Dispel:Show()
		self.Dispel:SetBackdropBorderColor(unpack(dispelColors[foundDispel]))
	else
		self.Dispel:Hide()
	end

	if (foundGlow) then
		lib_glow.ShowOverlayGlow(self.Glow)
	else
		lib_glow.HideOverlayGlow(self.Glow)
	end
end