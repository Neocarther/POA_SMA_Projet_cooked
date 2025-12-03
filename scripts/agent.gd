extends CharacterBody2D
class_name Agent

@export var id: int ##Id of the Agent
@export var movement_speed: float = 300.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var plated_meal_scene = preload("res://scenes/PlatedMeal.tscn")

var held_item: Item = null ##Current item held by the agent
var nearby_interactables: Array[Node] = [] ##Array of interactable elements in range of the Agent

#------ Navigation Code for the Agent to move around the world -------#

func get_agent_id() -> int:
	return self.id

func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)

func _ready() -> void:
	var agent: RID = navigation_agent.get_rid()
	# Enable avoidance
	NavigationServer2D.agent_set_avoidance_enabled(agent, true)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))

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

## Returns the closest interactable node from the list of interactable nodes in range of the agent
## If no interactable node is in range, returns null
func get_closest_interactable() -> Node:
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
		return held_item.get_class_name()

func ingredient_to_meal() -> void:
	if held_item is Ingredient:
		var ingredient = remove_item()
		held_item = plated_meal_scene.instantiate() as PlatedMeal
		held_item.ingredients.append(ingredient)
		add_child(held_item)

## Call to interact with an Interactable in range
func _try_interact() -> void:
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
}

signal order_completed(blackboard)

var state: State ##State of the Agent, can be IDLE, INTERACTING or MOVING
var required_ingredient: StringName ##Name and state of the ingredient required for the next step of the recipe
var required_ingredient_name: String ##Name of the ingredient required for the next step of the recipe
var required_ingredient_state: String ##State of the ingredient required for the next step of the recipe
var interaction_interval: float = 0.0  ##Used to set the minimum interval between 2 interactions in seconds
var current_blackboard: BlackBoard
var need_fetch: bool = false
var is_dressing_plate: bool = false
var store_plated_meal: bool = false
var is_storing_item: bool = false
var serving_possible: bool = false
var ingredient_stored: bool = false
var item_cooking: bool = false

@onready var label: Label = $Label

func debugLabel():
	label.text = "State: " 
	label.text += "IDLE" if state == 0 else "MOVING" if state == 2 else "INTERACTING"
	label.text += "\n"
	label.text += "need_fetch true" if need_fetch else "need_fetch false"
	label.text += "\n"
	label.text += "is_dressing_plate true" if is_dressing_plate else "is_dressing_plate false"
	label.text += "\n"
	label.text += "store_plated_meal true" if store_plated_meal else "store_plated_meal false"
	label.text += "\n"
	label.text += "is_storing_item true" if is_storing_item else "is_storing_item false"
	label.text += "\n"
	label.text += "serving_possible true" if serving_possible else "serving_possible false"
	label.text += "\n"
	label.text += "ingredient_stored true" if ingredient_stored else "ingredient_stored false"
	label.text += "\n"
	label.text += "item_cooking true" if item_cooking else "item_cooking false"

func _process(_delta: float) -> void:
	interaction_interval += _delta
	if interaction_interval <= 0.3:
		return
	else:
		interaction_interval = 0.0
	match state:
		State.IDLE:
			required_ingredient = "none"
			required_ingredient_name = "none"
			required_ingredient_state = "none"
			if current_blackboard != null:
				current_blackboard.agents_tasks.erase(self.id)
				if current_blackboard.nb_of_agents_on_task < 2:
					_get_next_step()
					return
				else:
					current_blackboard.agents_tasks.erase(self.id)
					current_blackboard.nb_of_agents_on_task -= 1
					current_blackboard = null
			
			var task = _WorldState.get_recipe()
			if task is BlackBoard:
				current_blackboard = task
			else:
				return
			_get_next_step()
		
		State.MOVING:
			if navigation_agent.is_navigation_finished():
				state = State.INTERACTING
		
		State.INTERACTING:
			_try_interact()
			if get_last_ingredient_string_name(held_item) == required_ingredient and current_blackboard.is_next_required_ingredient(self.id):
				if current_blackboard.is_plated_meal_stored() and current_blackboard.plated_meal_available():
					if is_storing_item:
						is_storing_item = false
						ingredient_stored = false
					_combine_to_plated_meal()
				else:
					if held_item is PlatedMeal:
						current_blackboard.current_nb_ingredients = 1
					_store_item()
			elif get_last_ingredient_string_name(held_item) == required_ingredient:
				_store_item()
			elif held_item is Ingredient and held_item.data.name == required_ingredient_name and held_item.get_state() != required_ingredient_state :
				_get_next_station()
			elif held_item is PlatedMeal:
				if held_item.ingredients.size() == current_blackboard.current_nb_ingredients:
					current_blackboard.current_nb_ingredients += 1
					current_blackboard.stored_ingredients.pop_front()
				_combine_from_plated_meal()
			elif need_fetch:
				_fetch_ingredient()
			elif is_storing_item:
				is_storing_item = false
				store_plated_meal = false
				if ingredient_stored:
					ingredient_stored = false
					current_blackboard.update_stored(self.id)
				state = State.IDLE
			elif store_plated_meal:
				store_plated_meal = false
				is_storing_item = false
				current_blackboard.unlock_plated_meal()
				state = State.IDLE
			elif is_dressing_plate == true:
				is_dressing_plate = false
				current_blackboard.unlock_plated_meal()
				current_blackboard.current_nb_ingredients += 1
				state = State.IDLE
			elif item_cooking:
				current_blackboard.update_stored(self.id)
				item_cooking = false
				state = State.IDLE
			elif serving_possible:
				serving_possible = false
				order_completed.emit(current_blackboard)

				_WorldState.remove_blackboard(current_blackboard)
				current_blackboard = null
				state = State.IDLE

