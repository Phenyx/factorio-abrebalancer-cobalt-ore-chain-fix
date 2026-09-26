# AngelBob Space Age Cobalt Chain Hotfix

A narrow compatibility hotfix for **AngelBob Space Age Rebalance** on Factorio **2.0.x**.

## The bug

In the affected mod set, the final runtime technology graph contains:

- `angels-roll-cobalt` owned by `angels-cobalt-casting-2`
- `angels-roll-cobalt-2` owned by `angels-cobalt-casting-3`
- both owning technologies are hidden and disabled
- all prerequisites of those hidden technologies can already be researched

The upstream cobalt unlock audit sees an unlock owner and reports success, but the player can never research the owner, leaving the sheet-coil recipes disabled.

## What this mod changes

It does **not** unhide, enable, or rewrite the casting technologies.

For each affected cobalt casting technology, it enables the associated coil recipe only when:

1. the owner technology exists,
2. the owner technology is hidden,
3. the owner technology is disabled, and
4. every prerequisite of that owner technology is already researched.

That preserves the prerequisite gates already present in the loaded technology graph. The hidden+disabled guard also makes the hotfix stop intervening if upstream later restores the casting technology normally.

No recipe ingredients, material ratios, crafting categories, machines, or technology costs are changed.

## Existing saves

Install the zip and load the save. Factorio's configuration-change event applies the repair automatically.

Diagnostics:

```text
/ab-cobalt-hotfix-status
/ab-chrome-chain-status
```

The Chrome command is diagnostic only. Version 0.1.1 does not alter Chromium/Chrome progression.

## Reported environment

- Factorio 2.0.77
- Space Age 2.0.77
- AngelBob Space Age Rebalance 1.1.42

## Removal

After an upstream fix, verify that the cobalt roll recipes have reachable upstream unlocks. The hotfix's hidden+disabled guard should make it a no-op once the original casting technologies are restored.
