# AngelBob Space Age Cobalt / Chrome Chain Hotfix

A narrow compatibility hotfix for **AngelBob Space Age Rebalance** on Factorio **2.0.x**.

## Cobalt bug

In the affected final runtime technology graph:

- `angels-roll-cobalt` is owned only by `angels-cobalt-casting-2`
- `angels-roll-cobalt-2` is owned only by `angels-cobalt-casting-3`
- both owner technologies are hidden and disabled
- their prerequisites can already be researched

The hotfix enables each cobalt roll recipe only when its hidden+disabled owner exists and all of that owner's prerequisites are researched.

## Chrome bug

Chrome is broken differently. The affected runtime graph shows:

- `angels-chrome-casting-2` and `angels-chrome-casting-3` hidden+disabled
- their unlock effect lists stripped
- `angels-liquid-molten-chrome`, `angels-plate-chrome`, `angels-plate-chrome-2`, `angels-roll-chrome`, `angels-roll-chrome-2`, and `angels-powder-chrome` with no unlock owner

Version 0.1.2 restores those recipes behind the progression gates present in Angel's upstream technology graph:

- Chrome Smelting 1 -> molten chrome + chrome plate
- Chrome Smelting 2 -> chrome powder
- Chrome Smelting 1 + Strand Casting 4 -> chrome sheet coil + secondary plate recipe
- Chrome Smelting 3 -> advanced chrome sheet coil

The Chrome repair only runs while the casting branch is hidden+disabled and only touches recipes that still have **no technology unlock owner**. If upstream later restores a proper owner, the hotfix leaves that recipe alone.

## What this mod does not change

It does not alter recipe ingredients, material ratios, crafting categories, machines, science costs, or unhide the obsolete casting technologies.

## Existing saves

Install the zip and load the save. Factorio's configuration-change event applies eligible repairs automatically. Future research completions are also checked.

Diagnostics:

```text
/ab-cobalt-hotfix-status
/ab-chrome-chain-status
```

## Reported environment

- Factorio 2.0.77
- Space Age 2.0.77
- AngelBob Space Age Rebalance 1.1.42

## Removal

Once the upstream mod restores reachable recipe ownership for these chains, the guards in this compatibility shim should cause it to stop intervening.
