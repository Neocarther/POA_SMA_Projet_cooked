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
		add_to_group("cuttable")
	elif data.cookable:
		add_to_group("cookable")
	update_texture()

func update_texture():
	match state:
		State.BASE:
			sprite.texture = data.base_texture
		State.CUT:
			sprite.texture = data.cut_texture
		State.COOKED:
			sprite.texture = data.cooked_texture

func set_state(new_state: State):
	state = new_state
	update_texture()

func cut():
	if data.cookable:
		add_to_group("cookable")
	set_state(State.CUT)

func cook():
	set_state(State.COOKED)
