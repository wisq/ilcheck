# ILCheck

Manages your FFXIV inventory.  Identifies items that you've outgrown, or future gear that is worse than other future gear at the same level.

## Why?

I've been really good at levelling up all my classes (everything except BLU is in the 70-90 range), but really bad at doing MSQ, so I don't have access to 80 or 90 poetics gear yet.  My retainers have been bringing me gear all the way up to level 90, which is great, but there's a big mishmash of item levels in the 80-90 range, and it can be tricky to keep track of which items are better than others.

As such, I wrote this to manage my gear for me.  I provide it with a CSV export of my relevant gear, and it lets me know which items I should consider putting into my armoury, versus which ones I should throw away.  (It also reserves the best gear for my retainers, because having better gear helps them bring back better gear.)

You may find it useful as a general cleanup tool, since it will (hopefully) identify items that are worse than other items in your armoury, or that all your classes have outgrown.

… Or maybe it'll get super confused by your inventory, and it'll tell you to do a bunch of silly things, and you won't find it useful at all.  No idea!  I'm just putting this out there, because why not.

## How it works

Essentially, there are four places your equipment can be:

 * Equipped to your retainer
 * In your **current** equipment — either on your character right now, or in your armoury chest
 * In your **future** equipment — same as above, plus the chocobo saddlebag, where you can store equipment you're not using yet (if your armoury is full)
 * In your inventory — also considered the "discard" pile

When run, the planner will go through your items, in best-to-worst order, and start assigning them to those categories.  Your best items will go to your retainer (if configured), then to your current/future equipment (depending on whether you can equip it yet or not).

For any given piece of gear, we check if we've already seen gear in the same slot with the same equip level (or lower).  Since we're going through the items best-to-worst, we know that if we've seen **any** matching gear so far, then this gear must be worse and we can throw it out.  For example, we might see a Cryptlurker Sickle (level 80, iLvl 530), and then a Monstrorum Sickle (level 81, iLvl 520) — in this case, we can throw out the Monstrorum Sickle, because a level 81 character could just equip the Cryptlurker.  (The only exception is rings, where we need to have seen **two** rings at any given level before we start throwing worse ones out.)

## Usage

To use this tool, you need to be running the "Inventory Tools" plugin.  You'll export a CSV file containing the relevant gear, and then this program will parse that CSV.

### Exporting CSV

1. Fire up FFXIV using [XIVLauncher](https://github.com/goatcorp/FFXIVQuickLauncher) with Dalamud integration enabled.
2. In-game, install the "Inventory Tools" plugin.
3. Create a filter with the following parameters:
  * **Basic → Equippable By Gender**: your gender (this gets rid of non-equipment items)
  * **Basic → Required Level** (optional): if you only want to check items over a certain equip level — I put in `>=70` to only consider level 70+ gear
  * **Basic → Item Level** (optional): if you only want to check items over a certain iLvl — I put in `>=400` to only consider Scaevan gear and up
  * **Inventories → Source - All Characters?:** Yes
  * **Inventories → Source - All Retainers?:** Yes (if you want to check retainer gear and/or reserve gear for your retainers)
  * **Columns:** You can add any columns you want, but these columns **must** be included:
    * Name
    * Category
    * Source
    * Location
    * Item Level
    * iLevel
    * Equippable By
    * Type
    * Rarity
4. Now pull up your filter.
  * If you checked off "Display in Tab List", you'll see it across the top bar of Inventory Tools.
  * Otherwise, go to the "Filters" tab and navigate to your filter.
5. You should see a list of relevant items.  Click "Export to CSV".  Save it somewhere.

### Running ILCheck

1. Run `mix deps.get` to fetch dependencies.
2. Copy `config/example.exs` to `config/config.exs` and edit it:
  * Fill in your character's in-game name.
  * If you want to reserve items for retainers, move those classes to the top and fill in their levels and retainer names.
  * Fill in the rest of your levels.
    * If you don't have a class yet, put in its level as 0.
    * If you don't care about a class whatsoever, you can just delete it.
    * What's the difference?  If you have e.g. a BLM at 75 and an RDM at 0, ILCheck will suggest you hold on to your best 1 to 75 gear for your future RDM.  If you omit RDM entirely, it'll just find the best gear for your BLM and then suggest you throw out all your <75 caster gear.
3. Run `mix ilcheck.plan <path to CSV>`.
4. Perform the actions it suggests.  (Or don't, up to you.  But it'll keep nagging you each time you run it.)

To "discard" an item, just move it to your inventory — you don't have to get rid of it right away.

Note that the planner *will continue looking* at your inventory (even if it's also the "discard" pile).  So once you acquire new gear, you can perform another export, and then run this again.

If it tells you to move the gear to your armoury — great, you've found new & better gear.  If it tells you "nothing to do", then nothing in your inventory is better than what you've already got, and you should be able to safely get rid of all the gear in your inventory.

## Quirks

### Retainer gear

**If a retainer is configured, we always reserve the absolute best gear for them.**

I give my retainers the best gear so they can bring me the best gear, and so any unique gear they're wearing doesn't prevent me from getting that unique gear for myself.

If your retainer's level is lower than your best gear, this **will** be a problem.  It'll suggest you equip gear that they can't equip, and also take off the gear they're already wearing.  This isn't quick or easy to fix, and it's moot for me, since mine are level 90 now.  (Maybe I'll fix it on the next level expansion.)

### Saddlebags

**The chocobo saddlebag is considered overflow for the armoury chest.**  My weapon bag got full, so I needed somewhere to store future weapons.

If your saddlebag contains equipment that should be equipped to a class right now (e.g. you've been keeping an 82 WAR weapon in here and your WAR just turned 82), it'll tell you to move them to the armoury chest.

If you have **future** equipment in here, it'll leave them alone.  If there's junk equipment, it'll tell you to discard them, i.e. move them to your inventory.

### Limited jobs

**There's currently no code to handle the Blue Mage level limitation.**  In theory, it ought to ignore BLU gear over 70, unless you're playing the _really long game_ and waiting for a BLU level expansion.

In practice, since I already only use this to manage my 71+ gear, it's kinda moot for me. Personally, I just don't put BLU in my `config.exs`, so it doesn't reserve any caster gear below my lowest caster class.

## Disclaimers

This program is heavily tuned for my own use case.  I'm releasing it because I've had some requests to do so, and I figure it might be useful to someone.

If you want to edit it for your own needs, then cool, but this is just a quick and dirty tool for sorting my own inventory, and it's not meant to be a general solution for everyone.  If you want to add features and send me PRs, that's cool too, but your changes had better be optional (i.e. configurable) and backwards-compatible with my own usage.

I currently only run this on level 70+ / iLvl 400+ gear.  I can't guarantee it'll make sensible decisions for anything below that.  (There's some specific tuning for level 80 gear with unreliable iLevels, e.g. NQ items.)

Finally, **before throwing out any items, double check that you're making the right choice first.**  You use ILCheck at your own risk, and I accept **zero** responsibility for lost items.  If ILCheck tells you to do something, and you do it, and it was your prized penta-melded item, that's on you.
