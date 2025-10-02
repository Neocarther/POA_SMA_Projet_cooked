extends Station

@onready var ingredient_scene: PackedScene = preload("res://scenes/Ingredient.tscn")
@export var ingredient_data: IngredientData

func _ready() -> void:
	add_to_group("interactable")

func interact(player):
	if player.has_item():
		print("Cannot pick another element while holding one")
	else:
		current_item = ingredient_scene.instantiate() as Ingredient
		current_item.data = ingredient_data
		give_item(player)
