local ENTITY_NAME = "se-zone-id-combinator"
-- Set a green tint color
local TINT_COLOR = {r = 0.25, g = 1, b = 0.25}

local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = ENTITY_NAME
item.place_result = ENTITY_NAME
item.icons = {
  {
    icon = item.icon,
    tint = TINT_COLOR
  }
}

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = ENTITY_NAME
entity.minable.result = ENTITY_NAME
entity.item_slot_count = 1
entity.icons = {
  {
    icon = entity.icon,
    tint = TINT_COLOR
  }
}
for _, direction in pairs({"north", "east", "south", "west"}) do
  for index, layer in pairs(entity.sprites[direction].layers) do
    entity.sprites[direction].layers[index].tint = TINT_COLOR
    entity.sprites[direction].layers[index].hr_version.tint = TINT_COLOR
  end
end
-- table.insert(entity.flags, "hide-alt-info") -- No point in showing always the same icons

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.name = ENTITY_NAME
recipe.result = ENTITY_NAME
recipe.ingredients = {
  {"copper-cable", 100},
  {"electronic-circuit", 100}
}

table.insert(data.raw.technology["circuit-network"].effects,
  {type = "unlock-recipe", recipe = ENTITY_NAME}
)

data:extend{item, entity, recipe}
