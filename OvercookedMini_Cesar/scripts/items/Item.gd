extends Node2D
class_name Item

@export var name_id: String = ""
@export var is_chopped: bool = false

func get_icon() -> Texture2D:
	# Optionnel si tu ajoutes de vraies textures
	return null
