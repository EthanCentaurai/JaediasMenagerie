
--------------------------------------------------------------------------------
-- The code in this widget was heavily inspired by Adirelle's
-- ItemList widget in AdiBags and is used with his permission.
--------------------------------------------------------------------------------


local _G = _G
local ClearCursor = _G.ClearCursor
local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local GetCursorInfo = _G.GetCursorInfo
local GetCompanionInfo = _G.GetCompanionInfo
local GetNumCompanions = _G.GetNumCompanions
local pairs = _G.pairs
local PickupCompanion = _G.PickupCompanion
local PlaySound = _G.PlaySound
local tinsert = _G.tinsert
local tonumber = _G.tonumber
local tsort = _G.table.sort
local UIParent = _G.UIParent
local wipe = _G.wipe

local AceGUI = LibStub("AceGUI-3.0")


--------------------------------------------------------------------------------
-- Companion list button element.
--------------------------------------------------------------------------------

do
	local Type, Version = "CompanionListElement", 1

	local function Button_OnClick(frame, ...)
		AceGUI:ClearFocus()

		local widget = frame.obj
		local listWidget = widget:GetUserData('listwidget')

		if not listWidget then return end

		PlaySound("igMainMenuOption")

		local previousID = widget.companionID

		if previousID then
			listWidget:Fire("OnValueChanged", previousID, false)
		end

		local kind, index, companionType = GetCursorInfo()

		if kind == "companion" and tonumber(index) and companionType == "CRITTER" then
			local _, _, spellID = GetCompanionInfo("CRITTER", index)

			widget.spellIndex = index

			listWidget:Fire("OnValueChanged", spellID, true)

			if previousID then
				PickupCompanion("CRITTER", index)
			else
				ClearCursor()
			end
		end
	end

	local function Button_OnDragStart(frame)
		local widget = frame.obj
		local listWidget = widget:GetUserData('listwidget')

		if not listWidget or not widget.companionID or not widget.spellIndex then return end

		PickupCompanion("CRITTER", widget.spellIndex)

		listWidget:Fire("OnValueChanged", widget.companionID, false)
	end

	local function Button_OnEnter(frame)
		local listWidget = frame.obj:GetUserData('listwidget')

		if listWidget then
			listWidget:Fire("OnEnter")

			if frame.obj.companionID then
				local title = GetSpellInfo(frame.obj.companionID)

				GameTooltip:SetText(title)
				GameTooltip:AddLine("Left-click to remove this companion from the list.", 0, 1, 0)
			else
				GameTooltip:AddLine("Drag a companion here from the spellbook to add it to the list.", 0, 1, 0)
			end

			GameTooltip:Show()
		end
	end

	local function Button_OnLeave(frame)
		local listWidget = frame.obj:GetUserData('listwidget')

		if listWidget then
			listWidget:Fire("OnLeave")
		end
	end

	local methods = {}

	function methods:OnAcquire()
		self:SetWidth(32)
		self:SetHeight(32)
	end

	function methods:OnRelease()
		self:SetUserData('listwidget', nil)
	end

	function methods:SetDisabled(disabled)
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end

	function methods:SetCompanionID(companionID)
		self.companionID = companionID

		if companionID then
			local _, _, texture = GetSpellInfo(companionID)

			self.frame:SetNormalTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
			self.frame:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
		else
			self.frame:SetNormalTexture("Interface\\Buttons\\UI-Slot-Background")
			self.frame:GetNormalTexture():SetTexCoord(0, 41/64, 0, 41/64)
		end
	end

	local function Constructor()
		local name = "AceGUI30CompanionListElement" .. AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Button", name, UIParent)

		frame:Hide()
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton", "RightButton")

		frame:SetScript("OnClick", Button_OnClick)
		frame:SetScript("OnReceiveDrag", Button_OnClick)
		frame:SetScript("OnDragStart", Button_OnDragStart)
		frame:SetScript("OnEnter", Button_OnEnter)
		frame:SetScript("OnLeave", Button_OnLeave)

		frame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

		local widget = {
			frame = frame,
			type  = Type
		}

		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

--------------------------------------------------------------------------------
-- Companion list.
--------------------------------------------------------------------------------

do
	local Type, Version = "CompanionList", 1

	local methods = {}

	function methods:SetMultiselect()
		-- noop
	end

	function methods:SetLabel(name)
		self:SetTitle(name)
	end

	function methods:SetDisabled(disabled)
		for _, child in pairs(self.children) do
			child:SetDisabled(disabled)
		end
	end

	local function AddItem(self, companionID)
		local widget = AceGUI:Create('CompanionListElement')

		widget:SetUserData('listwidget', self)
		widget:SetCompanionID(companionID)

		self:AddChild(widget)

		return widget
	end

	local t = {}
	function methods:SetList(values)
		self:PauseLayout()
		self:ReleaseChildren()

		wipe(t)

		for companionID in pairs(values) do
			tinsert(t, companionID)
		end

		tsort(t)

		for _, companionID in pairs(t) do
			AddItem(self, companionID)
		end

		AddItem(self, nil)

		self:SetLayout("Flow")
		self:ResumeLayout()
		self:DoLayout()
	end

	function methods:SetItemValue()
		-- noop
	end

	local function Constructor() -- create an InlineGroup widget and "upgrade" it to CompanionList
		local widget = AceGUI.WidgetRegistry.InlineGroup()

		widget.type = Type

		for method, func in pairs(methods) do
			widget[method] = func
		end

		return widget
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
