extends Node
class_name BlackBoard

var id: int ##Id of the Black Board
var recipe: StringName ##Name of the recipe being worked on in the blackboard
var timer: Timer ##Timer of the recipe
var current_nb_ingredients: int = 0 ##Number of ingredients gathered in a plated meal for the recipe
var required_nb_ingredients: int ##Number of ingredients required to complete the recipe
var plated_meal_location: Vector2 = Vector2(0, 0) ##Current Location of the plated meal in stations, if plated meal on the move, value is null
var last_ingredient_on_the_way: int = -1 ##Index of the last ingredient in the recipe being worked on by an agent

var agents_tasks: Dictionary[int, int] ##List of agents with the index of the ingredient they are working on
var nb_of_agents_on_task: int ##Number of agents working on the recipe at the same time

func _init(recipe_name: StringName, recipe_timer: Timer, agent_id: int, black_board_id: int) -> void:
	self.id = black_board_id
	self.recipe = recipe_name
	self.timer = recipe_timer
	self.required_nb_ingredients = _RecipeManager.get_recipe_size(recipe_name)
	self.agents_tasks[agent_id] = 0
	self.nb_of_agents_on_task = 1

func number_of_ingredients_left() -> int:
	return required_nb_ingredients - (last_ingredient_on_the_way + 1);

func get_time_left() -> float:
	return timer.time_left

func get_next_ingredient(agent_id: int) -> StringName:
	last_ingredient_on_the_way += 1
	if last_ingredient_on_the_way == required_nb_ingredients:
		return "recipe_complete"
	agents_tasks[agent_id] = last_ingredient_on_the_way
	return _RecipeManager.get_recipe_ingredient(recipe, last_ingredient_on_the_way)

func is_plated_meal_stored() -> bool:
	return plated_meal_location != Vector2(0, 0)

func is_next_required_ingredient(agent_id: int) -> bool:
	return agents_tasks[agent_id] == current_nb_ingredients
