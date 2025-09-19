extends Area2D

@export var ingredient_type: String = "tomato"

@onready var label = $Label

func _ready():
	label.text = ingredient_type.capitalize()
	
	# Set visual color based on ingredient type
	var visual = $Visual
	match ingredient_type:
		"tomato":
			visual.color = Color.RED
		"lettuce":
			visual.color = Color.GREEN
		_:
			visual.color = Color.GRAY

func can_interact() -> bool:
	return true

func interact(player):
	if player.can_hold_item():
		if player.add_item(ingredient_type):
			print("Player picked up ", ingredient_type)