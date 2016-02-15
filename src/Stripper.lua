STRIPPER_MSG_VERSION = GetAddOnMetadata("Stripper","Version");
STRIPPER_MSG_ADDONNAME = "Stripper";

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

Stripper = {};
Stripper.slotListMap={"HeadSlot","NeckSlot","ShoulderSlot","ShirtSlot","ChestSlot","WaistSlot","LegsSlot",
		"FeetSlot", "WristSlot", "HandsSlot", "Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot",
		"BackSlot","MainHandSlot","SecondaryHandSlot","RangedSlot","TabardSlot"};
Stripper.slotListMap[18] = nil  -- no RangedSlot

Stripper.slotListRemove = {
		"Trinket0Slot", "Trinket1Slot", "Finger0Slot",
		"Finger1Slot", "NeckSlot", "BackSlot",
		"WristSlot", "WaistSlot", "HandsSlot",
		"FeetSlot", "ShoulderSlot", "HeadSlot",
		"LegsSlot","ChestSlot",	"ShirtSlot",
		"SecondaryHandSlot", "MainHandSlot"
};
Stripper.slotListAdd = {
		"Trinket0Slot", "Trinket1Slot", "Finger0Slot",
		"Finger1Slot", "NeckSlot", "BackSlot",
		"WristSlot", "WaistSlot", "HandsSlot",
		"FeetSlot", "ShoulderSlot", "HeadSlot",
		"LegsSlot", "ShirtSlot", "ChestSlot",
		"MainHandSlot", "SecondaryHandSlot"
}
Stripper.slotListNum = 17

Stripper.setWaitTime = 5
-- TODO: Make the setWaitTime an option

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
	for setNum = 1, GetNumEquipmentSets(),1 do
		if (string.lower(GetEquipmentSetInfo(setNum)) == testStr) then
			return GetEquipmentSetInfo(setNum);
		end
	end
	return nil;
end

-- Event Handlers
function Stripper.OnLoad()
	StripperFrame:RegisterEvent("ADDON_LOADED")
	StripperFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	StripperFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	CombatTextSetActiveUnit("player")
	StripperFrame:RegisterEvent("COMBAT_TEXT_UPDATE")

	StripperFrame:RegisterEvent("ITEM_LOCKED")
	StripperFrame:RegisterEvent("ITEM_LOCK_CHANGED")
	StripperFrame:RegisterEvent("ITEM_UNLOCKED")
	StripperFrame:RegisterEvent("UI_ERROR_MESSAGE")

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
function Stripper.ADDON_LOADED()
	Stripper.Print("Stripper loaded")
	StripperFrame:UnregisterEvent("ADDON_LOADED")
end
function Stripper.PLAYER_REGEN_ENABLED()
	--Stripper.Print("Out of combat");
	Stripper.isBusy = nil;
	Stripper.OnUpdate();
end
function Stripper.PLAYER_REGEN_DISABLED()
	--Stripper.Print("In combat");
	Stripper.isBusy = true;
end
function Stripper.COMBAT_TEXT_UPDATE( arg1, arg2 )
	if (arg2 == "Fishing") then
		Stripper.isBusy = (arg1 == "SPELL_AURA_START");
	end
	--Stripper.Print("Combat_Text_Update( "..(arg1 or "nil")..", "..(arg2 or "nil").." ) "..(Stripper.isBusy and "true" or "false"));
	Stripper.OnUpdate();
end
function Stripper.ITEM_LOCKED( bag, slot )
	if bag >= 0 then
		--Stripper.Print("bag: "..bag.." slot: "..(slot or "nil").." ITEM_LOCKED")
		Stripper.lockbag = bag
		Stripper.lockslot = slot
	end
end
function Stripper.ITEM_LOCK_CHANGED( bag, slot )
	-- slot may be nil, chaning what bag holds
	if bag >= 0 then
		--Stripper.Print("bag: "..bag.." slot: "..(slot or "nil").." ITEM_LOCK_CHANGED")
	end
