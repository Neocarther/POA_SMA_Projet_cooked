extends CharacterBody2D

@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
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

func add_item(item) -> void:
	if has_item():
		return
	held_item = item

func remove_item() -> Node:
	if not has_item():
		return null
	var removed_item = held_item
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

func _try_interact():
	if not nearby_interactables.is_empty():
		get_closest_interactable().interact(self)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		nearby_interactables.append(area.get_parent())
		_try_interact()

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("interactables"):
		nearby_interactables.erase(parent)
