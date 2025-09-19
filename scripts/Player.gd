extends CharacterBody2D

@export var speed = 200.0

@onready var interaction_area = $InteractionArea
@onready var held_item_container = $HeldItemContainer

var held_items = []
var max_held_items = 2

func _ready():
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)

func _physics_process(delta):
	# Handle movement
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _input(event):
	if event.is_action_pressed("interact"):
		_try_interact()

var nearby_interactables = []

func _on_area_entered(area):
	if area.has_method("can_interact"):
		nearby_interactables.append(area)

func _on_area_exited(area):
	nearby_interactables.erase(area)

func _try_interact():
	if nearby_interactables.is_empty():
		return
	
	# Interact with the first nearby interactable
	var interactable = nearby_interactables[0]
	if interactable.has_method("interact"):
		interactable.interact(self)

func can_hold_item() -> bool:
	return held_items.size() < max_held_items

func add_item(item_type: String):
	if can_hold_item():
		held_items.append(item_type)
		_update_held_items_display()
		return true
	return false

func remove_item(item_type: String = "") -> String:
	if held_items.is_empty():
		return ""
	
	var removed_item
	if item_type == "":
		# Remove last item if no specific type requested
		removed_item = held_items.pop_back()
	else:
		# Remove specific item type
		var index = held_items.find(item_type)
		if index != -1:
			removed_item = held_items[index]
			held_items.remove_at(index)
		else:
			return ""
	
	_update_held_items_display()
	return removed_item

func get_held_items() -> Array:
	return held_items.duplicate()

func clear_items():
	held_items.clear()
	_update_held_items_display()

func _update_held_items_display():
	# Clear existing display items
	for child in held_item_container.get_children():
		child.queue_free()
	
	# Add new display items
	for i in range(held_items.size()):
		var item_display = ColorRect.new()
		item_display.size = Vector2(16, 16)
		item_display.position = Vector2(i * 20 - 10, 0)
		
		# Color items based on type
		match held_items[i]:
			"tomato":
				item_display.color = Color.RED
			"lettuce":
				item_display.color = Color.GREEN
			"tomato_cooked":
				item_display.color = Color.DARK_RED
			_:
				item_display.color = Color.WHITE
		
		held_item_container.add_child(item_display)