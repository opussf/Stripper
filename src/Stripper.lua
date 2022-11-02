STRIPPER_SLUG, Stripper = ...
STRIPPER_MSG_ADDONNAME = GetAddOnMetadata( STRIPPER_SLUG, "Title" )
STRIPPER_MSG_AUTHOR    = GetAddOnMetadata( STRIPPER_SLUG, "Author" )
STRIPPER_MSG_VERSION   = GetAddOnMetadata( STRIPPER_SLUG, "Version" )

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

Stripper.slotListMap={
		"HeadSlot","NeckSlot","ShoulderSlot","ShirtSlot","ChestSlot","WaistSlot","LegsSlot",
		"FeetSlot", "WristSlot", "HandsSlot", "Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot",
		"BackSlot","MainHandSlot","SecondaryHandSlot","RangedSlot","TabardSlot"
}
Stripper.slotListRemove = {
		"Trinket0Slot", "Trinket1Slot", "Finger0Slot",
		"Finger1Slot", "NeckSlot", "BackSlot",
		"WristSlot", "WaistSlot", "HandsSlot",
		"FeetSlot", "ShoulderSlot", "HeadSlot",
		"LegsSlot","ChestSlot",	"ShirtSlot",
		"SecondaryHandSlot", "MainHandSlot"
}
Stripper.slotListAdd = {
		"MainHandSlot", "SecondaryHandSlot",
		"Trinket0Slot", "Trinket1Slot", "Finger0Slot",
		"Finger1Slot", "NeckSlot", "BackSlot",
		"WristSlot", "WaistSlot", "HandsSlot",
		"FeetSlot", "ShoulderSlot", "HeadSlot",
		"LegsSlot", "ShirtSlot", "ChestSlot",
}
Stripper.setWaitTime = 5

Stripper.bitFields = {
	["combat"] = 0x01,
	["fishing"] = 0x02,
	["petbattle"] = 0x04,
}

-- Support code
function Stripper.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED..STRIPPER_MSG_ADDONNAME.."> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end
function Stripper.ParseCmd(msg)
	if msg then
		local a,b,c = strfind(msg, "(%S+)");  --contiguous string of non-space characters
		if a then
			return c, strsub(msg, b+2);
		else
			return "";
		end
	end
end
function isEquipmentSet( testStr )
	for setNum = 0, C_EquipmentSet.GetNumEquipmentSets(),1 do
		equipmentSetName = C_EquipmentSet.GetEquipmentSetInfo( setNum )
		if( equipmentSetName and string.lower( equipmentSetName ) == testStr ) then
			return C_EquipmentSet.GetEquipmentSetInfo( setNum ), setNum
		end
	end
	return nil
end
-- Event Handlers
function Stripper.OnLoad()
	StripperFrame:RegisterEvent("ADDON_LOADED")
	StripperFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	StripperFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	StripperFrame:RegisterEvent("PET_BATTLE_OPENING_START")
	StripperFrame:RegisterEvent("PET_BATTLE_CLOSE")
	StripperFrame:RegisterEvent("UNIT_AURA")

	-- EQUIPMENT_SWAP_PENDING
	-- EQUIPMENT_SWAP_FINISHED
	-- ITEM_LOCK_CHANGED
	-- PLAYER_EQUIPMENT_CHANGED

	--register slash commands
	SLASH_STRIPPER1 = "/stripper";
	SLASH_STRIPPER2 = "/st";
	SLASH_STRIPPER3 = "/mm";
	SlashCmdList["STRIPPER"] = function(msg) Stripper.Command(msg); end
end
function Stripper.ADDON_LOADED( _, arg1 )
	if( arg1 == STRIPPER_SLUG ) then
		Stripper.Print( STRIPPER_MSG_VERSION.." loaded" )
		StripperFrame:UnregisterEvent("ADDON_LOADED")
	end
end
function Stripper.PLAYER_REGEN_ENABLED()
	Stripper.clearIsBusy( Stripper.bitFields.combat )
	Stripper.OnUpdate()
end
function Stripper.PLAYER_REGEN_DISABLED()
	Stripper.setIsBusy( Stripper.bitFields.combat )
end
function Stripper.PET_BATTLE_OPENING_START()
	Stripper.setIsBusy( Stripper.bitFields.petbattle )
end
function Stripper.PET_BATTLE_CLOSE()
	Stripper.clearIsBusy( Stripper.bitFields.petbattle )
	if Stripper.addLater then Stripper.addLater = time() + 2 end
	Stripper.OnUpdate()
end
function Stripper.UNIT_AURA( arg1 )
	if (arg1 == "player") then
		Stripper.clearIsBusy( Stripper.bitFields.fishing )
		for an = 1,40 do
			aName = UnitAura( arg1, an )
			if( aName and aName == "Fishing" ) then
				Stripper.setIsBusy( Stripper.bitFields.fishing )
				break
			end
		end
	end
