extends Node2D

enum station_state {
	IN_USE,
	IDLE,
	COOKING,
}

var state: station_state = station_state.IDLE

func handle_element(element):
	print("Handling " + element + " at the station...")