func _get_next_step() -> void:
	if (current_blackboard.stored_ingredients.has(current_blackboard.current_nb_ingredients) and current_blackboard.plated_meal_available()):
		if next_stored_ingredient_not_cooking():
			set_movement_target(current_blackboard.plated_meal_location)
			state = State.MOVING
			return
		else:
			current_blackboard.unlock_plated_meal()
	
	required_ingredient = current_blackboard.get_next_ingredient(self.id)
	
	if required_ingredient == "recipe_complete":
		if next_stored_ingredient_not_cooking() and current_blackboard.plated_meal_available():
			set_movement_target(current_blackboard.plated_meal_location)
			state = State.MOVING
		else:
			state = State.IDLE
		return
		
	required_ingredient_name = required_ingredient.split("_")[0]
	required_ingredient_state = required_ingredient.split("_")[1]
	if held_item == null:
		_fetch_ingredient()
	else:
		set_movement_target(_WorldState.get_closest_element("counter_station", self))
		need_fetch = true
		state = State.MOVING

func next_stored_ingredient_not_cooking() -> bool:
	var target_ingredient = current_blackboard.get_next_stored_ingredient()
	return (target_ingredient.split("_")[1] == "cooked" and _WorldState.get_closest_element("cooking_station", self, target_ingredient).distance_to(global_position) > 10) or target_ingredient.split("_")[1] != "cooked"

func _fetch_ingredient() -> void:
	set_movement_target(_WorldState.get_closest_element("ingredient_station", self, required_ingredient_name + "_base"))
	need_fetch = false
	state = State.MOVING

func _combine_to_plated_meal() -> void:
	is_dressing_plate = true
	var target_position: Vector2 = current_blackboard.plated_meal_location
	set_movement_target(target_position)
	state = State.MOVING

func _combine_from_plated_meal() -> void:
	var target_ingredient = current_blackboard.get_next_stored_ingredient()
	if target_ingredient != "next_ingredient_not_stored":
		var pos1 = _WorldState.get_closest_element("counter_station", self, target_ingredient)
		var pos2 = _WorldState.get_closest_element("cooking_station", self, target_ingredient)
		if self.global_position.distance_to(pos1) > 10 and (self.global_position.distance_to(pos1) < self.global_position.distance_to(pos2) or self.global_position.distance_to(pos2) < 10):
			set_movement_target(pos1)
		elif self.global_position.distance_to(pos2) > 10:
			set_movement_target(pos2)
		else:
			store_plated_meal = true
			var target_position = _WorldState.get_closest_element("counter_station", self)
			current_blackboard.update_plated_meal_location(target_position)
			set_movement_target(target_position)
	elif current_blackboard.current_nb_ingredients == current_blackboard.required_nb_ingredients:
		serving_possible = true
		set_movement_target(_WorldState.get_closest_element("serving_station", self))
	else:
		store_plated_meal = true
		var target_position = _WorldState.get_closest_element("counter_station", self)
		current_blackboard.update_plated_meal_location(target_position)
		set_movement_target(target_position)
	state = State.MOVING

func _store_item() -> void:
	is_storing_item = true
	var target_position = _WorldState.get_closest_element("counter_station", self)
	if held_item is PlatedMeal:
		current_blackboard.update_plated_meal_location(target_position)
	else:
		ingredient_stored = true
	set_movement_target(target_position)
	state = State.MOVING

#Done
func _get_next_station() -> void:
	var group: String
	if held_item is Ingredient:
		match held_item.state:
			Ingredient.State.BASE:
				group = "cutting_station"
			Ingredient.State.CUT:
				group = "cooking_station"
				item_cooking = true
		set_movement_target(_WorldState.get_closest_element(group, self))
		state = State.MOVING

func get_last_ingredient_string_name(element) -> StringName:
	var last_element
	if (element is Ingredient):
		last_element = element as Ingredient
	elif (element is PlatedMeal):
		if element.ingredients.size() == 0:
			return "plate_base"
		last_element = element.ingredients[element.ingredients.size() - 1] as Ingredient
	else:
		return ""
	return StringName(last_element.get_item_name())
