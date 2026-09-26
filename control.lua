-- AngelBob Space Age Cobalt Chain Hotfix
-- Factorio 2.0 branch
--
-- This is intentionally a runtime-only compatibility shim. It does not unhide,
-- enable, or rewrite upstream technologies. It only restores a cobalt recipe
-- when the technology that owns the recipe is itself hidden+disabled and every
-- prerequisite of that technology has already been researched.
--
-- The hidden+disabled guard is important: if the upstream mod later restores
-- the casting technology normally, this hotfix becomes a no-op instead of
-- bypassing the newly reachable research.

local RULES = {
  {
    technology = "angels-cobalt-casting-2",
    recipes = { "angels-roll-cobalt" },
  },
  {
    technology = "angels-cobalt-casting-3",
    recipes = { "angels-roll-cobalt-2" },
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

local function is_orphan_owner(technology)
  if not technology or not technology.prototype then
    return false
  end

  return technology.prototype.hidden and not technology.enabled
end

local function refresh_force(force, reason)
  if not force then
    return
  end

  local changed = {}

  for _, rule in ipairs(RULES) do
    local technology = force.technologies[rule.technology]

    if is_orphan_owner(technology) and all_prerequisites_researched(technology) then
      for _, recipe_name in ipairs(rule.recipes) do
        local recipe = force.recipes[recipe_name]
        if recipe and not recipe.enabled then
          recipe.enabled = true
          changed[#changed + 1] = recipe_name .. "@" .. rule.technology
        end
      end
    end
  end

  if #changed > 0 then
    log(
      "[AB COBALT HOTFIX] force=" .. force.name
        .. " reason=" .. tostring(reason)
        .. " enabled=" .. table.concat(changed, ",")
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
    prerequisites[#prerequisites + 1] =
      prerequisite_name .. "=" .. bool(prerequisite.researched)
  end
  table.sort(prerequisites)

  player.print(
    "  prerequisites: "
      .. (#prerequisites > 0 and table.concat(prerequisites, ", ") or "none")
  )

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
  if #tech_names == 0 then
    player.print("No technology names containing '" .. family .. "' found.")
  else
    for _, technology_name in ipairs(tech_names) do
      print_technology(player, technology_name)
    end
  end

  player.print("=== AngelBob " .. family .. " recipe ownership ===")
  if #recipe_names == 0 then
    player.print("No recipe names containing '" .. family .. "' found.")
  else
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
  "Diagnostic only: show Chrome technologies, recipes and unlock owners. Does not modify Chrome.",
  function(command)
    local player = command.player_index and game.get_player(command.player_index)
    if player then
      print_family_status(player, "chrome")
    end
  end
)
