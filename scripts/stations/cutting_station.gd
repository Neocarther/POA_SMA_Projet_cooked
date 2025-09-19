extends "res://scripts/stations/station.gd"

var current_ingredient = null


func _on_area_2d_area_entered(area: Area2D) -> void:
	if player.has_something:
		handle_element(element)
		state = station_state.IN_USE

func _on_area_2d_area_exited(area: Area2D) -> void:
	state = station_state.IDLE
	
func handle_element(element):
	if state == station_state.IN_USE and element.is_cuttable():
		cut(element)

func cut(element):
	print("The cook is cutting " + element.name)
