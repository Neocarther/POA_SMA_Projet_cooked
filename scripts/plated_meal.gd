extends Item
class_name PlatedMeal

@onready var meal: Sprite2D = $Meal
var ingredients: Array[Ingredient]

func _ready() -> void:
	_update_sprite()

func can_add(ingredient: Variant) -> bool:
	if not ingredient is Ingredient:
		return false
	var ingredient_string_names: Array[StringName] = ["plate_base"]
	if not ingredients.is_empty():
		for meal_ingredient in ingredients:
			ingredient_string_names.append(StringName(meal_ingredient.get_item_name()))
	ingredient_string_names.append(StringName(ingredient.get_item_name()))
	return _RecipeManager.is_recipe_valid(ingredient_string_names)

## Adds an ingredient to the ingredients list of the meal
##
## /!\ Must always be called after can_add(Ingredient) /!\
func add_ingredient(ingredient: Ingredient) -> void:
	ingredients.append(ingredient)
	_update_sprite()

func is_complete() -> bool:
	var ingredient_string_names: Array[StringName] = ["plate_base"]
	if not ingredients.is_empty():
		for meal_ingredient in ingredients:
			ingredient_string_names.append(StringName(meal_ingredient.get_item_name()))
	return _RecipeManager.is_recipe_complete(ingredient_string_names)

## Changes the Sprite of the meal on the plate, does not change the plate
func _update_sprite() -> void:
	var ingredients_string_name = StringName(self.get_item_name())
	meal.texture = _RecipeManager.get_sprite(ingredients_string_name)

## Combine the name of each ingredient of the meal with the state it is currently in
## and updates the name of the meal for easy comparisons
func get_item_name() -> String:
	var s := PackedStringArray()
	s.append("plate_base")
	for ingredient in ingredients:
		s.append(ingredient.get_item_name())
	return "".join(s)

func get_class_name():
	return "PlatedMeal"
