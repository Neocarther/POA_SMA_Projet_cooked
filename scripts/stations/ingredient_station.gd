extends Station

@onready var ingredient_scene: PackedScene = preload("res://scenes/Ingredient.tscn")
@onready var plated_meal_scene: PackedScene = preload("res://scenes/PlatedMeal.tscn")
@export var ingredient_data: IngredientData
@onready var ingredient: Sprite2D = $Counter/Ingredient

var is_plate: bool = false

func _ready() -> void:
	self.add_to_group("interactable")
	self.add_to_group("ingredient_station")
	ingredient.texture = ingredient_data.base_texture
	current_item = ingredient_scene.instantiate() as Ingredient
	current_item.init(ingredient_data)
	if current_item.get_item_name() == "plate_base":
		is_plate = true

func interact(player):
	if player.has_item():
		print("Cannot pick another element while holding one")
	elif is_plate:
		var plate_ingredient = current_item
		current_item = plated_meal_scene.instantiate() as PlatedMeal
		give_item(player)
		current_item = plate_ingredient
	else:
		var new_item = ingredient_scene.instantiate() as Ingredient
		new_item.init(ingredient_data)
		give_item(player)
		current_item = new_item
