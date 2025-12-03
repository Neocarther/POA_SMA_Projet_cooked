extends Node
class_name RecipeManager

const recipes_folder_path = "res://resources/recipes/"

var sprites: Dictionary[StringName, Resource]
var recipes_list: Dictionary[StringName, Array]
var recipes_points: Dictionary[StringName, int]
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 66
	preload_sprites()
	recipes_list = get_all_recipes(recipes_folder_path)

func preload_sprites():
	sprites = {
		"plate_basesteak_cooked" = preload("uid://dwg1ccikmatit"),
		"plate_basetomato_cut" = preload("uid://buubwye4vojn8"),
		"plate_basecheese_base" = preload("uid://dpp6jx5850os2"),
		"plate_basecheese_basetomato_cut" = preload("uid://blybn3myciffp"),
		"plate_basesteak_cookedtomato_cut" = preload("uid://dkohphcp0j8xs"),
		"plate_basesteak_cookedcheese_base" = preload("uid://bum8kv6urja5v"),
		"plate_basesteak_cookedcheese_basetomato_cut" = preload("uid://dfykn0mhxl4a"),
		"plate_basebread_base" = preload("uid://drhw3mno0kfwb"),
		"plate_basebread_basesteak_cooked" = preload("uid://0syniwtvh1gq"),
		"plate_basebread_basesteak_cookedtomato_cut" = preload("uid://ccgcga2xeodwe"),
		"plate_basebread_basesteak_cookedcheese_base" = preload("uid://bswtbwmahlhep"),
		"plate_basebread_basesteak_cookedcheese_basetomato_cut" = preload("uid://40jly3umkhte"),
		"plate_basebread_basesteak_cookedtomato_cutcheese_base" = preload("uid://40jly3umkhte"),
		"plate_basebread_basetomato_cut" = preload("uid://mhf63t15vhhr"),
		"plate_basebread_basecheese_base" = preload("uid://ls65cu1mx105"),
		"plate_basebread_basecheese_basetomato_cut" = preload("uid://b6nng7drbb0l7")
	}

## Get all recipes from the recipe resource directory and puts their names 
## along with the list of their ingredients and the state of each ingredient 
## in a dictionary for comparisons with ingredients
##
## Combines the name of each ingredient from the recipe with the state it
## should be in for easier comparison with ingredients
func get_all_recipes(path: String) -> Dictionary[StringName, Array]:
	var recipe_list: Dictionary[StringName, Array]
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
					recipes_points[recipe.name] = recipe.points
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Recipes resources dir not found")
	return recipe_list

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

func get_sprite(ingredients: StringName) -> Texture2D:
	for sprite in sprites.keys():
		if sprite == ingredients:
			return sprites[sprite]
	return preload("uid://taybuu0hp4oh")

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

## Returns the name of a random Recipe among the list of recipes available
func get_random_recipe() -> StringName:
	return recipes_list.keys()[rng.randi_range(0, recipes_list.size() - 1)]

## Returns the next ingredient to fetch for a specific recipe given the last ingredient 
## currently in possession
##
## If there is no next ingredient, meaning the recipe is already complete, returns "recipe_complete" instead
func get_next_ingredient(recipe: StringName, last_ingredient: StringName) -> StringName:
	if last_ingredient == "":
		return recipes_list[recipe][0]
	var next_ingredient = false
	for ingredient in recipes_list[recipe]:
		if next_ingredient:
			return ingredient
		if ingredient == last_ingredient:
			next_ingredient = true
	if next_ingredient:
		return "recipe_complete"
	else:
		return "error"

func get_recipe_ingredient(recipe: StringName, ingredient_number: int) -> StringName:
	return recipes_list[recipe][ingredient_number]

func get_recipe_size(recipe: StringName) -> int:
	return recipes_list[recipe].size()

func get_recipe_points(recipe: StringName) -> int:
	return recipes_points[recipe]
