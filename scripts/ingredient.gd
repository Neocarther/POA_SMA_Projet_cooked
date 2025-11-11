extends Node
class_name Ingredient

enum State {
	BASE,
	CUT,
	COOKED,
}

@onready var sprite = $Sprite2D
@export var data: IngredientData
var state: State = State.BASE

func _ready() -> void:
	if data.cuttable:
		get_tree().add_to_group("cuttable")
	elif data.cookable:
		get_tree().add_to_group("cookable")
	_update_texture()

func _update_texture() -> void:
	match state:
		State.BASE:
			sprite.texture = data.base_texture
		State.CUT:
			sprite.texture = data.cut_texture
		State.COOKED:
			sprite.texture = data.cooked_texture

func _set_state(new_state: State) -> void:
	state = new_state
	name = get_name_state()
	_update_texture()

func cut() -> void:
	if data.cookable:
		get_tree().add_to_group("cookable")
	get_tree().remove_from_group("cuttable")
	_set_state(State.CUT)

func cook() -> void:
	get_tree().remove_from_group("cookable")
	_set_state(State.COOKED)

func get_name_state() -> String:
	match state:
		State.BASE:
			return data.name + "_base"
		State.CUT:
			return data.name + "_cut"
		State.COOKED:
			return data.name + "_cooked"
	return ""
