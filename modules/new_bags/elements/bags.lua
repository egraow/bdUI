local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("New Bags")

mod.bags = mod:create_container("Bags", 0, 4)
mod.bags.cat_pool = CreateObjectPool(mod.category_pool_create, mod.category_pool_reset)
mod.bags.item_pool = CreateObjectPool(mod.item_pool_create, mod.item_pool_reset)

local function close_all()
	mod.bags:Hide()
end
local function open_all()
	mod.bags:Show()
end

local function close_bag()
	mod.bags:Hide()
end

local function open_bag()
	mod.bags:Show()
end

local function toggle_bag()
	mod.bags:SetShown(not mod.bags:IsShown())
end


function mod:create_bags()
	local config = mod:get_save()
	mod.bags:Show()
	mod.bags:SetPoint("BOTTOMRIGHT", bdParent, "BOTTOMRIGHT", -30, 30)
	mod.bags.container:SetHeight(config.bag_height)

	mod.bags.category_items = {}

	mod.bags:RegisterEvent('EQUIPMENT_SWAP_PENDING')
	mod.bags:RegisterEvent('EQUIPMENT_SWAP_FINISHED')
	mod.bags:RegisterEvent('AUCTION_MULTISELL_START')
	mod.bags:RegisterEvent('AUCTION_MULTISELL_UPDATE')
	mod.bags:RegisterEvent('AUCTION_MULTISELL_FAILURE')
	mod.bags:RegisterEvent('BAG_UPDATE_DELAYED')

	-- track when we call vs blizzard ui
	local from_blizzard = true
	-- mod.bags.open = function(self)
	-- 	mod.bags:Show()
	-- end
	-- mod.bags.close = function(self)
	-- 	mod.bags:Hide()
	-- end
	-- mod.bags.toggle = function(self)
	-- 	mod.bags:SetShown(not mod.bags:IsShown())
	-- end

	CloseAllBags()
	CloseSpecialWindows()

	mod:RawHook("ToggleBackpack", toggle_bag, true)
	mod:RawHook("ToggleAllBags", toggle_bag, true)
	mod:RawHook("ToggleBag", toggle_bag, true)

	mod:RawHook("OpenAllBags", open_all, true)

	mod:RawHook("OpenBackpack", open_bag, true)
	mod:RawHook("OpenBag", open_bag, true)

	mod:RawHook("CloseBag", close_bag, true)
	mod:RawHook("CloseBackpack", close_bag, true)

	mod:RawHook("CloseAllBags", close_all, true)
	hooksecurefunc("CloseSpecialWindows", close_all)
	
	-- hooksecurefunc("ToggleAllBags", mod.bags.toggle)
	-- hooksecurefunc("ToggleBag", mod.bags.toggle)



	mod.bags:SetScript("OnEvent", function(self, event, arg1)
		if (event == "EQUIPMENT_SWAP_PENDING" or event == "AUCTION_MULTISELL_START") then
			self.paused = true
		elseif (event == "EQUIPMENT_SWAP_FINISHED" or event == "AUCTION_MULTISELL_FAILURE") then
			self.paused = false
			mod:update_bags()
		else
			if (self.paused) then return end
			mod:update_bags()
		end
	end)

	-- create shortcut category bar
end


