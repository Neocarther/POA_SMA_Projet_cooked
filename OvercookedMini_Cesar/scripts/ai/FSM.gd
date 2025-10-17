extends Node
class_name FSM
## Mini FSM plug-and-play.

var _state: Object = null
var _state_name: String = ""

signal state_changed(from: String, to: String)

func set_state(new_state_obj: Object, new_state_name: String) -> void:
	var prev := _state_name
	if _state and _state.has_method("exit"):
		_state.exit(self.get_parent())
	_state = new_state_obj
	_state_name = new_state_name
	if _state and _state.has_method("enter"):
		_state.enter(self.get_parent())
	state_changed.emit(prev, _state_name)

func update(owner_node: Node, delta: float) -> void:
	if _state and _state.has_method("update"):
		_state.update(owner_node, delta)

func current() -> String:
	return _state_name
