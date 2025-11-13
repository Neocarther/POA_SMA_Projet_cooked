extends Station

@onready var progress_bar = $ProgressBar

var cutting_progress: float = 0.0
var cutting_goal: float = 10.0
var cutting_rate: float = 100.0 / cutting_goal
var cutting_in_progress: bool = false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cutting_station")
	progress_bar.visible = false

func interact(agent):
	if not has_item():
		if agent.has_item():
			receive_item(agent)
			if _can_cut():
				cutting_progress = 0.0
				progress_bar.value = 0.0
				progress_bar.visible = true
				print(current_item.get_item_name(), " is set for cutting at Cutting Station")
			else:
				give_item(agent)
				print()
	elif not agent.has_item():
		if cutting_progress >= progress_bar.max_value:
			current_item.cut()
			print("Picked up ", current_item.get_item_name(), " from Cutting Station")
			give_item(agent)
			progress_bar.visible = false
		else:
			cutting_progress += cutting_rate
			progress_bar.value = cutting_progress
		

func _can_cut() -> bool:
	return current_item.is_in_group("cuttable") and not current_item.is_cut()
