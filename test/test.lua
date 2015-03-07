#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

--test.outFileName = "../dest/testOut.xml"

-- Figure out how to parse the XML here, until then....
StripperFrame = Frame

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "Stripper"

function test.before()
	Stripper.OnLoad()
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
function test.testPlayerIsBusy_StartsFishing()
	assertFalse( Stripper.isBusy, "Should not be busy" )
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_START", "Fishing" ) -- start fishing event
	assertTrue( Stripper.isBusy, "Should be busy" )
end
function test.testPlayerIsBusy_EndsFishing()
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_START", "Fishing" ) -- start fishing event
	assertTrue( Stripper.isBusy, "Should be busy" )
	Stripper.COMBAT_TEXT_UPDATE( "SPELL_AURA_REMOVED", "Fishing" ) -- start fishing event
	assertFalse( Stripper.isBusy )
end
function test.testGetFreeBag_HasFreeSpace_OnlyBackpack_Empty()
	-- Test that it finds a bag that has free space.
	local bagid = Stripper.getFreeBag()
	assertEquals( 0, bagid )
end
function test.testCommand_Help()
	-- Send the help command  -- no side effects to check on
	Stripper.Command("help")
end
function test.testCommand_RemoveOne()
	Stripper.Command("remove")
end
function test.testCommand_Default()
	Stripper.Command("")
end
function test.testCommand_noGear()
	Stripper.Command("")
	-- no assert, should do nothing, with no failure.
end
function test.testCommand_withGear()
	myGear[1] = "113596" -- http://us.battle.net/wow/en/item/113596/raid-heroic  -- http://www.wowhead.com/item=113596/vilebreath-mask&bonus=0
	Stripper.Command("")
	assertIsNil( myGear[1] ) -- The item should be removed.
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
function test.test_RemoveFromSlot()
end
test.run()