end
function Stripper.ITEM_UNLOCKED( unknown1, unknown2 )
	if unknown1 >= 0 then
		--Stripper.Print("bag: "..(unknown1 or "nil").." slot: "..(unknown2 or "nil").." ITEM_UNLOCKED")
		Stripper.lockbag = nil
		Stripper.lockslot = nil
	end
end
function Stripper.UI_ERROR_MESSAGE( message )
	if (Stripper.lockbag and Stripper.lockslot) then
		lockedItem = GetContainerItemID( Stripper.lockbag, Stripper.lockslot )
		Stripper.Print("item:"..lockedItem.." is locked.")
		slotName = select( 9, GetItemInfo(lockedItem) )
		if slotName then
			slotNameModified = _G[slotName].."Slot"
			print("This can be equipped at slot: "..slotName..":".._G[slotName]..":"..slotNameModified)
			slotNumClicked = GetInventorySlotInfo( slotNameModified )
			print(slotNumClicked) --Stripper.targetSetItemArray
			if Stripper.targetSetItemArray then -- is equipping a set
				Stripper.targetSetItemArray[slotNumClicked]=lockedItem
			else -- not equipping set.  set one up
				Stripper.targetSetItemArray = {}
				for _,v in pairs(Stripper.slotListMap) do -- find all equipped items
					slotNum = GetInventorySlotInfo(v)
					itemId = GetInventoryItemID("player", slotNum)
					if itemId then
						print(v.."("..slotNum..") "..itemId)
						Stripper.targetSetItemArray[slotNum] = itemId
					end
				end
				Stripper.targetSetItemArray[slotNumClicked]=lockedItem
				Stripper.AddOne()
			end
		end
	end
end

function Stripper.OnUpdate()
	if (not Stripper.isBusy) then
		if Stripper.removeLater then
			Stripper.RemoveOne();
		elseif Stripper.addLater and Stripper.addLater <= time() then
			Stripper.AddOne();
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
	local freeid, typeid
	for bagid = NUM_BAG_SLOTS, 0, -1 do
		freeid, typeid = GetContainerNumFreeSlots(bagid)
		if freeid > 0 and typeid == 0 then
			return bagid
		end
	end
end
function Stripper.getItemToRemove()
	-- Finds the first item in the list of slots
	-- Returns: slotNum, slotName
	for _,v in pairs(Stripper.slotListRemove) do
		local slotNum = GetInventorySlotInfo(v)
		local itemId = GetInventoryItemID("player", slotNum);
		if itemId then
			--Stripper.Print(v..":"..itemId);
			return slotNum, v;
		end
	end
	return nil;
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
			PutItemInBag(freeBagId+19)
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
		Rested.commandList.ilvl();
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
--[[  -- Un-needed code
function Stripper.Test()
	if Stripper.targetSet then
		Stripper.Print("A targetSet is set:"..Stripper.targetSet);

		local itemIDs = {};
		GetEquipmentSetLocations(Stripper.targetSet, itemIDs);
		for k,v in pairs(itemIDs) do
			local player, bank, bags, location, bag = EquipmentManager_UnpackLocation(v);
			Stripper.Print(k..":"..v..":"..(player and "inInv" or "nil")..":"..(bank and "inBank" or "nil")..":"..(bags and "inBags" or "nil")..":"..location..":"..(bag or "nil"));
		end


	end
end
]]

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
		local setName = isEquipmentSet(cmd);
		if setName then
			Stripper.setWaitTime = tonumber(param) or 5
			Stripper.targetSet = setName
			Stripper.Print("Set targetSet to "..Stripper.targetSet);
			Stripper.targetSetItemArray = GetEquipmentSetItemIDs(Stripper.targetSet) -- returns slot:id
			Stripper.AddOne();
		else
			Stripper.commandList.remove.func()
		end
	end
end