--==================================
-- update item tables
--==================================
function mod:update_bags()
	bdUI:profile_start("bags", "update bags", 2)
	local items = {}
	local remove = {}
	local new_items = {}
	local item_weights = {}
	local open_slots = 0
	mod.bags.category_items = {}

	-- first gather all items up
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot);
			local itemID = mod:item_id(itemLink)
			if (texture) then 
				items[#items + 1] = {itemLink, bag, slot, itemID}

				-- add to new items category
				if (C_NewItems.IsNewItem(bag, slot)) then
					if (quality > 0) then
						new_items[#new_items + 1] = {itemLink, bag, slot, itemID}
					end
				end
			else
				open_slots = open_slots + 1
			end
		end
	end

	-- build item category weight table
	for category_name, category in pairs(mod.categories) do
		-- mod.bags.category_items[category_name] = {}
		category.items = {}
		local conditions = category.conditions
		for k = 1, #items do
			v = items[k]

			-- item information
			local itemLink, bag, slot, itemID = unpack(v)
			local name, link, rarity, ilvl, minlevel, itemtype, subtype, count, itemEquipLoc, icon, price, itemTypeID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)

			if (rarity == nil or rarity > 0) then
				item_weights[k] = item_weights[k] or {0, nil}
				local current_weight, parent_category = unpack(item_weights[k])
				local new_weight = 0

				-- evaluate conditions
				if (mod:has_value(conditions['type'], itemTypeID)) then new_weight = new_weight + 1 end -- weight: 1
				if (mod:has_value(conditions['subtype'], itemSubClassID)) then new_weight = new_weight + 1 end -- weight: 1
				if (mod:has_value(conditions['itemids'], itemID)) then new_weight = new_weight + 10 end -- weight: 10

				if (current_weight < new_weight) then
					item_weights[k] = {new_weight, category_name}
				end
			else
				remove[#remove + 1] = k
			end
		end
	end

	-- now loop through categories items that we've weighted out, assign them to their categories
	for k, v in pairs(item_weights) do
		local weight, parent_category = unpack(v)

		if (weight > 0) then
			local itemLink, bag, slot, itemID = unpack(items[k])
			-- local count = #mod.bags.category_items[parent_category]
			-- mod.bags.category_items[parent_category][count + 1] = {itemLink, bag, slot, itemID}
			local count = #mod.categories[parent_category].items
			mod.categories[parent_category].items[count + 1] = {itemLink, bag, slot, itemID}
			remove[#remove + 1] = k
		end
	end

	--=====================
	-- remove what we've used
	--=====================
	for k = 1, #remove do
		items[remove[k]] = nil
	end

	--=====================
	-- didn't find these items
	--=====================
	for k, v in pairs(items) do
		-- local itemLink, bag, slot, itemID = unpack(items[k])
		-- local name, link, rarity, ilvl, minlevel, itemtype, subtype, count, itemEquipLoc, icon, price, itemTypeID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)
		-- local count = #mod.bags.category_items["Uncategorized"]
		-- mod.bags.category_items["Uncategorized"][count + 1] = items[k]
		local count = #mod.categories["Uncategorized"].items
		mod.categories["Uncategorized"].items[count + 1] = items[k]
	end

	--=====================
	-- Add New Items to New Category
	--=====================
	for k = 1, #new_items do
		local v = new_items[k]
		-- local itemLink, bag, slot, itemID = unpack(new_items[k])
		-- local name, link, rarity, ilvl, minlevel, itemtype, subtype, count, itemEquipLoc, icon, price, itemTypeID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)
		-- local count = #mod.bags.category_items["New Items"]
		-- mod.bags.category_items["New Items"][count + 1] = items[k]
		local count = #mod.categories["New Items"].items
		mod.catecategoriesgory["New Items"].items[count + 1] = items[k]
	end

	bdUI:profile_stop("bags", "update bags", 2)

	mod:draw_bags()
end


--==================================
-- draw the bags and categories
--==================================
function mod:draw_bags()
	bdUI:profile_start("bags", "draw bags", 3)

	mod.bags.cat_pool:ReleaseAll() -- release frame pool
	mod.bags.item_pool:ReleaseAll() -- release frame pool
	mod.current_parent = mod.containers["bags"] -- set this to parent the category frames correctly

	-- find out which categories we should display
	local loop_cats = mod:get_visible_categories()

	-- 
	for i = 1, #loop_cats do
		local category = loop_cats[i]
		category.frame = mod.bags.cat_pool:Acquire()
		category.frame.name = category.name

		-- position items in categories
		local width, height = mod:position_items(category.frame, category.items, mod.bags.item_pool)
		category.frame:update_size(width, height)
	end

	-- now position the categories since we have dimensions
	local width, height = mod:position_categories(mod.bags.container, loop_cats, mod.bags.cat_pool)
	mod.bags:update_size(width, height)

	bdUI:profile_stop("bags", "draw bags", 3)	
end