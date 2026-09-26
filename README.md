# AngelBob Space Age Cobalt Chain Hotfix

A deliberately small compatibility hotfix for **AngelBob Space Age Rebalance** on Factorio **2.0.x**.

## The bug

In the affected runtime technology graph:

- `angels-roll-cobalt` is owned only by `angels-cobalt-casting-2`
- `angels-roll-cobalt-2` is owned only by `angels-cobalt-casting-3`
- both owner technologies are hidden and disabled
- their prerequisites can already be researched

The recipes therefore exist but remain disabled forever because their unlock owners cannot be researched.

## What this mod changes

Only the two cobalt sheet-coil recipes are touched.

For each recipe, the hotfix enables it only when:

1. its owning casting technology exists,
2. that technology is hidden,
3. that technology is disabled, and
4. every prerequisite of that technology has already been researched.

It does **not** modify Chromium/Chrome, recipe ingredients, ratios, machines, science costs, or technology visibility.

## Existing saves

Install the zip and load the save. The repair runs on configuration change and after research completes.

Diagnostic command:

```text
/ab-cobalt-hotfix-status
```

## Multiplayer

Factorio multiplayer requires every peer to have the same mod set and version. If this hotfix is not yet published on the Factorio Mod Portal, copy the exact same hotfix zip into every player's `mods` directory before connecting.

## Reported environment

- Factorio 2.0.77
- Space Age 2.0.77
- AngelBob Space Age Rebalance 1.1.42

## Removal

Once upstream restores reachable cobalt sheet-coil unlocks, the hidden+disabled guard should make this shim stop intervening.
