extends Station

func _ready() -> void:
	add_to_group("interactable")

func interact(player):
	if not has_item():
		if player.has_item():
			receive_item(player)
			print(current_item.label, " has been placed on the Counter Station")
		else:
			print("Need to hold item to place it on the Counter Station")
	else:
		if player.has_item():
			print("Cannot take or place item from Counter Station, hands or station needs to be empty")
		else:
			give_item(player)
			print("Received ", current_item.label, " from Counter Station")
