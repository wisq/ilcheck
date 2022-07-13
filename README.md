# ILCheck

Manages your FFXIV inventory.  Identifies items that you've outgrown, or future gear that is worse than other future gear at the same level.

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

1. Copy `config/example.exs` to `config/config.exs` and edit it:
  * Fill in your character's in-game name.
  * If you want to reserve items for retainers, move those classes to the top and fill in their levels and retainer names.
  * Fill in the rest of your levels.
    * If you don't have a class yet, put in its level as 0.
    * If you don't care about a class whatsoever, you can just delete it.
    * What's the difference?  If you have e.g. a BLM at 75 and an RDM at 0, ILCheck will suggest you hold on to your best 1 to 75 gear for your future RDM.  If you omit RDM entirely, it'll just find the best gear for your BLM and then suggest you throw out all your <75 caster gear.
2. Run `mix ilcheck.plan <path to CSV>`.
3. Perform the actions it suggests.  (Or don't, up to you.  But it'll keep nagging you each time you run it.)

## Disclaimers

This program is heavily tuned for my own use case.  I'm releasing it because I've had some requests to do so, and I figure it might be useful to someone.

If you want to edit it for your own needs, then cool, but this is just a quick and dirty tool for sorting my own inventory, and it's not meant to be a general solution for everyone.  If you want to add features and send me PRs, that's cool too, but your changes had better be optional (i.e. configurable) and backwards-compatible with my own usage.

I currently only run this on level 70+ / iLvl 400+ gear.  I can't guarantee it'll make sensible decisions for anything below that.  (There's some specific tuning for level 80 gear with unreliable iLevels, e.g. NQ items.)

Finally, **before throwing out any items, double check that you're making the right choice first.**  You use ILCheck at your own risk, and I accept **zero** responsibility for lost items.  If ILCheck tells you to do something, and you do it, and it was your prized penta-melded item, that's on you.
