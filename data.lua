local ENTITY_NAME = "se-cme-combinator"

local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = ENTITY_NAME
item.place_result = ENTITY_NAME
item.icon = "__se-cme-combinator__/graphics/icon.png"

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = ENTITY_NAME
entity.minable.result = ENTITY_NAME
entity.icon = "__se-cme-combinator__/graphics/icon.png"
for _, sprite_direction in pairs(entity.sprites) do
  sprite_direction.layers[1].filename = "__se-cme-combinator__/graphics/entity.png"
  sprite_direction.layers[1].hr_version.filename = "__se-cme-combinator__/graphics/hr-entity.png"
end

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.name = ENTITY_NAME
recipe.result = ENTITY_NAME
recipe.ingredients = {
  {"copper-cable", 50},
  {"processing-unit", 10}
}

table.insert(data.raw.technology["se-energy-beam-defence"].effects,
  {type = "unlock-recipe", recipe = ENTITY_NAME}
)

data:extend{item, entity, recipe}
