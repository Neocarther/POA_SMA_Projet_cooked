extends CharacterBody2D
class_name Agent

@export var move_speed: float = 180.0
@export var interact_distance: float = 48.0
@export var state_timeout: float = 5.0

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var fsm: FSM = $FSM

# Références de stations (assignées par Main au _ready)
var crate: CrateTomato = null
var board: CuttingBoard = null
var drop_counter: DropCounter = null

# Inventaire simple (1 slot)
var held_item: Item = null

# BlackBoard simple
var target_point: Vector2 = Vector2.ZERO
var _state_elapsed: float = 0.0

# === INVENTAIRE (1 slot) ===
func can_hold_item() -> bool:
	return held_item == null

func get_held_item() -> Item:
	return held_item

func pick_item(item: Item) -> void:
	if held_item or item == null:
		return
	held_item = item
	var anchor := $CarryAnchor
	# Si pas d'ancre, on garde l'item dans la scène au-dessus de la tête
	if anchor == null:
		if held_item.get_parent() == null:
			get_tree().current_scene.add_child(held_item)
		held_item.global_position = global_position + Vector2(0, -28)
	else:
		# Re-parent proprement sous l'ancre
		var parent := held_item.get_parent()
		if parent != null:
			parent.remove_child(held_item)
		anchor.add_child(held_item)
		held_item.position = Vector2.ZERO
	# Option : s'assurer qu'il passe au-dessus
	if held_item is Node2D:
		(held_item as Node2D).z_index = 10
	_update_label()

func drop_item_here(at_pos: Vector2) -> Item:
	var out := held_item
	if out:
		# Re-parent dans la scène principale
		var root := get_tree().current_scene
		var parent := out.get_parent()
		if parent != root:
			if parent != null:
				parent.remove_child(out)
			root.add_child(out)
		out.global_position = at_pos
	held_item = null
	_update_label()
	return out

func drop_item_dispose() -> void:
	if held_item:
		held_item.queue_free()
	held_item = null
	_update_label()

# === Mouvement basique via NavigationAgent2D ===
func set_target(p: Vector2) -> void:
	target_point = p
	nav.target_position = p

func _physics_process(delta: float) -> void:
	var next := nav.get_next_path_position()
	var dir := (next - global_position)
	if dir.length() > 1.0:
		velocity = dir.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_state_elapsed += delta
	fsm.update(self, delta)
	_update_label_pos()

# === Helpers ===
func arrived_at_target(threshold := 10.0) -> bool:
	return global_position.distance_to(target_point) <= threshold or nav.is_navigation_finished()

func is_in_interact_range(node: Node2D) -> bool:
	return node and global_position.distance_to(node.global_position) <= interact_distance

func _update_label() -> void:
	var lbl := $"AgentStateLabel"
	if lbl:
		var item_name := held_item and held_item.name_id or "rien"
		lbl.text = "ÉTAT: %s\nItem: %s" % [fsm.current(), item_name]

func _update_label_pos() -> void:
	var lbl := $"AgentStateLabel"
	if lbl:
		lbl.global_position = global_position + Vector2(0, -40)

func _reset_state_timer() -> void:
	_state_elapsed = 0.0

# === DÉFINITION DES ÉTATS ===
class Idle:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
	func update(owner: Agent, _d: float) -> void:
		if owner.held_item == null:
			owner.fsm.set_state(Agent.GoToCrate.new(), "GoToCrate"); return
		if owner.held_item and not owner.held_item.is_chopped:
			owner.fsm.set_state(Agent.GoToBoard.new(), "GoToBoard"); return
		if owner.held_item and owner.held_item.is_chopped:
			owner.fsm.set_state(Agent.GoToDrop.new(), "GoToDrop"); return

