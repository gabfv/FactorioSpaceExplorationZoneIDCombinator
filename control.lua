local function on_init()
  global.combinators_by_surface = {}
end
script.on_init(on_init)

local entity_filter = {{filter = "name", name = "se-cme-combinator"}}

local function on_entity_created(event)
  local entity = event.created_entity or event.entity
  global.combinators_by_surface[entity.surface.name] = global.combinators_by_surface[entity.surface.name] or {}
  table.insert(global.combinators_by_surface[entity.surface.name], entity)
  log(serpent.line(global.combinators_by_surface))
end
script.on_event(defines.events.on_robot_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.on_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_built, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_revive, on_entity_created, entity_filter)


local function remove_from_table_by_unit_number(table_to_search, entity)
  for i, table_entity in pairs(table_to_search) do
    if table_entity.unit_number == entity.unit_number then
      table.remove(table_to_search, i)
      return
    end
  end
end

local function on_entity_removed(event)
  remove_from_table_by_unit_number(global.combinators_by_surface[event.entity.surface.name], event.entity)
  if #global.combinators_by_surface[event.entity.surface.name] == 0 then
    global.combinators_by_surface[event.entity.surface.name] = nil
  end
  log(serpent.line(global.combinators_by_surface))
end
script.on_event(defines.events.on_player_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed, entity_filter)
script.on_event(defines.events.on_entity_died, on_entity_removed, entity_filter)
script.on_event(defines.events.script_raised_destroy, on_entity_removed, entity_filter)