end
function Stripper.setIsBusy( valIn )
	Stripper.isBusy = bit.bor( (Stripper.isBusy or 0), valIn )
end
function Stripper.clearIsBusy( valIn )
	valIn = bit.bnot( valIn )
	Stripper.isBusy = bit.band( (Stripper.isBusy or 0), valIn )
	if (Stripper.isBusy == 0) then Stripper.isBusy = nil; end
end
function Stripper.OnUpdate()
	if (not Stripper.isBusy) then
		if Stripper.removeLater then
			Stripper.RemoveOne()
		elseif Stripper.addLater and Stripper.addLater <= time() then
			Stripper.AddOne()
		end
	end
	if Stripper.targetSet then
		Stripper.updateBar()
	end
end
function Stripper.updateBar()
	Stripper_TimerBar:Show()
	Stripper_TimerBar:SetMinMaxValues( 0, Stripper.setWaitTime )
	Stripper_TimerBar:SetValue( Stripper.addLater - time() )
	Stripper_TimerBarText:SetText( Stripper.targetSet.."::"..SecondsToTime(Stripper.addLater - time(), false, false, 1 ) )
end
function Stripper.getFreeBag()
	-- http://www.wowwiki.com/BagId
	-- bags are 0 based, right to left.  0 = backpack
	local freeSlots, typeid, firstFreeBag, firstFreeEquipmentBag
	for bagid = NUM_BAG_SLOTS, 0, -1 do
		freeSlots, typeid = GetContainerNumFreeSlots(bagid)
		isEquipmentBag = C_Container.GetBagSlotFlag( bagid, 2 )
		--isEquipmentBag = true    -- @TODO:   figure this shit out again.
		--print( "bag: "..bagid.." isType: "..(typeid or "nil").." free: "..freeSlots.." isEquipmentBag: "..( isEquipmentBag and "True" or "False" ) )
		if( typeid == 0 ) then  -- 0 = no special bag type ( Herb, mine, fishing, etc... )
			if( not firstFreeBag ) then
				firstFreeBag = ( not isEquipmentBag and freeSlots > 0 ) and bagid
			end
			if( not firstFreeEquipmentBag ) then
				firstFreeEquipmentBag = ( isEquipmentBag and freeSlots > 0 ) and bagid
			end
		end
	end
	--print( "firstFreeBag: "..(firstFreeBag or "False").." firstEquipmentBag: "..(firstFreeEquipmentBag or "False") )
	if( firstFreeEquipmentBag and firstFreeEquipmentBag >= 0 ) then
		--print( "returning firstFreeEquipmentBag: "..firstFreeEquipmentBag )
		return firstFreeEquipmentBag
	end
	if( firstFreeBag and firstFreeBag >=0 ) then
		--print( "returning firstFreeBag: "..firstFreeBag )
		return firstFreeBag
	end
end
function Stripper.getItemToRemove()
	-- Finds the first item in the list of slots
	-- Returns: slotNum, slotName
	for _,v in pairs(Stripper.slotListRemove) do
		local slotNum = GetInventorySlotInfo(v)
		local itemId = GetInventoryItemID("player", slotNum)
		if itemId then
			--Stripper.Print(v..":"..itemId);
			return slotNum, v
		end
	end
end
function Stripper.RemoveFromSlot( slotName, report )
	-- Remove an item from slotName with optional reporting
	-- String: slotName to remove an item from
	-- Boolean: report - to report or not.
	ClearCursor()
	local freeBagId = Stripper.getFreeBag()
	--Stripper.Print("Found a free bag: "..freeBagId);

	if freeBagId then
		local slotNum = GetInventorySlotInfo( slotName )
		--Stripper.Print(slotName..":"..slotNum..":"..(GetInventoryItemLink("player",slotNum) or "nil"))
		if report then
			Stripper.Print( "Removing "..(GetInventoryItemLink("player",slotNum) or "nil") )
		end
		PickupInventoryItem(slotNum)
		if freeBagId == 0 then
			PutItemInBackpack()
		else
			PutItemInBag(freeBagId+30)
		end
		return true
	else
		if report then
			Stripper.Print("No more stripping for you.  Inventory is full");
		end
	end
end
function Stripper.RemoveOne()
	if Stripper.isBusy then
		Stripper.removeLater = true;
		Stripper.Print("You are busy. An item will be removed when you finish.");
	else
		local _, slotName = Stripper.getItemToRemove()  -- slotNum, slotName
		if slotName then
			Stripper.RemoveFromSlot( slotName, true )
		end
		Stripper.removeLater = nil;
	end
	if Rested then
		--Rested.Command( "iLvl" )
	end
