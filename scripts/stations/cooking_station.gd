extends Station

@onready var progress_bar: ProgressBar = $ProgressBar

var cooking_progress: float = 0.0
var cooking_time: float = 10.0
var is_cooking: bool = false

var burn_time: float = 5.0

func _ready() -> void:
	add_to_group("interactable")
	progress_bar.visible = false

func interact(agent) -> void:
	if not has_item():
		if agent.has_item():
			receive_item(agent)
			if _can_cook():
				cooking_progress = 0.0
				progress_bar.value = 0.0
				progress_bar.visible = true
				_start_cooking()
				print( current_item.label, " is cooking at Cooking Station")
			else:
				print("Can't cook ", current_item.label)
				give_item(agent)
	elif not is_cooking:
		if not agent.has_item():
			progress_bar.visible = false
			print("Picked up ", current_item.label, " from Cooking Station")
			give_item(agent)
		elif agent.item_type() == "Plate":
			progress_bar.visible = false
			give_item(agent)
			agent.ingredient_to_meal()
		elif agent.item_type() == "PlatedMeal":
			try_make_meal(agent)

func _can_cook() -> bool:
	return current_item.is_in_group("cookable") and not current_item.is_cooked()

func _start_cooking() -> void:
	if has_item() and not is_cooking:
		if current_item.is_in_group("cookable") and current_item.is_cooked():
			is_cooking = true
			#Create timer for the cooking time
			var timer = Timer.new()
			timer.wait_time = cooking_time
			timer.timeout.connect(_finish_cooking)
			add_child(timer)
			timer.start()
			#Tween is used to update the progress bar over time
			var tween = create_tween()
			tween.tween_property(progress_bar, "value", progress_bar.max_value, cooking_time)

func _finish_cooking() -> void:
	is_cooking = false
	current_item.cook()
	var timer = Timer.new()
	timer.wait_time = burn_time
	timer.timeout.connect(_burn_item)
	add_child(timer)
	timer.start()
	print("Finished cooking ", current_item.label, " at Cooking Station")

func _burn_item() -> void:
	if has_item() and current_item.is_in_group("cookable"):
		current_item.burn()
