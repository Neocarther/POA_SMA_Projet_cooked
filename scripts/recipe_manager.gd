extends Node
class_name RecipeManager

const recipes_folder_path = "res://resources/recipes/"

var textures = {}
var combinations = {}

func _ready() -> void:
	preload_textures()
	var recipes_list = get_all_recipes(recipes_folder_path)
	generate_combinations(recipes_list)

func preload_textures():
	textures = {
	}

func get_all_recipes(path: String) -> Array:
	var recipe_list = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		while file_name.is_empty():
			if file_name.ends_with(".tres"):
				var full_path = path + file_name
				var recipe = load(full_path)
				if recipe is RecipeData:
					recipe_list.append(recipe)
			file_name = dir.get_next()
		dir.list_dir_end()
	return recipe_list

func generate_combinations(recipes_list):
	for recipe in recipes_list:
		var ingredient_list = []
		var nb_ingredients = recipe.ingredients.size()
		for i in range(nb_ingredients):
			match recipe.states[i]:
				Ingredient.State.BASE:
					ingredient_list.append(StringName(recipe.ingredients[i] + "_base"))
				Ingredient.State.CUT:
					ingredient_list.append(StringName(recipe.ingredients[i] + "_cut"))
				Ingredient.State.COOKED:
					ingredient_list.append(StringName(recipe.ingredients[i] + "_cooked"))
		ingredient_list.sort()
		combinations = _combinations_rec(ingredient_list, combinations)

func _combinations_rec(ingredient_list, combinations):
	for i in range(ingredient_list.size()):
		if ingredient_list[i] not in combinations.keys():
			combinations[ingredient_list[i]] = _combinations_rec(ingredient_list.slice(i+1), combinations[ingredient_list[i]])
	return combinations

func get_texture(ingredients: Array[Ingredient]) -> Texture2D:
	for combination in combinations.keys():
		
