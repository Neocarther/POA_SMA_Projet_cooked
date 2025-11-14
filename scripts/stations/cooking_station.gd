extends Station

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var pan: Sprite2D = $Counter/Pan
const PAN_OFF = preload("uid://csh5q65lp4vgu")
const PAN_ON = preload("uid://b1rdgfdwdc48i")

var cooking_progress: float = 0.0
var cooking_time: float = 10.0
var is_cooking: bool = false

var burn_time: float = 5.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cooking_station")
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
				print(current_item.get_item_name(), " is cooking at Cooking Station")
			else:
				print("Can't cook ", current_item.get_item_name())
				give_item(agent)
	elif not is_cooking:
		progress_bar.visible = false
		if not agent.has_item():
			print("Picked up ", current_item.get_item_name(), " from Cooking Station")
			give_item(agent)
		elif agent.item_type() == "Plate":
			give_item(agent)
			agent.ingredient_to_meal()
		elif agent.item_type() == "PlatedMeal":
			try_make_meal(agent)

func _can_cook() -> bool:
	return current_item.is_in_group("cookable") and not current_item.is_cooked()

func _start_cooking() -> void:
	if has_item() and not is_cooking:
		is_cooking = true
		pan.texture = PAN_ON
		#Create timer for the cooking time
		var timer = Timer.new()
		timer.wait_time = cooking_time
		timer.one_shot = true
		timer.timeout.connect(_finish_cooking)
		add_child(timer)
		timer.start()
		#Tween is used to update the progress bar over time
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", progress_bar.max_value, cooking_time)

func _finish_cooking() -> void:
	is_cooking = false
	pan.texture = PAN_OFF
	current_item.cook()
	var timer = Timer.new()
	timer.wait_time = burn_time
	timer.timeout.connect(_burn_item)
	add_child(timer)
	timer.start()
	print("Finished cooking ", current_item.get_item_name(), " at Cooking Station")

func _burn_item() -> void:
	pass
	#if has_item() and current_item.is_in_group("cookable"):
	#	current_item.burn()
