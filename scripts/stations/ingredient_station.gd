extends Station

@onready var ingredient_scene: PackedScene = preload("res://scenes/Ingredient.tscn")
@export var ingredient_data: IngredientData
@onready var ingredient: Sprite2D = $Counter/Ingredient

func _ready() -> void:
	self.add_to_group("interactable")
	self.add_to_group("ingredient_station")
	ingredient.texture = ingredient_data.base_texture
	current_item = ingredient_scene.instantiate() as Ingredient
	current_item.init(ingredient_data)

func interact(player):
	if player.has_item():
		print("Cannot pick another element while holding one")
	else:
		var new_item = ingredient_scene.instantiate() as Ingredient
		new_item.init(ingredient_data)
		give_item(player)
		current_item = new_item