class GoToCrate:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
		if owner.crate:
			# Si la station expose un point d'ancre, vise-le ; sinon vise son centre
			if owner.crate.has_method("get_interact_point"):
				owner.set_target(owner.crate.get_interact_point())
			else:
				owner.set_target(owner.crate.global_position)
	func update(owner: Agent, _d: float) -> void:
		if not owner.crate:
			owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		if owner.arrived_at_target() and owner.is_in_interact_range(owner.crate):
			owner.fsm.set_state(Agent.PickTomato.new(), "PickTomato"); return
		if owner._state_elapsed > owner.state_timeout:
			owner.fsm.set_state(Agent.Idle.new(), "Idle")

class PickTomato:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
	func update(owner: Agent, _d: float) -> void:
		if owner.crate and owner.is_in_interact_range(owner.crate):
			if owner.crate.interact(owner):
				owner.fsm.set_state(Agent.GoToBoard.new(), "GoToBoard"); return
		owner.fsm.set_state(Agent.GoToCrate.new(), "GoToCrate")

class GoToBoard:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
		if owner.board:
			if owner.board.has_method("get_interact_point"):
				owner.set_target(owner.board.get_interact_point())
			else:
				owner.set_target(owner.board.global_position)
	func update(owner: Agent, _d: float) -> void:
		if not owner.board:
			owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		if owner.arrived_at_target() and owner.is_in_interact_range(owner.board):
			if owner.held_item and not owner.held_item.is_chopped:
				owner.fsm.set_state(Agent.PlaceOnBoard.new(), "PlaceOnBoard")
			else:
				owner.fsm.set_state(Agent.CutOnBoard.new(), "CutOnBoard")
			return
		if owner._state_elapsed > owner.state_timeout:
			owner.fsm.set_state(Agent.Idle.new(), "Idle")

class PlaceOnBoard:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
	func update(owner: Agent, _d: float) -> void:
		if owner.board and owner.is_in_interact_range(owner.board):
			if owner.board.interact(owner):
				owner.fsm.set_state(Agent.CutOnBoard.new(), "CutOnBoard"); return
		owner.fsm.set_state(Agent.GoToBoard.new(), "GoToBoard")

class CutOnBoard:
	var _cut_started := false
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
		_cut_started = false
	func update(owner: Agent, _d: float) -> void:
		if not owner.board:
			owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		if owner._state_elapsed > owner.state_timeout * 2.0:
			owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		if not _cut_started and owner.board.start_cut():
			_cut_started = true
			owner.board.cut_finished.connect(func ():
				owner.fsm.set_state(Agent.PickChopped.new(), "PickChopped"), Object.CONNECT_ONE_SHOT)

class PickChopped:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
	func update(owner: Agent, _d: float) -> void:
		if owner.board and owner.is_in_interact_range(owner.board):
			if owner.board.interact(owner):
				owner.fsm.set_state(Agent.GoToDrop.new(), "GoToDrop"); return
		owner.fsm.set_state(Agent.GoToBoard.new(), "GoToBoard")

class GoToDrop:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
		if owner.drop_counter:
			if owner.drop_counter.has_method("get_interact_point"):
				owner.set_target(owner.drop_counter.get_interact_point())
			else:
				owner.set_target(owner.drop_counter.global_position)
	func update(owner: Agent, _d: float) -> void:
		if not owner.drop_counter:
			owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		if owner.arrived_at_target() and owner.is_in_interact_range(owner.drop_counter):
			owner.fsm.set_state(Agent.DropItem.new(), "DropItem"); return
		if owner._state_elapsed > owner.state_timeout:
			owner.fsm.set_state(Agent.Idle.new(), "Idle")

class DropItem:
	func enter(owner: Agent) -> void:
		owner._reset_state_timer()
	func update(owner: Agent, _d: float) -> void:
		if owner.drop_counter and owner.is_in_interact_range(owner.drop_counter):
			if owner.drop_counter.interact(owner):
				owner.fsm.set_state(Agent.Idle.new(), "Idle"); return
		owner.fsm.set_state(Agent.GoToDrop.new(), "GoToDrop")

func _ready() -> void:
	fsm.set_state(Idle.new(), "Idle")
	_update_label()
