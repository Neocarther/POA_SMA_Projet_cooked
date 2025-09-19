extends Area2D

@onready var progress_bar = $ProgressBar

var current_ingredient = ""
var cutting_progress = 0.0
var cutting_time = 3.0  # seconds to cut
var is_cutting = false

func can_interact() -> bool:
	return true

func interact(player):
	if current_ingredient == "":
		# Try to place an ingredient
		var held_items = player.get_held_items()
		if not held_items.is_empty():
			var item = player.remove_item()
			if _can_cut(item):
				current_ingredient = item
				cutting_progress = 0.0
				progress_bar.value = 0.0
				progress_bar.visible = true
				print("Placed ", item, " on cutting station")
			else:
				# Return the item if it can't be cut
				player.add_item(item)
				print("Can't cut ", item)
	else:
		# Try to pick up the ingredient or start cutting
		if not is_cutting and player.can_hold_item():
			if cutting_progress >= 100.0:
				# Item is fully cut, pick it up
				var cut_item = _get_cut_version(current_ingredient)
				player.add_item(cut_item)
				current_ingredient = ""
				cutting_progress = 0.0
				progress_bar.visible = false
				print("Picked up cut ingredient")
			else:
				# Start cutting process
				_start_cutting()

func _can_cut(ingredient: String) -> bool:
	return ingredient in ["tomato", "lettuce"]

func _get_cut_version(ingredient: String) -> String:
	match ingredient:
		"tomato":
			return "tomato_cut"
		"lettuce":
			return "lettuce_cut"
		_:
			return ingredient

func _start_cutting():
	if current_ingredient != "" and not is_cutting:
		is_cutting = true
		
		# Create a timer for cutting
		var timer = Timer.new()
		timer.wait_time = cutting_time
		timer.timeout.connect(_finish_cutting)
		add_child(timer)
		timer.start()
		
		# Update progress over time
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100.0, cutting_time)

func _finish_cutting():
	is_cutting = false
	cutting_progress = 100.0
	print("Finished cutting ", current_ingredient)