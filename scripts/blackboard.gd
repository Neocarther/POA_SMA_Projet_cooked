extends Node

class_name BlackBoard

var id: int ##Id of the Black Board
var recipe: StringName ##Name of the recipe being worked on in the blackboard
var current_plated_meal: Array[StringName] ##List of ingredients currently in a plated meal for the recipe
var current_nb_ingredients: int = 0 ##Number of ingredients gathered in a plated meal for the recipe
var required_nb_ingredients: int ##Number of ingredients required to complete the recipe
var plated_meal_location: Vector2 ##Current Location of the plated meal in stations, if plated meal on the move, value is null
var last_ingredient_on_the_way: int = 0 ##Index of the last ingredient in the recipe being worked on by an agent

var agents_tasks: Dictionary[int, int] ##List of agents with the index of the ingredient they are working on
var nb_of_agents_on_task: int ##Number of agents working on the recipe at the same time

func _init(recipe_name: StringName, agent_id: int, black_board_id: int) -> void:
	self.id = black_board_id
	self.recipe = recipe_name
	self.required_nb_ingredients = _RecipeManager.get_recipe_size(recipe_name)
	self.agents_tasks[agent_id] = 0
	self.nb_of_agents_on_task = 1
