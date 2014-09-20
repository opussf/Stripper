Stripper!

After getting pissed about my monk tank out DPSing the dps classes, I decided to play "Gear Golf".
The idea being that my tank is "over geared", so I should remove gear until my dps is lower than others.

Scoring is simple.  Use the iLvl score of the highest amount of gear that puts the monk tank below the top damage doing player in the group.

Play:
At the end of each battle, remove gear to lower the iLvl.
Do this until dps drops below the top, or threat is hard to maintain.
Add if threat cannot be maintained.

Stripper is set to automate this a bit.


---
Ideas
* /blush only when removing legs and chest
* add /mm (magic mike) as another slash command
* Give it a target gear set to work towards. Works in the same direction.
  /stripper [gear set] sets the set, changes an item.
  /stripper will continue to work towards the gear set until fully changed, then starts stripping again.
* Configure order and slots that are changed
  Stripping to a gear set will over ride the list and do all of the non-ignored slots
* Tie into recount to automate this even more.
  Enable or disable the recount tie in.




----


Changes:
=======================================
1.1.0   2013 Nov 19   Bit of a refactor. Adds the /stripper [gear set] command to slowly switch to a set.
                      Bug - Gets stuck on a ring or trinket that is equipped in the wrong slot.
					  Bug - Does not give up if stuck
1.00    2012 Dec 3    Initial release of Stripper - /stripper or /st  removes clothing down to shirt and tabard, /blushes.
                      Queues a removal of gear if in combat.
                      Shows the link for the gear and the slot it removes from.