end
function Stripper.AddOne()
	-- Loop through the targetSetItemArray
	-- Compare the item to the one in the slot.
	-- EquipSet id=1 is ignore

	-- itemId = GetInventoryItemID("unit", invSlot)

	if Stripper.isBusy then
		Stripper.addLater = time();
		Stripper.Print("You are busy. An item will be equipped when you finish.");
	else
		ClearCursor();
		local i = 0
		for _,v in pairs(Stripper.slotListAdd) do -- Loop through the slot list
			for ii=1, 19 do                    -- find the index number
				if v == Stripper.slotListMap[ii] then
					i = ii
					break
				end
			end
			local slotName = Stripper.slotListMap[i]
			if slotName then
				local equipped = GetInventoryItemID("player",i)  -- nil if not equipped
				--Stripper.Print("slot: "..i.." equipped:"..(equipped or "nil"))
				--Stripper.Print("Should be: "..(Stripper.targetSetItemArray[i] or "nil"))

				if (Stripper.targetSetItemArray[i] ~= 1) and (equipped ~= Stripper.targetSetItemArray[i]) then
					-- not to be ignored, and not the same item.
					--print(Stripper.targetSetItemArray[i])
					if (not Stripper.targetSetItemArray[i]) then  -- remove item  -- changed from 0 to nil?
						-- Stripper.Print( "Need to remove an item from "..slotName )
						if Stripper.RemoveFromSlot( slotName, true ) then
							Stripper.addLater = time()+Stripper.setWaitTime;
							return
						else
							break -- break from the for loop if unable to remove item
						end
					elseif (Stripper.targetSetItemArray[i]) then
						--Stripper.Print("Looking at "..Stripper.targetSetItemArray[i])
						local _,itemLink = GetItemInfo(Stripper.targetSetItemArray[i])
						if (GetItemCount(Stripper.targetSetItemArray[i]) > 0) then
							Stripper.Print( "Equipping "..(itemLink or "unknown") )
							EquipItemByName( Stripper.targetSetItemArray[i], i )
							Stripper.addLater = time()+Stripper.setWaitTime;
							--Stripper.Print( "Setting future add to "..Stripper.addLater..". Now: "..time())
							return
						else
							Stripper.Print( (itemLink or "unknown").." is not available to equip." )
							Stripper.targetSetItemArray[i] = nil
							break -- break from the for loop if item is not inventory
						end
					else
						Stripper.Print("Slot "..i.." is nil?")
					end
				end
				--print(i, Stripper.slotListMap[i], equipped, (GetItemInfo(Stripper.targetSetItemArray[i])));
			end
		end
		Stripper.targetSet = nil
		Stripper.targetSetItemArray = nil
		Stripper.Print("Ending targetSet");
		Stripper.addLater = nil;
		Stripper_TimerBar:Hide()
	end
end
-- Command code
function Stripper.PrintHelp()
	Stripper.Print(STRIPPER_MSG_ADDONNAME.." version: "..STRIPPER_MSG_VERSION)
	Stripper.Print("Use: /stripper, /st, or /mm for these commands:")

	for cmd, info in pairs(Stripper.commandList) do
		Stripper.Print(string.format("-- %s %s -> %s",
			cmd, info.help[1], info.help[2]));
	end
end
Stripper.commandList = {
	["help"] = {
		["func"] = Stripper.PrintHelp,
		["help"] = {"", "Print this help"},
	},
	["remove"] = {
		["func"] = Stripper.RemoveOne,
		["help"] = {"", "Remove a piece of gear. Default action."},
	},
	["<EquipmentSet>"] = {
		["help"] = {"<delay seconds>", "Change to <EquipmentSet>, one piece every <delay seconds>"}
	},
}
function Stripper.Command( msg )
	local cmd, param = Stripper.ParseCmd(msg);
	cmd = string.lower(cmd);
	local cmdFunc = Stripper.commandList[cmd];
	if cmdFunc then
		cmdFunc.func(param);
	else
		local setName, setNum = isEquipmentSet(cmd);
		if setName then
			Stripper.setWaitTime = tonumber(param) or 5
			Stripper.targetSet = setName
			Stripper.Print("Set targetSet to "..Stripper.targetSet);
			local setItemArray = C_EquipmentSet.GetItemIDs( setNum )
			local setIgnoredSlots = C_EquipmentSet.GetIgnoredSlots( setNum )

			for slot = 1, 19 do
				local itemId = GetInventoryItemID( "player", slot )   -- nil means no current item
				if( setIgnoredSlots[slot] and itemId ) then -- slot is ignored, and there is an item
					setItemArray[slot] = itemId
				end
			end
			Stripper.targetSetItemArray = setItemArray
			--Stripper.targetSetItemArray = C_EquipmentSet.GetItemIDs( setNum );
			Stripper.AddOne();
		else
			Stripper.commandList.remove.func()
		end
	end
end
