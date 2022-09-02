local util = require("__core__/lualib/util.lua")

local s_signal = {type = "virtual", name = "signal-S"}
local w_signal = {type = "virtual", name = "signal-W"}
local function set_combinator_values(entity, seconds_value, megawatts_value)
  local control_behavior = entity.get_control_behavior()
  control_behavior.set_signal(1, {signal = s_signal, count = seconds_value})
  control_behavior.set_signal(2, {signal = w_signal, count = megawatts_value})
end

local function unset_combinator_values(entity)
  local control_behavior = entity.get_control_behavior()
  control_behavior.set_signal(1, nil)
  control_behavior.set_signal(2, nil)
end

local function process_surface(surface_name)
  for _, combinator in pairs(global.combinators_by_surface[surface_name]) do
    set_combinator_values(combinator, 69, 420)
  end
end

local function on_tick_less_than_60_surfaces(event)
  local surface_name = global.surface_list[event.tick % 60] -- surface #1 processed on tick 1, surface #2 on tick 2, etc.
  if surface_name then
    process_surface(surface_name)
  end
end

local function on_tick_more_than_60_surfaces(event)

end

local function on_init()
  global.combinators_by_surface = {}
  global.surface_list = {} -- Used to split work by surface, surface #1 processed on tick 1, surface #2 on tick 2, etc.
  script.on_event(defines.events.on_tick, on_tick_less_than_60_surfaces)
end
script.on_init(on_init)

local function on_load()
  if #global.surface_list < 60 then
    script.on_event(defines.events.on_tick, on_tick_less_than_60_surfaces)
  else
    script.on_event(defines.events.on_tick, on_tick_more_than_60_surfaces)
  end
end
script.on_load(on_load)

local entity_filter = {{filter = "name", name = "se-cme-combinator"}}

local function add_new_surface(surface_name)
  global.combinators_by_surface[surface_name] = {}
  table.insert(global.surface_list, surface_name)
  if #global.surface_list == 61 then
    log("Switched to on_tick_more_than_60_surfaces")
    script.on_event(defines.events.on_tick, on_tick_more_than_60_surfaces)
  end
end

local function remove_surface(surface_name)
  global.combinators_by_surface[surface_name] = nil
  util.remove_from_list(global.surface_list, surface_name)
  if #global.surface_list == 60 then
    log("Switched back to on_tick_less_than_60_surfaces")
    script.on_event(defines.events.on_tick, on_tick_less_than_60_surfaces)
  end
end

local function on_entity_created(event)
  local entity = event.created_entity or event.entity
  if not global.combinators_by_surface[entity.surface.name] then
    add_new_surface(entity.surface.name)
  end
  table.insert(global.combinators_by_surface[entity.surface.name], entity)
  log(serpent.line(global.combinators_by_surface))
end
script.on_event(defines.events.on_robot_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.on_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_built, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_revive, on_entity_created, entity_filter)


local function remove_from_list_by_unit_number(table_to_search, entity)
  for i, table_entity in pairs(table_to_search) do
    if table_entity.unit_number == entity.unit_number then
      table.remove(table_to_search, i)
      return
    end
  end
end

local function on_entity_removed(event)
  remove_from_list_by_unit_number(global.combinators_by_surface[event.entity.surface.name], event.entity)
  if #global.combinators_by_surface[event.entity.surface.name] == 0 then
    remove_surface(event.entity.surface.name)
  end
  log(serpent.line(global.combinators_by_surface))
end
script.on_event(defines.events.on_player_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_entity_died, on_entity_removed, entity_filter)
script.on_event(defines.events.script_raised_destroy, on_entity_removed, entity_filter)
