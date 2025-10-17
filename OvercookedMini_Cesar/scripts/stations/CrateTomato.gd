extends Node2D
class_name CrateTomato

@export var infinite_stock: bool = true
@export var stock: int = 2

const TomatoScene: PackedScene = preload("res://scenes/Items/Tomate.tscn")

func can_interact(_agent: Agent) -> bool:
	return infinite_stock or stock > 0

func interact(agent: Agent) -> bool:
	if not can_interact(agent):
		return false
	if agent.has_method("can_hold_item") and agent.can_hold_item():
		var t: Item = TomatoScene.instantiate() as Item
		agent.pick_item(t)
		if not infinite_stock:
			stock = max(0, stock - 1)
		return true
	return false
