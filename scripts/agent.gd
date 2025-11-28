extends CharacterBody2D
class_name Agent

@export var id: int ##Id of the Agent
@export var movement_speed: float = 800.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var plated_meal_scene = preload("res://scenes/PlatedMeal.tscn")

var held_item: Item = null ##Current item held by the agent
var nearby_interactables: Array[Node] = [] ##Array of interactable elements in range of the Agent

#------ Navigation Code for the Agent to move around the world -------#

func get_agent_id() -> int:
	return self.id

func set_movement_target(movement_target: Vector2):
	print("Moving to : ", movement_target)
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

signal order_completed(recipe)

var state: State ##State of the Agent, can be IDLE, INTERACTING or MOVING
var recipe: StringName ##Name of the current recipe being prepared by the agent
var required_ingredient: StringName ##Name and state of the ingredient required for the next step of the recipe
var required_ingredient_name: String ##Name of the ingredient required for the next step of the recipe
var required_ingredient_state: String ##State of the ingredient required for the next step of the recipe
var order_served: bool = false
var previous_item: String
var interaction_interval: float = 0.0  ##Used to set the minimum interval between 2 interactions in seconds
var need_fetch: bool = false
var item_cooking: bool = false
var cooking_item: String

# ------------------- New Logic here-----------------------
var current_blackboard: BlackBoard
var combine_to_plated_meal: bool = false
var need_to_idle: bool = false

func _process(_delta: float) -> void:
	interaction_interval += _delta
	if interaction_interval <= 0.3:
		return
	else:
		interaction_interval = 0.0
	match state:
		State.IDLE:
			if current_blackboard != null and current_blackboard.nb_of_agents_on_task < 2:
				_get_next_step()
			elif current_blackboard != null:
				current_blackboard.agents_tasks.erase(self.id)
				current_blackboard.nb_of_agents_on_task -= 1
			
			current_blackboard = _WorldState.get_recipe(self.id)
			_get_next_step()
		
		State.MOVING:
			if navigation_agent.is_navigation_finished():
				state = State.INTERACTING
		
		State.INTERACTING:
			_try_interact()
			if held_item == null and need_fetch:
				_fetch_ingredient()
			elif get_last_ingredient_string_name(held_item) == required_ingredient and current_blackboard.is_next_required_ingredient(self.id):
				if current_blackboard.is_plated_meal_stored():
					combine_to_plated_meal = true
					_combine_items()
				else:
					_store_item()
			elif held_item is Ingredient and held_item.data.name == required_ingredient_name and held_item.get_state() != required_ingredient_state :
				_get_next_station()
			elif held_item == null and item_cooking:
				_fetch_cooking_item()
			elif order_served == true:
				order_completed.emit(recipe)
				order_served = false
				state = State.IDLE
			elif need_to_idle:
				need_to_idle = false
				state = State.IDLE
			elif combine_to_plated_meal == true:
				combine_to_plated_meal = false
				current_blackboard.current_nb_ingredients += 1
				state = State.IDLE
				

func _get_next_step() -> void:
	required_ingredient = current_blackboard.get_next_ingredient(self.id)
	print(required_ingredient)
	if required_ingredient == "":
		state = State.IDLE  # No more ingredients, go back to idle state
		return
	elif required_ingredient == "recipe_complete":
		set_movement_target(_WorldState.get_closest_element("serving_station", self))
		order_served = true
		state = State.MOVING
		return
		
	required_ingredient_name = required_ingredient.split("_")[0]
	required_ingredient_state = required_ingredient.split("_")[1]
	if held_item == null:
		_fetch_ingredient()
	else:
		set_movement_target(_WorldState.get_closest_element("counter_station", self))
		need_fetch = true
		state = State.MOVING

func _fetch_ingredient() -> void:
	set_movement_target(_WorldState.get_closest_element("ingredient_station", self, required_ingredient_name + "_base"))
	need_fetch = false
	state = State.MOVING

