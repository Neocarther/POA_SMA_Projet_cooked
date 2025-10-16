extends Node2D

@onready var meal: Sprite2D = $Plate/Meal
var ingredients: Array[Ingredient]

func _ready() -> void:
	_update_sprite()

func can_add(ingredient: Ingredient) -> bool:
	var ingredient_string_names: Array[StringName] = []
	if not ingredients.is_empty():
		for meal_ingredient in ingredients:
			ingredient_string_names.append(StringName(_combine_name_and_state(meal_ingredient)))
	ingredient_string_names.append(StringName(_combine_name_and_state(ingredient)))
	return _RecipeManager.is_recipe_valid(ingredient_string_names)

## Adds an ingredient to the ingredients list of the meal
##
## /!\ Must always be called after can_add(Ingredient) /!\
func add_ingredient(ingredient: Ingredient) -> void:
	ingredients.append(ingredient)
	_update_sprite()

## Changes the Sprite of the meal on the plate, does not change the plate
func _update_sprite() -> void:
	var s := PackedStringArray()
	if not ingredients.is_empty():
		for ingredient in ingredients:
			s.append(_combine_name_and_state(ingredient))
	var ingredients_string_name = StringName("".join(s))
	meal = _RecipeManager.get_sprite(ingredients_string_name)

## Combine the name of an ingredient with the state it is currently in 
## for comparisons with ingredients in recipes
func _combine_name_and_state(ingredient: Ingredient) -> String:
	match ingredient.state:
		Ingredient.State.BASE:
			return ingredient.data.name + "_base"
		Ingredient.State.CUT:
			return ingredient.data.name + "_cut"
		Ingredient.State.COOKED:
			return ingredient.data.name + "_cooked"
	return ""
