# FEATURES

## syserr
This is an attempt to allow someone to equip an item when in combat, or otherwise busy.
This will detect when the player attempts to equip an item, and will equip it after the player is not busy.

The initial attempt idea is to catch an error on trying to equip an item.
What it has come to is this:

* Click on item in bags
	- ITEM_LOCKED (bag, slot)
	- Throws UI_ERROR
	- Record the (bag, slot) when the UI_ERROR happened.
	- Find item that is locked (GetContainerItemID( bag, slot ))
	- Find the slot GetItemInfo(itemID)  -- http://wowwiki.wikia.com/wiki/API_GetItemInfo
 		- (select(9,))  -- string
 			- This does not always seem to work out.

