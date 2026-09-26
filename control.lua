-- AngelBob Space Age Cobalt Chain Hotfix
-- Factorio 2.0 branch
--
-- Keep this deliberately small: restore only the two cobalt sheet-coil recipes
-- whose sole unlock owners are hidden+disabled technologies.  The repair only
-- applies after every prerequisite of that inaccessible owner has been researched.

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
  return technology
    and technology.prototype
    and technology.prototype.hidden
    and not technology.enabled
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
  )

  local prerequisites = {}
  for prerequisite_name, prerequisite in pairs(technology.prerequisites or {}) do
    prerequisites[#prerequisites + 1] = prerequisite_name .. "=" .. bool(prerequisite.researched)
  end
  table.sort(prerequisites)
  player.print("  prerequisites: " .. (#prerequisites > 0 and table.concat(prerequisites, ", ") or "none"))

  for _, effect in pairs(technology.prototype.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe then
      local recipe = force.recipes[effect.recipe]
      player.print(
        "  -> " .. effect.recipe
          .. " exists=" .. bool(recipe ~= nil)
          .. " enabled=" .. bool(recipe and recipe.enabled)
      )
    end
  end
end

commands.add_command(
  "ab-cobalt-hotfix-status",
  "Show the two cobalt casting owners and their recipe state.",
  function(command)
    local player = command.player_index and game.get_player(command.player_index)
    if not player then
      return
    end

    player.print("=== AngelBob cobalt chain hotfix ===")
    print_technology(player, "angels-cobalt-casting-2")
    print_technology(player, "angels-cobalt-casting-3")
  end
)
