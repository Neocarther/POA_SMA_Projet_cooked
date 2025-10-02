extends Node

@onready var tomato_full = "res://models/tomato_full"
@onready var sprite = $Sprite2D

@export var ingredient: _Ingredient

enum _Ingredient {
	TOMATO,
	BREAD,
	CHEESE,
	STEAK,
}

func _ready() -> void:
	match ingredient:
		_Ingredient.TOMATO:
			sprite.set_texture()
		_Ingredient.BREAD:
			sprite.set_texture()
		_Ingredient.CHEESE:
			sprite.set_texture()
		_Ingredient.STEAK:
			sprite.set_texture()
		_:
			push_error("Ingredient not implemented")
