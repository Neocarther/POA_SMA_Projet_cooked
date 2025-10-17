extends CharacterBody2D

@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var plated_meal_scene = preload("res://scenes/PlatedMeal.tscn")
var held_item: Node = null
var nearby_interactables = []

#------ Navigation Code for the Agent to move around the world -------#

func _ready() -> void:
	var agent: RID = navigation_agent.get_rid()
	# Enable avoidance
	NavigationServer2D.agent_set_avoidance_enabled(agent, true)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))

func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)

func _physics_process(_delta: float) -> void:
	set_movement_target(Vector2(0, 0))
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
 
#------ Environment interaction code ------#

func has_item() -> bool:
	return held_item != null

func add_item(item: Node) -> void:
	if has_item() and item_type() == "Plate":
		remove_item()
	elif has_item():
		return
	held_item = item
	add_child(item)
	item.position = Vector2.ZERO

func remove_item() -> Node:
	if not has_item():
		return null
	var removed_item = held_item
	if self.is_ancestor_of(held_item):
		remove_child(held_item)
		held_item = null
	return removed_item

func get_closest_interactable():
	var closest = null
	var closest_dist := INF
	for interactable in nearby_interactables:
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist
	return closest

func item_type() -> String:
	if held_item is Ingredient and held_item.data.name == "Plate":
		return "Plate"
	else:
		return held_item.get_class()

func ingredient_to_meal() -> void:
	if held_item is Ingredient:
		var ingredient = remove_item()
		held_item = plated_meal_scene.instantiate() as PlatedMeal
		held_item.ingredients.append(ingredient)
		add_child(held_item)

## Call to interact with an Interactable in range
func _try_interact():
	if not nearby_interactables.is_empty():
		get_closest_interactable().interact(self)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		nearby_interactables.append(area.get_parent())

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("interactables"):
		nearby_interactables.erase(parent)

#------ Agent Logic Code to manipulate the state machine and complete tasks ------#

var current_recipe

enum State {
	IDLE,
	GET_NEXT_INGREDIENT,
	FETCH_INGREDIENT,
	MOVING,
}

var state: State
var previous_state: State
var navigation_finished = false
var recipe: StringName

func _process(_delta: float) -> void:
	match state:
		State.IDLE:
			recipe = _WorldState.get_recipe()
			state = State.GET_NEXT_INGREDIENT
		State.FETCH_INGREDIENT:
			if (navigation_finished):
				var ingredient_and_state = _RecipeManager.get_next_ingredient(recipe,get_last_ingredient_string_name(held_item))
				var ingredient_name = ingredient_and_state.split("_")[0]
				
				var station = get_station(ingredient_and_state.split("_")[1])
				set_movement_target(_WorldState.get_closest_element(station, self))
				previous_state = state
				state = State.MOVING
		State.MOVING:
			if navigation_agent.is_navigation_finished():
				navigation_finished = true
				state = previous_state
			

func get_last_ingredient_string_name(element) -> StringName:
	var last_element
	if (element is Ingredient):
		last_element = element as Ingredient
	elif (element is PlatedMeal):
		last_element = element.ingredients[element.ingredients.size() - 1] as Ingredient
	else:
		return "error"
	match last_element.state:
		Ingredient.State.BASE:
			return StringName(last_element.data.name + "_base")
		Ingredient.State.CUT:
			return StringName(last_element.data.name + "_cut")
		Ingredient.State.COOKED:
			return StringName(last_element.data.name + "_cooked")
	return "error"

func get_station(ingredient_state: String):
	match ingredient_state:
		"base":
			return "ingredient_station"
		"cut":
			return "cutting_station"
		"cooked":
			return "cooking_station"
		_:
			return ""
