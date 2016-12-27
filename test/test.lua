#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

--test.outFileName = "../dest/testOut.xml"

-- Figure out how to parse the XML here, until then....
StripperFrame = Frame
Stripper_TimerBar = CreateStatusBar()

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "Stripper"

function test.before()
	Stripper.OnLoad()
	bagInfo = {
		[0] = {16, 0},
	}
	Stripper.isBusy = nil
	Stripper.targetSet = nil
	Stripper.targetSetItemArray = nil
end
function test.after()
	myGear = {}
end
function test.testOnLoad()
	-- This may seem noop, but it tests that the OnLoad throws no errors
	assertTrue( SlashCmdList["STRIPPER"] )
end
function test.testPlayerIsBusy_EntersCombat()
	-- Assure that isBusy is set correctly
	Stripper.PLAYER_REGEN_DISABLED()
	assertTrue( Stripper.isBusy )
	Stripper.PLAYER_REGEN_ENABLED()
end
function test.testPlayerIsBusy_LeavesCombat()
	-- Assure that isBusy is cleared correctly
	Stripper.PLAYER_REGEN_DISABLED()
	Stripper.PLAYER_REGEN_ENABLED()
	assertIsNil( Stripper.isBusy )
end
function test.notestPlayerIsBusy_StartsFishing()
	-- @TODO: Fix this
	assertFalse( Stripper.isBusy, "Should not be busy" )
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_START", "Fishing" ) -- start fishing event
	assertTrue( Stripper.isBusy, "Should be busy" )
end
function test.notestPlayerIsBusy_EndsFishing()
	-- @TODO: Fix this
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_START", "Fishing" ) -- start fishing event
	assertTrue( Stripper.isBusy, "Should be busy" )
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_REMOVED", "Fishing" ) -- start fishing event
	assertFalse( Stripper.isBusy )
end
function test.testGetFreeBag_HasFreeSpace_OnlyBackpack_Empty()
	-- Test that it finds a bag that has free space.
	local bagId = Stripper.getFreeBag()
	assertEquals( 0, bagId )
end
function test.testGetFreeBag_HasFreeSpace_Bag1_HasSpace()
	bagInfo = {
		[0] = {0,0},
		[1] = {8,0},
	}
	local bagId = Stripper.getFreeBag()
	assertEquals( 1, bagId )
end
function test.testGetFreeBag_HasNoSpace()
	bagInfo = {
		[0] = {0,0},
		[1] = {0,0},
	}
	local bagId = Stripper.getFreeBag()
	assertIsNil( bagId, "Should be nil")
end
function test.testCommand_EquipSet_useTestSet_equipItem()
	myGear = {} -- Naked
	Stripper.Command("testSet")
	assertEquals( "113596", myGear[1], "Item should have been equipped.")
end
function test.testCommand_EquipSet_useTestSet_isBusy_notEquipped()
	myGear = {} -- Naked
	Stripper.isBusy = true
	Stripper.Command("testSet")
	assertIsNil( myGear[1], "Item should not be equipped.")
end
function test.testCommand_EquipSet_useTestSet_replaceItem()
	myInventory["113596"] = 1
	myGear = { [1] = "113590", } -- something else equiped, replace it.
	Stripper.Command("testSet")
	assertEquals( "113596", myGear[1], "Item should have been replaced.")
end
function test.testCommand_EquipSet_useTestSet_isBusy_addLater_isSet()
	myGear = {} -- Naked
	Stripper.isBusy = true
	Stripper.Command("testSet")
	assertEquals( time(), Stripper.addLater, "Should be set to now." )
end
function test.testCommand_EquipSet_useTestSet_removeItem()
	myGear = {[13] = "113590", } -- something is set in Trinket0Slot, it should be removed
	Stripper.Command("testSet")
	assertIsNil( myGear[13], "Item should not be equipped." )
end
function test.testCommand_EquipSet_useTestSet_addLater_isSet()
	myGear = {[13] = "113590", } -- something is set in Trinket0Slot, it should be removed
	Stripper.Command("testSet")
	assertEquals( time() + Stripper.setWaitTime, Stripper.addLater )
end
function test.testCommand_EquipSet_useTestSet_targetSet_isSet()
	myGear = {[13] = "113590", } -- something is set in Trinket0Slot, it should be removed
	Stripper.Command("testSet")
	assertEquals( "testSet", Stripper.targetSet )
