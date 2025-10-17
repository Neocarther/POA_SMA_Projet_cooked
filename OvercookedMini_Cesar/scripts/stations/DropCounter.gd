extends Node2D
class_name DropCounter
## Accepte uniquement les items coupés. Incrémente un score.

var score: int = 0
@onready var label: Label = $Label

func _ready() -> void:
	_update_label()

func accepts(item: Item) -> bool:
	return item and item.is_chopped

func can_interact(agent: Node) -> bool:
	var held: Item = agent.get_held_item()
	return held != null and accepts(held)

func interact(agent: Node) -> bool:
	var held: Item = agent.get_held_item()
	if accepts(held):
		# déposer = enlever de l'agent et supprimer l'item (consommé)
		agent.drop_item_dispose()
		score += 1
		_update_label()
		return true
	return false

func _update_label() -> void:
	label.text = "Déposés: %d" % score
