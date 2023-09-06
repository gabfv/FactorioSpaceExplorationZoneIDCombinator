-- define a function that will set the current zone id on the combinator when it is placed
local function set_zone_id(zone_id, zone_signal, entity)
  local control_behavior = entity.get_control_behavior()
  control_behavior.set_signal(1, {signal = zone_signal, count = zone_id})
end

-- get current surface info
local function get_surface_info(entity_created)
  local surface_index = entity_created.surface.index

  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface_index})

  local zone_id = nil
  local zone_signal = nil
  
  if zone then
    zone_id = zone.index
    if zone.type == "orbit" then --need to check for the parent of the orbit
      local parent_orbit = remote.call("space-exploration", "get_zone_from_zone_index", {zone_index = zone.parent_index})
      if parent_orbit then
        if parent_orbit.type == "star" then --special case for stars, since even though they're in orbit, the virtual signal name is just "star"
          zone_signal = {type = "virtual", name = "se-" .. parent_orbit.type}
        else -- any orbits
          zone_signal = {type = "virtual", name = "se-" .. parent_orbit.type .. "-" .. zone.type}
        end
      end
    else -- everything else
      zone_signal = {type = "virtual", name = "se-" .. zone.type}
    end
  else
    entity_created.surface.create_entity{name = "flying-text", position = entity_created.position, text = "No zone found"}
  end
  return zone_id, zone_signal
end

-- On creation
local function on_entity_created(event)
  local entity = event.created_entity or event.entity
  entity.operable = false
  
  local zone_id, zone_signal = get_surface_info(entity)
  if zone_id then
    set_zone_id(zone_id, zone_signal, entity)
  end
end
local entity_filter = {{filter = "name", name = "se-zone-id-combinator"}}
script.on_event(defines.events.on_robot_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.on_built_entity, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_built, on_entity_created, entity_filter)
script.on_event(defines.events.script_raised_revive, on_entity_created, entity_filter)