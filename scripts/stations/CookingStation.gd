extends Area2D

@onready var progress_bar = $ProgressBar

var current_ingredient = ""
var cooking_progress = 0.0
var cooking_time = 4.0  # seconds to cook
var is_cooking = false

func can_interact() -> bool:
	return true

func interact(player):
	if current_ingredient == "":
		# Try to place an ingredient
		var held_items = player.get_held_items()
		if not held_items.is_empty():
			var item = player.remove_item()
			if _can_cook(item):
				current_ingredient = item
				cooking_progress = 0.0
				progress_bar.value = 0.0
				progress_bar.visible = true
				print("Placed ", item, " on cooking station")
			else:
				# Return the item if it can't be cooked
				player.add_item(item)
				print("Can't cook ", item)
	else:
		# Try to pick up the ingredient or start cooking
		if not is_cooking and player.can_hold_item():
			if cooking_progress >= 100.0:
				# Item is fully cooked, pick it up
				var cooked_item = _get_cooked_version(current_ingredient)
				player.add_item(cooked_item)
				current_ingredient = ""
				cooking_progress = 0.0
				progress_bar.visible = false
				print("Picked up cooked ingredient")
			else:
				# Start cooking process
				_start_cooking()

func _can_cook(ingredient: String) -> bool:
	return ingredient in ["tomato", "tomato_cut"]

func _get_cooked_version(ingredient: String) -> String:
	match ingredient:
		"tomato":
			return "tomato_cooked"
		"tomato_cut":
			return "tomato_cooked"
		_:
			return ingredient

func _start_cooking():
	if current_ingredient != "" and not is_cooking:
		is_cooking = true
		
		# Create a timer for cooking
		var timer = Timer.new()
		timer.wait_time = cooking_time
		timer.timeout.connect(_finish_cooking)
		add_child(timer)
		timer.start()
		
		# Update progress over time
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100.0, cooking_time)

func _finish_cooking():
	is_cooking = false
	cooking_progress = 100.0
	print("Finished cooking ", current_ingredient)