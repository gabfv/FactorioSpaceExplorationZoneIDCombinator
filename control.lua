local CME_INFO_CACHE_REFRESH_RATE = 60*60*1 -- 1 minute
local CME_DURATION = 60*60*2-- 2 minutes
local NEGATIVE_SECONDS_BEFORE_REFRESH = -CME_DURATION/60 +1
local util = require("__core__/lualib/util.lua")


local function refresh_cme_info()
  -- SE deletes the CME from the list as soon as it starts.
  -- Block refreshes while a CME is ongoing to keep combinators on during a CME.
  if not global.ongoing_cme then
    global.cme_info = remote.call("space-exploration", "get_solar_flares")
  end
end
script.on_nth_tick(CME_INFO_CACHE_REFRESH_RATE, refresh_cme_info)

local s_signal = {type = "virtual", name = "signal-S"}
local w_signal = {type = "virtual", name = "signal-W"}
local j_signal = {type = "virtual", name = "signal-J"}
local function set_combinator_values(entity, values)
  local control_behavior = entity.get_control_behavior()
  control_behavior.set_signal(1, {signal = s_signal, count = values[1]})
  control_behavior.set_signal(2, {signal = w_signal, count = values[2]})
  control_behavior.set_signal(3, {signal = j_signal, count = values[3]})
end

local function unset_combinator_values(entity)
  local control_behavior = entity.get_control_behavior()
  control_behavior.set_signal(1, nil)
  control_behavior.set_signal(2, nil)
  control_behavior.set_signal(3, nil)
end

local function update_combinators_on_surface(surface_name, current_tick)
  local surface_cme_info = global.cme_info[surface_name]
  if surface_cme_info then
    surface_cme_info = surface_cme_info[1] -- Let's just assume there's only 1 CME per surface for performance

    local seconds = (surface_cme_info.tick - current_tick) / 60
    if NEGATIVE_SECONDS_BEFORE_REFRESH < seconds and seconds <= 1 then
      global.ongoing_cme = true -- ongoing CME
    elseif seconds <= NEGATIVE_SECONDS_BEFORE_REFRESH then
      global.ongoing_cme = false -- CME has passed
      refresh_cme_info()
    end

    local values = {
      seconds, -- S: seconds
      surface_cme_info.peak_power / 1000000, -- W: MegaWatts
      surface_cme_info.energy / 1000000, -- J: MegaJoules
    }
    for _, combinator in pairs(global.combinators_by_surface[surface_name]) do
      -- set_combinator_values(combinator, values)
      set_combinator_values(combinator, values)
    end
  else
    for _, combinator in pairs(global.combinators_by_surface[surface_name]) do
      unset_combinator_values(combinator)
    end
  end
end

local function on_tick_less_than_60_surfaces(event)
  local surface_name = global.surface_list[event.tick % 60] -- surface #1 processed on tick 1, surface #2 on tick 2, etc.
  if surface_name then
    update_combinators_on_surface(surface_name, event.tick)
  end
end

local function on_tick_more_than_60_surfaces(event)
  for i = event.tick % 60, #global.surface_list, 60 do
    update_combinators_on_surface(global.surface_list[i], event.tick)
  end
end

local function on_init()
  global.combinators_by_surface = {}
  global.surface_list = {} -- Used to split work by surface, surface #1 processed on tick 1, surface #2 on tick 2, etc.
  global.ongoing_cme = false
  refresh_cme_info()
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
  entity.operable = false
  local surface_name = entity.surface.name
  if surface_name == "nauvis" then surface_name = "Nauvis" end
  if not global.combinators_by_surface[surface_name] then
    add_new_surface(surface_name)
  end
  table.insert(global.combinators_by_surface[surface_name], entity)
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
  local surface_name = event.entity.surface.name
  if surface_name == "nauvis" then surface_name = "Nauvis" end
  remove_from_list_by_unit_number(global.combinators_by_surface[surface_name], event.entity)
  if #global.combinators_by_surface[surface_name] == 0 then
    remove_surface(surface_name)
  end
  log(serpent.line(global.combinators_by_surface))
end
script.on_event(defines.events.on_player_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_entity_died, on_entity_removed, entity_filter)
script.on_event(defines.events.script_raised_destroy, on_entity_removed, entity_filter)