end
function test.testCommand_EquipSet_unknownEquipmentSet()
	myGear[1] = "113596" -- HeadSlot equipped
	Stripper.Command("unknownSet")  -- this should not fail as it will not see the set, and just try to remove one.
	assertIsNil( myGear[1], "HeadSlot should be empty now." ) -- The item should be removed.
end
function test.testCommand_EquipSet_clearsTargetSet_noChangesToBeMade_targetSetCleared()
	-- The current process has Stripper only clear the target set one time period after the final item is used.
	myGear = {[1] = "113596", } -- set already equipped
	Stripper.Command("testSet")
	assertIsNil( Stripper.targetSet )
	assertIsNil( Stripper.targetSetItemArray )
end
function test.testCommand_EquipSet_clearsTargetSet_noChangesToBeMade_addLaterCleared()
	-- The current process has Stripper only clear the target set one time period after the final item is used.
	myGear = {[1] = "113596", } -- set already equipped
	Stripper.Command("testSet")
	assertIsNil( Stripper.addLater )
end
function test.testCommand_EquipSet_clearsTargetSet_ChangesMade_targetSetCleared()
	myInventory["113596"] = 1
	myGear = {}
	Stripper.Command("testSet")  -- equip the item
	Stripper.addLater = time() - 1 -- force addLater to be in the past
	Stripper.OnUpdate()  -- check that set is fully equipped, clear control vars
	assertIsNil( Stripper.targetSet )
	assertIsNil( Stripper.targetSetItemArray )
end
function test.testCommand_EquipSet_clearsTargetSet_ChangesMade_addLaterCleared()
	myInventory["113596"] = 1
	myGear = {}
	Stripper.Command("testSet")  -- equip the item
	Stripper.addLater = time() - 1 -- force addLater to be in the past
	Stripper.OnUpdate()  -- check that set is fully equipped, clear control vars
	assertIsNil( Stripper.addLater )
end
function test.testCommand_Help()
	-- Send the help command  -- no side effects to check on
	Stripper.Command("help")
end
function test.testCommand_RemoveOne()
	Stripper.Command("remove")
end
function test.testCommand_Default()
	-- This tests command works.
	Stripper.Command("")
end
function test.testCommand_noGear()
	-- This is to test that trying to remove an item with nothing equipped does not fail.
	Stripper.Command("")
	-- no assert, should do nothing, with no failure.
end
function test.testCommand_withGear_toBackpack()
	-- Default is only backpack equipped with 16 free slots.
	myGear[1] = "113596" -- http://us.battle.net/wow/en/item/113596/raid-heroic  -- http://www.wowhead.com/item=113596/vilebreath-mask&bonus=0
	Stripper.Command("")
	assertIsNil( myGear[1], "HeadSlot should be empty now." ) -- The item should be removed.
end
function test.testCommand_withGear_toBag1()
	-- Strip an equipped item to not the backpack
	bagInfo = {
		[0] = {0,0}, -- backpack is full
		[1] = {8,0}, -- bag 1 has 8 free slots
	}
	myGear[1] = "113596" -- HeadSlot equipped
	Stripper.Command("")
	assertIsNil( myGear[1], "HeadSlot should be empty now." ) -- The item should be removed.
end
function test.testCommand_withGear_toBackpack_isFull()
	bagInfo = {
		[0] = {0,0}, -- backpack is full
	}
	myGear[1] = "113596" -- HeadSlot equipped
	Stripper.Command("")
	assertEquals( "113596", myGear[1], "Item should not have been removed.")
end
function test.testGetItemToRemove_NothingEquipped()
	local result = Stripper.getItemToRemove()
	assertIsNil( result )
end
function test.testGetItemToRemove_HeadEquipped_Number()
	myGear[1] = "113596" -- http://us.battle.net/wow/en/item/113596/raid-heroic  -- http://www.wowhead.com/item=113596/vilebreath-mask&bonus=0
	local result = Stripper.getItemToRemove()
	assertEquals( 1, result )
end
function test.test_GetItemToRemove_HeadEquipped_Name()
	myGear[1] = "113596" -- http://us.battle.net/wow/en/item/113596/raid-heroic  -- http://www.wowhead.com/item=113596/vilebreath-mask&bonus=0
	local result = select(2, Stripper.getItemToRemove())
	assertEquals( "HeadSlot", result )
end


--function test.test_RemoveFromSlot()
--end
test.run()