func _combine_items() -> void:
	var target_position: Vector2
	if combine_to_plated_meal:
		target_position = current_blackboard.plated_meal_location
	set_movement_target(target_position)
	state = State.MOVING

func _store_item() -> void:
	var target_position = _WorldState.get_closest_element("counter_station", self)
	if target_position == self.global_position:
		print("Agent %d waiting for available counter station to store item" % id)
		_store_item()
	else:
		need_to_idle = true
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
				cooking_item = held_item.get_item_name()
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
# ---------------------------------------------------------

#func _process(_delta: float) -> void:
	#interaction_interval += _delta
	#if interaction_interval <= 0.3:
		#return
	#else:
		#interaction_interval = 0.0
	#match state:
		#State.IDLE:
			#recipe = _WorldState.get_recipe()
			#_get_next_step()
		#
		#State.MOVING:
			#if navigation_agent.is_navigation_finished():
				#state = State.INTERACTING
		#
		#State.INTERACTING:
			#_try_interact()
			#if held_item == null and need_fetch:
				#_fetch_ingredient()
			#elif held_item != null and (held_item.get_item_name() == required_ingredient or item_cooking) and previous_item != "":
				#_combine_items()
				#item_cooking = false
			#elif get_last_ingredient_string_name(held_item) == required_ingredient and previous_item == "":
				#_get_next_step()
			#elif held_item is Ingredient and held_item.data.name == required_ingredient_name and held_item.get_state() != required_ingredient_state :
				#_get_next_station()
			#elif held_item == null and item_cooking:
				#_fetch_cooking_item()
			#elif order_served == true:
				#order_completed.emit(recipe)
				#order_served = false
				#state = State.IDLE

#func _get_next_step() -> void:
	#required_ingredient = _RecipeManager.get_next_ingredient(recipe, get_last_ingredient_string_name(held_item))
	#print(required_ingredient)
	#if required_ingredient == "":
		#state = State.IDLE  # No more ingredients, go back to idle state
		#return
	#elif required_ingredient == "recipe_complete":
		#set_movement_target(_WorldState.get_closest_element("serving_station", self))
		#order_served = true
		#state = State.MOVING
		#return
	#
	#required_ingredient_name = required_ingredient.split("_")[0]
	#required_ingredient_state = required_ingredient.split("_")[1]
	#if held_item == null:
		#print("fetching...")
		#_fetch_ingredient()
	#else:
		#previous_item = held_item.get_item_name()
		#set_movement_target(_WorldState.get_closest_element("counter_station", self))
		#need_fetch = true
		#state = State.MOVING

#func _fetch_ingredient() -> void:
	#set_movement_target(_WorldState.get_closest_element("ingredient_station", self, required_ingredient_name + "_base"))
	#need_fetch = false
	#state = State.MOVING

#func _combine_items() -> void:
	#if previous_item != "":
		#var pos1 = _WorldState.get_closest_element("counter_station", self, previous_item)
		#var pos2 = _WorldState.get_closest_element("cooking_station", self, previous_item)
		#if self.global_position.distance_to(pos1) > 10 and self.global_position.distance_to(pos1) < self.global_position.distance_to(pos2) or self.global_position.distance_to(pos2) < 10:
			#set_movement_target(pos1)
		#else:
			#set_movement_target(pos2)
		#previous_item = ""
		#state = State.MOVING

#func _get_next_station() -> void:
	#var group: String
	#if held_item is Ingredient:
		#match held_item.state:
			#Ingredient.State.BASE:
				#group = "cutting_station"
			#Ingredient.State.CUT:
				#group = "cooking_station"
				#item_cooking = true
				#cooking_item = held_item.get_item_name()
		#set_movement_target(_WorldState.get_closest_element(group, self))
		#state = State.MOVING

func _fetch_cooking_item() -> void:
	set_movement_target(_WorldState.get_closest_element("interactable", self, previous_item))
	previous_item = cooking_item
	print(previous_item, cooking_item)
	print(item_cooking)
	state = State.MOVING
