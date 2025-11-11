extends Node2D
class_name PlatedMeal

@onready var meal: Sprite2D = $Plate/Meal
var _ingredients: Array[Ingredient]

func _ready() -> void:
	_update_name()
	_update_sprite()

func can_add(ingredient: Ingredient) -> bool:
	var ingredient_string_names: Array[StringName] = []
	if not _ingredients.is_empty():
		for meal_ingredient in _ingredients:
			ingredient_string_names.append(StringName(meal_ingredient.get_name_state()))
	ingredient_string_names.append(StringName(ingredient.get_name_state()))
	return _RecipeManager.is_recipe_valid(ingredient_string_names)

## Adds an ingredient to the ingredients list of the meal
##
## /!\ Must always be called after can_add(Ingredient) /!\
func add_ingredient(ingredient: Ingredient) -> void:
	_ingredients.append(ingredient)
	_update_name()
	_update_sprite()

func is_complete() -> bool:
	var ingredient_string_names: Array[StringName] = []
	if not _ingredients.is_empty():
		for meal_ingredient in _ingredients:
			ingredient_string_names.append(StringName(meal_ingredient.get_name_state()))
	return _RecipeManager.is_recipe_complete(ingredient_string_names)

func get_name_state() -> String:
	return self.name

## Changes the Sprite of the meal on the plate, does not change the plate
func _update_sprite() -> void:
	var ingredients_string_name = StringName(self.name)
	meal = _RecipeManager.get_sprite(ingredients_string_name)

## Combine the name of each ingredient of the meal with the state it is currently in
## and updates the name of the meal for easy comparisons
func _update_name() -> String:
	var s := PackedStringArray()
	for ingredient in _ingredients:
		s.append(ingredient.get_name_state())
	return "".join(s)
