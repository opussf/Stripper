#!/usr/bin/env lua

addonData = { ["version"] = "1.0",
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
function test.test_getFreeBag_HasFreeSpace_OnlyBackpack_Empty()
	-- Test that it finds a bag that has free space.
	local bagid = Stripper.getFreeBag()
	assertEquals( 0, bagid )
end

test.run()
