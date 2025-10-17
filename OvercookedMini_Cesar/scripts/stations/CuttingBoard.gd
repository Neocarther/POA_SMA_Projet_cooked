extends Node2D
class_name CuttingBoard
## Planche 1 slot, coupe en 2.0 s

@export var cut_time: float = 2.0

var has_item: bool = false
var is_busy: bool = false
var _item_on_board: Item = null

@onready var timer: Timer = $Timer
@onready var label: Label = $Label

const TomatoChoppedScene: PackedScene = preload("res://scenes/Items/TomatoChopped.tscn")

signal cut_finished()

func _ready() -> void:
	label.text = "Planche (vide)"
	timer.wait_time = cut_time
	timer.one_shot = true
	timer.timeout.connect(_on_cut_done)

func can_interact(agent: Node) -> bool:
	if not has_item and not is_busy and agent and agent.has_method("get_held_item"):
		var it: Item = agent.get_held_item() as Item
		if it and not it.is_chopped:
			return true
	if has_item and not is_busy and _item_on_board and _item_on_board.is_chopped and agent and agent.has_method("can_hold_item") and agent.can_hold_item():
		return true
	return false

func interact(agent: Node) -> bool:
	if not has_item and not is_busy and agent and agent.has_method("get_held_item"):
		var it: Item = agent.get_held_item() as Item
		if it and not it.is_chopped:
			_item_on_board = agent.drop_item_here(self.global_position)
			has_item = true
			label.text = "Tomate posée"
			return true
	if has_item and not is_busy and _item_on_board and _item_on_board.is_chopped and agent and agent.has_method("can_hold_item") and agent.can_hold_item():
		agent.pick_item(_item_on_board)
		_item_on_board = null
		has_item = false
		label.text = "Planche (vide)"
		return true
	return false

func start_cut() -> bool:
	if has_item and not is_busy and _item_on_board and not _item_on_board.is_chopped:
		is_busy = true
		label.text = "Découpe..."
		timer.start()
		return true
	return false

func _process(_delta: float) -> void:
	if is_busy:
		var t_left: float = float(max(0.0, timer.time_left))
		label.text = "Découpe: %.1fs" % t_left

func _on_cut_done() -> void:
	# Détruire l'ancienne tomate
	if _item_on_board:
		_item_on_board.queue_free()

	# Créer la tomate coupée (cast explicite -> Item)
	var chopped: Item = (TomatoChoppedScene.instantiate() as Item)
	chopped.global_position = self.global_position
	get_parent().add_child(chopped)  # place au même niveau que la planche
	_item_on_board = chopped

	# MAJ état
	is_busy = false
	has_item = true
	label.text = "Prêt (coupée)"

	# Signal pour prévenir l’agent
	cut_finished.emit()
