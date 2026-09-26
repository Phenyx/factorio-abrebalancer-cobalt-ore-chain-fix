-- AngelBob Space Age Cobalt / Chrome Chain Hotfix
-- Factorio 2.0 branch
--
-- Cobalt failure mode:
--   The sheet-coil recipes still have unlock owners, but those technologies are
--   hidden+disabled and therefore cannot be researched.
--
-- Chrome failure mode:
--   The final runtime graph has the Chrome casting technologies hidden+disabled,
--   while the molten/plate/roll recipes have no unlock owner at all.  We restore
--   those recipes behind the progression gates used by Angel's upstream graph.
--
-- Every repair is guarded so a later upstream fix takes precedence.

local COBALT_RULES = {
  {
    technology = "angels-cobalt-casting-2",
    recipes = { "angels-roll-cobalt" },
  },
  {
    technology = "angels-cobalt-casting-3",
    recipes = { "angels-roll-cobalt-2" },
  },
}

local CHROME_RULES = {
  -- Upstream chrome-smelting-1 owns molten chrome and the direct plate recipe.
  {
    required = { "angels-chrome-smelting-1" },
    recipes = { "angels-liquid-molten-chrome", "angels-plate-chrome" },
  },
  -- Upstream chrome-smelting-2 owns chrome powder.
  {
    required = { "angels-chrome-smelting-2" },
    recipes = { "angels-powder-chrome" },
  },
  -- Upstream chrome-casting-2 is gated by Chrome Smelting 1 + Strand Casting 4.
  {
    required = { "angels-chrome-smelting-1", "angels-strand-casting-4" },
    recipes = { "angels-roll-chrome", "angels-plate-chrome-2" },
  },
  -- Angel's migration path maps the retired casting tier 3 to chrome-smelting-3.
  {
    required = { "angels-chrome-smelting-3" },
    recipes = { "angels-roll-chrome-2" },
  },
}

local function bool(value)
  return value and "true" or "false"
end

local function all_prerequisites_researched(technology)
  if not technology then
    return false
  end
  for _, prerequisite in pairs(technology.prerequisites or {}) do
    if not prerequisite.researched then
      return false
    end
  end
  return true
end

local function all_named_technologies_researched(force, names)
  for _, name in ipairs(names) do
    local technology = force.technologies[name]
    if not technology or not technology.researched then
      return false
    end
  end
  return true
end

local function is_hidden_disabled(technology)
  return technology
    and technology.prototype
    and technology.prototype.hidden
    and not technology.enabled
end

