local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("Maps")


function mod:create_button_frame()
	local config = mod:get_save()

	-- Button frame
	Minimap.buttonFrame = CreateFrame("frame", "bdButtonFrame", Minimap)
	Minimap.buttonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	if (bdUI.version >= 60000) then
		Minimap.buttonFrame:RegisterEvent("GARRISON_UPDATE")
	end
	Minimap.buttonFrame:RegisterEvent("PLAYER_XP_UPDATE")
	Minimap.buttonFrame:RegisterEvent("PLAYER_LEVEL_UP")
	Minimap.buttonFrame:RegisterEvent("UPDATE_FACTION")
	Minimap.buttonFrame:SetSize(Minimap.background:GetWidth() - (bdUI.border * 2), config.buttonsize)
	Minimap.buttonFrame:SetPoint("TOP", Minimap.background, "BOTTOM", bdUI.border, -bdUI.border)

	local bdConfigButton = CreateFrame("button","bdUI_configButton", Minimap)
	bdConfigButton.text = bdConfigButton:CreateFontString(nil,"OVERLAY")
	bdConfigButton.text:SetFontObject("BDUI_SMALL")
	bdConfigButton.text:SetTextColor(.4,.6,1)
	bdConfigButton.text:SetText("bd")
	bdConfigButton.text:SetJustifyH("CENTER")
	bdConfigButton.text:SetPoint("CENTER", bdConfigButton, "CENTER", -1, -1)
	bdConfigButton:RegisterForClicks("AnyUp")
	bdConfigButton:SetScript("OnEnter", function(self) 
		self.text:SetTextColor(.6,.8,1) 
		-- ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 6)
		GameTooltip:AddLine(bdUI.colorString.."Config\n|cffFFAA33Left Click:|r |cff00FF00Open bdUI Config|r\n|cffFFAA33Right Click:|r |cff00FF00Toggle lock/unlock|r\n|cffFFAA33Ctrl+Click:|r |cff00FF00Reload UI|r")
		GameTooltip:Show()
	end)
	bdConfigButton:SetScript("OnLeave", function(self) 
		self.text:SetTextColor(.4,.6,1)
		GameTooltip:Hide()
	end)
	bdConfigButton:SetScript("OnClick", function(self, button)
		if (IsControlKeyDown()) then
			ReloadUI()
		end
		
		if (button == "LeftButton") then
			bdUI.bdConfig:toggle()
		elseif (button == "RightButton") then
			bdUI.bdConfig.header.lock:Click()
		end		
	end)

	-- Find and move buttons
	local ignoreFrames = {}
	local hideTextures = {}
	local manualTarget = {}
	local hideButtons = {}
	local frames = {}
	local numChildren = 0

	MiniMapTracking:SetParent(Minimap)
	MiniMapTrackingButtonBorder:Hide()
	MiniMapTrackingButtonShine:Hide()
	MiniMapTrackingButtonShine.Show = noop
	GarrisonLandingPageMinimapButton:SetParent(Minimap)
	-- QueueStatusMinimapButton:SetFrameLevel(5)
	QueueStatusMinimapButtonIcon:SetParent(QueueStatusMinimapButton)
	manualTarget['CodexBrowserIcon'] = true
	manualTarget['MiniMapTracking'] = true
	manualTarget['HelpOpenWebTicketButton'] = true
	manualTarget['GarrisonLandingPageMinimapButton'] = true
	-- manualTarget['MiniMapTrackingFrame'] = true
	manualTarget['MiniMapMailFrame'] = true
	manualTarget['COHCMinimapButton'] = true
	manualTarget['ZygorGuidesViewerMapIcon'] = true
	manualTarget['MiniMapBattlefieldFrame'] = true
	manualTarget['PeggledMinimapIcon'] = true
	manualTarget['QueueStatusMinimapButton'] = true

	ignoreFrames['bdButtonFrame'] = true
	ignoreFrames['MinimapBackdrop'] = true
	ignoreFrames['GameTimeFrame'] = true
	ignoreFrames['MinimapVoiceChatFrame'] = true
	ignoreFrames['TimeManagerClockButton'] = true

	hideTextures['Interface\\Minimap\\MiniMap-TrackingBorder'] = true
	hideTextures['Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight'] = true
	hideTextures['Interface\\Minimap\\UI-Minimap-Background'] = true 
	hideTextures[136430] = true 
	hideTextures[136467] = true 

	--===================================
	-- Position buttons
	--===================================
	local function size_move()
		local last = nil

		hideButtons = {}

		if (not config.showconfig) then
			hideButtons['bdButtonFrame'] = true
		end
		if (config.hideclasshall) then
			hideButtons['GarrisonLandingPageMinimapButton'] = true
		end

		table.sort(frames, function(a, b)
			return a.name < b.name
		end)

		for k, f in pairs(frames) do
			f:SetWidth(config.buttonsize)
			f:SetHeight(config.buttonsize)
			f:ClearAllPoints()

			if (hideButtons[f:GetName()]) then
				f:Hide()
				f:SetAlpha(0)
			end
			if (config.buttonpos == "Top" or config.buttonpos == "Bottom") then
				if (last) then
					f:SetPoint("LEFT", last, "RIGHT", bdUI.border*3, 0)		
				else
					f:SetPoint("TOPLEFT", Minimap.buttonFrame, "TOPLEFT", 0, 0)
				end
			end
			if (config.buttonpos == "Right" or config.buttonpos == "Left") then
				if (last) then
					f:SetPoint("TOP", last, "BOTTOM", 0, -bdUI.border*3)		
				else
					f:SetPoint("TOPLEFT", Minimap.buttonFrame, "TOPLEFT", 0, 0)
				end
			end
			last = f
		end
	end

	--===================================
	-- Skin button
	--===================================
	local function skin(f)
		if (f.skinned) then return end

		f:SetScale(1)
		f:SetFrameStrata("MEDIUM")

		-- Skin textures
		local r = {f:GetRegions()}
		for o = 1, #r do
			if (r[o].GetTexture and r[o]:GetTexture()) then
				local tex = r[o]:GetTexture()
				r[o]:SetAllPoints(f)
				r[o]:SetDrawLayer("ARTWORK")
				if (hideTextures[tex]) then
					r[o]:Hide()
				elseif (not strfind(tex,"WHITE8x8")) then
					local coord = table.concat({r[o]:GetTexCoord()})
					if (coord == "00011011" and not f:GetName() == "MinimMapTracking") then
						r[o]:SetTexCoord(0.3, 0.7, 0.3, 0.7)
						if (n == "DugisOnOffButton") then
							r[o]:SetTexCoord(0.25, 0.75, 0.2, 0.7)								
						end
					end
				end
			end
		end
		
		-- Create background
		bdUI:set_backdrop(f)
		f.skinned = true
	end

	
	local function move_buttons()
		-- if (InCombatLockdown()) then return end
		
		local c = {Minimap.buttonFrame:GetChildren()}
		local d = {Minimap:GetChildren()}

		if (#d ~= numChildren) then
			numChildren = #d
			frames = {}

			for k, v in pairs(d) do table.insert(c,v) end
			local last = nil
			for i = 1, #c do
				local f = c[i]
				local n = f:GetName() or i;
				f.buttonindex = i
				f.name = n

				if (f:IsShown() and not ignoreFrames[n] and (
						(manualTarget[n])
						or
						(f:GetName() and (strfind(n, "LibDB") or strfind(n, "Button") or strfind(n, "Btn")))
					)
				) then
					skin(f)
					frames[i] = f
				end
			end
		else
			for f, v in pairs(manualTarget) do
				local f = _G[f]
				if (f) then
					local n = f:GetName() or i;
					f.name = n
					if (f:IsShown()) then
						skin(f)
						frames[f.buttonindex or n] = f
					else
						frames[f.buttonindex or n] = nil
					end
				end

			end
		end

		size_move()
	end

	-- Updater script
	local total = 0
	Minimap.buttonFrame:SetScript("OnEvent",moveMinimapButtons)
	Minimap.buttonFrame:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed
		if (total > 1) then
			total = 0
			move_buttons()
		end
	end)
end