extends Item
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
	_update_texture()

@warning_ignore("shadowed_variable")
func init(data: IngredientData) -> void:
	self.data = data
	if data.cuttable:
		self.add_to_group("cuttable")
	elif data.cookable:
		self.add_to_group("cookable")

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
	_update_texture()

func is_cut() -> bool:
	return state == State.CUT

func is_cooked() -> bool:
	return state == State.COOKED

func cut() -> void:
	if data.cookable:
		add_to_group("cookable")
	remove_from_group("cuttable")
	_set_state(State.CUT)

func cook() -> void:
	remove_from_group("cookable")
	_set_state(State.COOKED)

func get_item_name() -> String:
	match state:
		State.BASE:
			return data.name + "_base"
		State.CUT:
			return data.name + "_cut"
		State.COOKED:
			return data.name + "_cooked"
	return ""

func get_state() -> String:
	match state:
		State.BASE:
			return "base"
		State.CUT:
			return "cut"
		State.COOKED:
			return "cooked"
	return ""

func get_class_name():
	return "Ingredient"
