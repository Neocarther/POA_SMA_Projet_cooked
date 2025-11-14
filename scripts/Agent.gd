extends CharacterBody2D

@export var movement_speed: float = 500.0
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
	print("Moving to : ", movement_target)
	navigation_agent.set_target_position(movement_target)

func _physics_process(_delta: float) -> void:
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
	if area.get_parent().is_in_group("interactable"):
		nearby_interactables.append(area.get_parent())

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("interactable"):
		nearby_interactables.erase(parent)

#------ Agent Logic Code to manipulate the state machine and complete tasks ------#

enum State {
	IDLE,
	INTERACTING,
	MOVING,
	CUTTING,
}

signal order_completed(recipe)

var state: State
var recipe: StringName
var next_ingredient_and_state: StringName
var required_ingredient_name: String
var required_ingredient_state: String
var ready_to_serve = false
var previous_item: String
var interaction_interval: float = 0.0

func _process(_delta: float) -> void:
	interaction_interval += _delta
	if interaction_interval <= 0.5:
		return
	else:
		interaction_interval = 0.0
	print(state)
	match state:
		State.IDLE:
			recipe = _WorldState.get_recipe()
			_get_next_Ingredient()
		
		State.MOVING:
			if navigation_agent.is_navigation_finished():
				state = State.INTERACTING
		
		State.INTERACTING:
			var previous_ingredient_state: Ingredient.State = held_item.state if held_item is Ingredient else Ingredient.State.BASE
			_try_interact()
			if previous_ingredient_state == Ingredient.State.CUT and required_ingredient_state == "cooked":
				_get_previous_item()
			elif held_item == null and previous_item != "":
				_fetch_ingredient()
			elif held_item is Ingredient and held_item.get_item_name() == next_ingredient_and_state and previous_item != "":
				_combine_items()
			elif get_last_ingredient_string_name(held_item) == next_ingredient_and_state:
				_get_next_Ingredient()
			elif held_item is Ingredient:
				if held_item.data.name == required_ingredient_name:
					_get_next_station()
			elif held_item is PlatedMeal or held_item != null and held_item.get_item_name() != next_ingredient_and_state:
				_fetch_required_ingredient()
			elif held_item == null and ready_to_serve == true:
				order_completed.emit(recipe)
				ready_to_serve = false
				state = State.IDLE
		
		State.CUTTING:
			_try_interact()
			if held_item != null:
				if held_item.get_item_name() == next_ingredient_and_state:
					if previous_item != "":
						_combine_items()
					else:
						_get_next_Ingredient()

func _get_next_Ingredient() -> void:
	next_ingredient_and_state = _RecipeManager.get_next_ingredient(recipe, get_last_ingredient_string_name(held_item))
	print(next_ingredient_and_state)
	if next_ingredient_and_state == "":
		state = State.IDLE  # No more ingredients, go back to idle state
		return
	elif next_ingredient_and_state == "recipe_complete":
		ready_to_serve = true
		set_movement_target(_WorldState.get_closest_element("serving_station", self))
		state = State.MOVING
		return
	
	required_ingredient_name = next_ingredient_and_state.split("_")[0]
	required_ingredient_state = next_ingredient_and_state.split("_")[1]
	if held_item == null and required_ingredient_state == "base":
		_fetch_ingredient()
		print("fetching...")
	else:
		previous_item = held_item.get_item_name()
		set_movement_target(_WorldState.get_closest_element("counter_station", self))
		state = State.MOVING

func _fetch_ingredient() -> void:
	set_movement_target(_WorldState.get_closest_element("ingredient_station", self, required_ingredient_name + "_base"))
	state = State.MOVING

func _combine_items() -> void:
	previous_item = ""
	set_movement_target(_WorldState.get_closest_element("interactable", self, previous_item))
	state = State.MOVING

func _get_next_station() -> void:
	var group: String
	if held_item is Ingredient:
		match held_item.state:
			Ingredient.State.BASE:
				group = "cutting_station"
			Ingredient.State.CUT:
				group = "cooking_station"
		set_movement_target(_WorldState.get_closest_element(group, self))
		state = State.MOVING

func _get_previous_item() -> void:
	if previous_item != "":
		set_movement_target(_WorldState.get_closest_element("interactable", self, previous_item))
		state = State.MOVING

func _fetch_required_ingredient() -> void:
	set_movement_target(_WorldState.get_closest_element("cooking_station", self, next_ingredient_and_state))
	state = State.MOVING

func get_last_ingredient_string_name(element) -> StringName:
	var last_element
	if (element is Ingredient):
		last_element = element as Ingredient
	elif (element is PlatedMeal):
		last_element = element.ingredients[element.ingredients.size() - 1] as Ingredient
	else:
		return ""
	return StringName(last_element.get_item_name())
