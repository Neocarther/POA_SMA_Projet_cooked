extends Station

@export var item: String

func _ready() -> void:
	add_to_group("interactable")

func interact(player):
	if player.has_item():
		print("Cannot pick another ingredient while holding one")
	else:
		give_item(player)
