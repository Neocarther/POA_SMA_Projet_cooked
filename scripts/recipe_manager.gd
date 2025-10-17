extends Node
class_name RecipeManager

const recipes_folder_path = "res://resources/recipes/"

var sprites = {}
var recipes_list = {}
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	preload_textures()
	recipes_list = get_all_recipes(recipes_folder_path)

func preload_textures():
	sprites = {
	}

## Get all recipes from the recipe resource directory and puts their names 
## along with the list of their ingredients and the state of each ingredient 
## in a dictionary for comparisons with ingredients
##
## Combines the name of each ingredient from the recipe with the state it
## should be in for easier comparison with ingredients
func get_all_recipes(path: String) -> Dictionary:
	var recipe_list = {}
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			if file_name.ends_with(".tres"):
				var full_path = path + file_name
				var recipe = load(full_path)
				if recipe is RecipeData:
					var nb_ingredients = recipe.ingredients.size()
					recipe_list[recipe.name] = []
					for i in range(nb_ingredients):
						match recipe.states[i]:
							Ingredient.State.BASE:
								recipe_list[recipe.name].append(StringName(recipe.ingredients[i] + "_base"))
							Ingredient.State.CUT:
								recipe_list[recipe.name].append(StringName(recipe.ingredients[i] + "_cut"))
							Ingredient.State.COOKED:
								recipe_list[recipe.name].append(StringName(recipe.ingredients[i] + "_cooked"))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Recipes resources dir not found")
	return recipe_list

#func generate_combinations(recipes_list):
	#for recipe in recipes_list:
		#var ingredient_list = []
		#var nb_ingredients = recipe.ingredients.size()
		#for i in range(nb_ingredients):
			#match recipe.states[i]:
				#Ingredient.State.BASE:
					#ingredient_list.append(StringName(recipe.ingredients[i] + "_base"))
				#Ingredient.State.CUT:
					#ingredient_list.append(StringName(recipe.ingredients[i] + "_cut"))
				#Ingredient.State.COOKED:
					#ingredient_list.append(StringName(recipe.ingredients[i] + "_cooked"))
		#ingredient_list.sort()
		#combinations = _combinations_rec(ingredient_list, combinations)

#func _combinations_rec(ingredient_list, combinations):
	#for i in range(ingredient_list.size()):
		#if ingredient_list[i] not in combinations.keys():
			#combinations[ingredient_list[i]] = _combinations_rec(ingredient_list.slice(i+1), combinations[ingredient_list[i]])
	#return combinations

## Compares given combination of ingredients with the recipes available.
##
## Combination of ingredients do not need to form a whole recipe to be valid as long as 
## they all strictly match to at least one recipe.
##
## Order of the ingredients in the evaluated combination is important. It will not match 
## with a recipe if the order is not respected even if one recipe does contain all of them. 
## This is to avoid the case where you first add tomatoes, and then steak, and then cheese 
## in a burger which doesn't really make sense and reduces the number of sprites to produce.
func is_recipe_valid(ingredients: Array[StringName]) -> bool:
	for recipe in recipes_list.keys():
		var nb_ingredients = ingredients.size()
		var i = 0
		while i < nb_ingredients:
			var owned_ingredient = ingredients[i]
			var recipe_ingredient = recipes_list[recipe][i]
			if recipe_ingredient is StringName and owned_ingredient is StringName:
				if owned_ingredient == recipe_ingredient:
					i += 1
				else:
					break
			else:
				push_error("Error in the implementation of recipe and ingredients, both should be StringName")
		if i == nb_ingredients:
			return true
	return false

func get_sprite(ingredients: StringName) -> Sprite2D:
	for sprite in sprites.keys():
		if sprite == ingredients:
			return sprites[sprite]
	return null

func is_recipe_complete(ingredients: Array[StringName]) -> bool:
	for recipe in recipes_list.keys():
		var nb_ingredients = ingredients.size()
		if nb_ingredients != recipes_list[recipe].size():
			continue
		for i in range(nb_ingredients) :
			var owned_ingredient = ingredients[i]
			var recipe_ingredient = recipes_list[recipe][i]
			if recipe_ingredient is StringName and owned_ingredient is StringName:
				if owned_ingredient != recipe_ingredient:
					break
			else:
				push_error("Error in the implementation of recipe and ingredients, both should be StringName")
		return true
	return false

func get_random_recipe():
	var random_recipe_index = rng.randi_range(1, recipes_list.size())
	for ingredient in recipes_list.keys():
		random_recipe_index -= 1
		if random_recipe_index == 0:
			return ingredient

func get_next_ingredient(recipe: StringName, last_ingredient: StringName) -> StringName:
	var next_ingredient = false
	for ingredient in recipes_list[recipe]:
		if next_ingredient == true:
			return ingredient
		if ingredient == last_ingredient:
			next_ingredient = true
	if next_ingredient == true:
		return "recipe_complete"
	else:
		return "error"