local function technology_unlocks_recipe(technology, recipe_name)
  if not technology or not technology.prototype then
    return false
  end
  for _, effect in pairs(technology.prototype.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return true
    end
  end
  return false
end

local function recipe_has_unlock_owner(force, recipe_name)
  for _, technology in pairs(force.technologies) do
    if technology_unlocks_recipe(technology, recipe_name) then
      return true
    end
  end
  return false
end

local function chrome_branch_is_orphaned(force)
  local c2 = force.technologies["angels-chrome-casting-2"]
  local c3 = force.technologies["angels-chrome-casting-3"]
  return is_hidden_disabled(c2) and is_hidden_disabled(c3)
end

local function refresh_force(force, reason)
  if not force then
    return
  end

  local cobalt_changed = {}
  local chrome_changed = {}

  -- Cobalt: preserve the prerequisite graph of the inaccessible owner technology.
  for _, rule in ipairs(COBALT_RULES) do
    local technology = force.technologies[rule.technology]
    if is_hidden_disabled(technology) and all_prerequisites_researched(technology) then
      for _, recipe_name in ipairs(rule.recipes) do
        local recipe = force.recipes[recipe_name]
        if recipe and not recipe.enabled then
          recipe.enabled = true
          cobalt_changed[#cobalt_changed + 1] = recipe_name .. "@" .. rule.technology
        end
      end
    end
  end

  -- Chrome: only repair the known orphaned branch, and only recipes that still
  -- have no technology owner.  If upstream assigns an owner later, we leave it alone.
  if chrome_branch_is_orphaned(force) then
    for _, rule in ipairs(CHROME_RULES) do
      if all_named_technologies_researched(force, rule.required) then
        for _, recipe_name in ipairs(rule.recipes) do
          local recipe = force.recipes[recipe_name]
          if recipe and not recipe.enabled and not recipe_has_unlock_owner(force, recipe_name) then
            recipe.enabled = true
            chrome_changed[#chrome_changed + 1] = recipe_name
              .. "@" .. table.concat(rule.required, "+")
          end
        end
      end
    end
  end

  if #cobalt_changed > 0 then
    log(
      "[AB COBALT HOTFIX] force=" .. force.name
        .. " reason=" .. tostring(reason)
        .. " enabled=" .. table.concat(cobalt_changed, ",")
    )
  end

  if #chrome_changed > 0 then
    log(
      "[AB CHROME HOTFIX] force=" .. force.name
        .. " reason=" .. tostring(reason)
        .. " enabled=" .. table.concat(chrome_changed, ",")
    )
  end
end

local function refresh_all_forces(reason)
  for _, force in pairs(game.forces) do
    refresh_force(force, reason)
  end
end

script.on_init(function()
  refresh_all_forces("init")
end)

script.on_configuration_changed(function()
  refresh_all_forces("configuration-changed")
end)

script.on_event(defines.events.on_research_finished, function(event)
  if event and event.research and event.research.force then
    refresh_force(event.research.force, "research-finished:" .. event.research.name)
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  if player then
    refresh_force(player.force, "player-joined")
  end
end)

local function print_technology(player, technology_name)
  local force = player.force
  local technology = force.technologies[technology_name]

  if not technology then
    player.print(technology_name .. ": MISSING")
    return
  end

  player.print(
    technology_name
      .. " researched=" .. bool(technology.researched)
      .. " enabled=" .. bool(technology.enabled)
      .. " hidden=" .. bool(technology.prototype.hidden)
      .. " visible_when_disabled=" .. bool(technology.visible_when_disabled)
  )

  local prerequisites = {}
  for prerequisite_name, prerequisite in pairs(technology.prerequisites or {}) do
    prerequisites[#prerequisites + 1] = prerequisite_name .. "=" .. bool(prerequisite.researched)
  end
  table.sort(prerequisites)
  player.print("  prerequisites: " .. (#prerequisites > 0 and table.concat(prerequisites, ", ") or "none"))

  local found_unlock = false
  for _, effect in pairs(technology.prototype.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe then
      found_unlock = true
      local recipe = force.recipes[effect.recipe]
      player.print(
        "  -> " .. effect.recipe
          .. " exists=" .. bool(recipe ~= nil)
          .. " enabled=" .. bool(recipe and recipe.enabled)
      )
    end
  end

  if not found_unlock then
    player.print("  unlock recipes: none")
  end
end

local function print_family_status(player, family)
  local force = player.force
  local owners = {}
  local tech_names = {}
  local recipe_names = {}

  for technology_name, technology in pairs(force.technologies) do
    if string.find(technology_name, family, 1, true) then
      tech_names[#tech_names + 1] = technology_name
    end
    for _, effect in pairs(technology.prototype.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe then
        owners[effect.recipe] = owners[effect.recipe] or {}
        owners[effect.recipe][#owners[effect.recipe] + 1] = technology_name
      end
    end
  end

  for recipe_name, _ in pairs(force.recipes) do
    if string.find(recipe_name, family, 1, true) then
      recipe_names[#recipe_names + 1] = recipe_name
    end
  end

  table.sort(tech_names)
  table.sort(recipe_names)

  player.print("=== AngelBob " .. family .. " technology status ===")
  for _, technology_name in ipairs(tech_names) do
    print_technology(player, technology_name)
  end

  player.print("=== AngelBob " .. family .. " recipe ownership ===")
  for _, recipe_name in ipairs(recipe_names) do
    local recipe = force.recipes[recipe_name]
    local recipe_owners = owners[recipe_name] or {}
    table.sort(recipe_owners)

    local owner_status = {}
    for _, technology_name in ipairs(recipe_owners) do
      local technology = force.technologies[technology_name]
      owner_status[#owner_status + 1] = technology_name
        .. "[researched=" .. bool(technology and technology.researched)
        .. ",enabled=" .. bool(technology and technology.enabled)
        .. ",hidden=" .. bool(technology and technology.prototype.hidden)
        .. "]"
    end

    player.print(
      recipe_name
        .. " enabled=" .. bool(recipe and recipe.enabled)
        .. " owners=" .. (#owner_status > 0 and table.concat(owner_status, ";") or "none")
    )
  end
end

commands.add_command(
  "ab-cobalt-hotfix-status",
  "Show cobalt technologies, recipes, unlock owners, and current hotfix state.",
  function(command)
    local player = command.player_index and game.get_player(command.player_index)
    if player then
      print_family_status(player, "cobalt")
    end
  end
)

commands.add_command(
  "ab-chrome-chain-status",
  "Show Chrome technologies, recipes, unlock owners, and current hotfix state.",
  function(command)
    local player = command.player_index and game.get_player(command.player_index)
    if player then
      print_family_status(player, "chrome")
    end
  end
)
