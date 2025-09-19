extends "res://scripts/stations/station.gd"

enum Element  {
	TOMATO,
	STEAK,
	CHEESE,
	BREAD
}

@export var element_scene_paths := {
	Element.TOMATO: "res://scenes/elements/Tomato.tscn",
	Element.STEAK: "res://scenes/elements/Steak.tscn",
	Element.CHEESE: "res://scenes/elements/Cheese.tscn",
	Element.BREAD: "res://scenes/elements/Bread.tscn",
}

@export var element: Element

func handle_element(player: Node):
	if player.has_element():
		return
	give_element_to_player(player)

func give_element_to_player(player: Node):
	var scene_path = element_scene_paths[element]
	var element_scene = load(scene_path)
	var instance = element_scene.instantiate()
	player.take_element(instance)

func _on_area_2d_area_entered(area: Area2D) -> void:
	var player = area.get_parent()
	if not player.has_method("has_element"):
		return
	state = station_state.IN_USE
	handle_element(player)
